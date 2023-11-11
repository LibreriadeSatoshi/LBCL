#!/bin/bash

# create_wallet - Crea una nueva billetera.
#
# Comprueba que se ha creado comparando el nombre de billetera devuelto por
# bitcoin-cli. Muestra un mensaje de error y detiene la ejecución si no es así.
#
# Parámetros:
#   $1 - El nombre de la billetera que se desea crear.
create_wallet() {

    local wallet_name=$1
    
    local createwallet_output=$(bitcoin-cli -named createwallet wallet_name="$wallet_name")
    local created_name=$(echo $createwallet_output | jq -r '.name')
    
    if [ "$created_name" != "$wallet_name" ]
    then
        (>&2 echo "Error. No se ha podido crear la cartera")
        kill -s TERM $$
    fi
}

# create_address - Crea una nueva dirección.
#
# Comprueba que se ha creado verificando que bitcoin-cli ha devuelto una cadena
# de texto. Muestra un mensaje de error y detiene la ejecución si no es así.
#
# Parámetros:
#   $1 - Nombre de la cartera en la que crear la dirección.
#   $2 - Etiqueta descriptiva para la nueva dirección.
create_address() {

    local wallet_name=$1
    local wallet_label=$2

    local createaddress_output=$(bitcoin-cli -rpcwallet="$wallet_name" -named getnewaddress label="$wallet_label")

    if [ ! -z "$createaddress_output" ]
    then
        echo "$createaddress_output"
    else
        (>&2 echo "Error. No se ha podido crear una dirección en la cartera '$wallet_name'")
        kill -s TERM $$
    fi
}

# create_change_address - Crea una nueva dirección para el cambio.
#
# Comprueba que se ha creado verificando que bitcoin-cli ha devuelto una cadena
# de texto. Muestra un mensaje de error y detiene la ejecución si no es así.
#
# Parámetros:
#   $1 - Nombre de la cartera en la que crear la dirección.
create_change_address() {

    local wallet_name=$1

    local createaddress_output=$(bitcoin-cli -rpcwallet="$wallet_name" getrawchangeaddress legacy)

    if [ ! -z "$createaddress_output" ]
    then
        echo "$createaddress_output"
    else
        (>&2 echo "Error. No se ha podido crear una dirección de cambio en la cartera '$wallet_name'")
        kill -s TERM $$
    fi
}

# mine_until_balance_equals - Mina bloques hasta el saldo disponible sea el indicado.
#
# Mina nuevos bloques recibiendo la recompensa en la dirección indicada. Tras cada
# bloque comprueba el saldo y si el saldo disponible no es el esperado, mina otro bloque.
# Repite hasta que el saldo sea suficiente.
#
# Nota 1: Si se indica una dirección que no pertenece a la cartera indicada, seguirá minando
#         bloques hasta que se cancele el proceso manualmente.
#
# Parámetros:
#   $1 - Nombre de la cartera asociada a la dirección de recompensa.
#   $2 - Dirección de recompensa.
#   $3 - Saldo objetivo.
mine_until_balance_equals() {

    local wallet_name=$1
    local mining_address=$2
    local expected_balance=$3

    local balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance)

    echo ""
    echo -n "Minando bloques... "

    while (( $(echo "$balance" "$expected_balance" | awk '{if ($1 + 0 < $2 + 0) print 1; else print 0;}') ))
    do
        bitcoin-cli generatetoaddress 1 "$mining_address" > /dev/null
        local blocks_mined=$(($blocks_mined + 1))
        echo -n "$blocks_mined "
        balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance)
    done

    echo ""
    echo "Se minaron $blocks_mined bloques hasta que el saldo alcanzó o superó '$expected_balance'"
    echo ""
    echo "Balance actual: $balance"
}

# find_first_utxos - Devuelve el número solicitado de UTXOs disponibles.
#
# Obtiene el número de UTXOs solicitado de la lista total de UTXOs y extrae
# los campos 'txid' y 'vout'.
#
# Parámetros:
#   $1 - Nombre de la cartera asociada a la dirección de recompensa.
#   $2 - Número de UTXOs deseados.
find_first_utxos() {

    local wallet_name=$1
    local requested_utxos_count=$2

    local utxos=$(bitcoin-cli -rpcwallet="$wallet_name" listunspent | jq '[.[:'$requested_utxos_count'][] | { txid: .txid, vout: .vout }]')
    local obtained_utxos_count=$(echo $utxos | jq 'length')

    if [ "$requested_utxos_count" == "$obtained_utxos_count" ]
    then
        echo "$utxos"
    else
        (>&2 echo "Error. Se solicitaron '$requested_utxos_count' pero se han obtenido '$obtained_utxos_count'")
        kill -s TERM $$
    fi
}

# compose_rbf_transaction - Crea una transacción RBF con los datos recibidos.
#
# Compone una transacción con RBF habilitado, conteniendo todos los UTXOs recibidos.
# Opcionalmente, devuelve a una dirección de cambio la cantidad indicada.
#
# Parámetros:
#   $1 - JSON con los UTXOs a incluir.
#   $2 - Dirección de destino.
#   $3 - Importe a enviar.
#   $4 - Dirección de cambio (opcional).
#   $5 - Importe a devolver (opcional).
compose_rbf_transaction() {

    local utxos=$1
    local destination_address=$2
    local amount=$3
    local change_address=$4
    local change_amount=$5

    local inputs=$(echo $utxos | jq 'map({ txid: .txid, vout: .vout, sequence: 1 })')
    local outputs='''{ "'$destination_address'": '$amount' }'''

    if [[ -n "$change_address" && -n "$change_amount" ]]
    then
        outputs=$(echo $outputs | jq '. + { "'$change_address'": '$change_amount' }')
    fi

    local tx_raw=$(bitcoin-cli -named createrawtransaction inputs="$inputs" outputs="$outputs")

    if [ ! -z "$tx_raw" ]
    then
        echo "$tx_raw"
    else
        (>&2 echo "Error. No se ha podido componer la transacción solicitada")
        kill -s TERM $$
    fi
}

# compose_transaction - Crea una transacción (no RBF) con los datos recibidos.
#
# Compone una transacción conteniendo todos los UTXOs recibidos.
# Opcionalmente, devuelve a una dirección de cambio la cantidad indicada.
#
# Parámetros:
#   $1 - JSON con los UTXOs a incluir.
#   $2 - Dirección de destino.
#   $3 - Importe a enviar.
#   $4 - Dirección de cambio (opcional).
#   $5 - Importe a devolver (opcional).
compose_transaction() {

    local utxos=$1
    local destination_address=$2
    local amount=$3
    local change_address=$4
    local change_amount=$5

    local inputs=$(echo $utxos | jq 'map({ txid: .txid, vout: .vout })')
    local outputs='''{ "'$destination_address'": '$amount' }'''

    if [[ -n "$change_address" && -n "$change_amount" ]]
    then
        outputs=$(echo $outputs | jq '. + { "'$change_address'": '$change_amount' }')
    fi

    local tx_raw=$(bitcoin-cli -named createrawtransaction inputs="$inputs" outputs="$outputs")

    if [ ! -z "$tx_raw" ]
    then
        echo "$tx_raw"
    else
        (>&2 echo "Error. No se ha podido componer la transacción solicitada")
        kill -s TERM $$
    fi
}

# sign_and_send_transaction - Firma y envía una transacción.
#
# Firma la transacción con la clave privada de la cartera indicada y la envía al nodo.
#
# Parámetros:
#   $1 - Nombre de la cartera cuya clave privada firmará la transacción.
#   $2 - Transacción (formato RAW).
sign_and_send_transaction() {

    local sender_wallet_name=$1
    local transaction=$2

    local sign_tx_outp=$(bitcoin-cli -rpcwallet="$sender_wallet_name" signrawtransactionwithwallet $transaction)
    local signed_tx=$(echo $sign_tx_outp | jq -r '.hex')

    if [ -z "$signed_tx" ]
    then
        (>&2 echo "Error. No se ha podido firmar la transacción")
        kill -s TERM $$
    fi

    local tx_hash=$(bitcoin-cli sendrawtransaction "$signed_tx")

    if [ ! -z "$tx_hash" ]
    then
        echo "$tx_hash"
    else
        (>&2 echo "Error. No se ha podido enviar la transacción firmada")
        kill -s TERM $$
    fi
}

# calculate_transaction_fee - Calcula la comisión de una transacción.
#
# Busca las transacciones de los vin de la transacción indicada y obtiene los
# importes de sus vout, sumándolos. Seguidamente resta los importes de los vouts
# de la transacción indicada para obtener la comisión.
#
# Parámetros:
#   $1 - Transacción de interés (formato JSON).
calculate_transaction_fee() {

    local tx=$1

    local vins_count=$(echo $tx | jq '.vin | length')

    local vin_idx
    local total_in=$(for (( vin_idx=0; vin_idx<$vins_count; vin_idx++ ))
    do
        local vin_txid=$(echo $tx | jq -r '.vin['$vin_idx'].txid')
        local vin_vout=$(echo $tx | jq -r '.vin['$vin_idx'].vout')

        local vin_tx=$(bitcoin-cli getrawtransaction "$vin_txid" 3)
        local vin_tx_vout=$(echo $vin_tx | jq '.vout['$vin_vout']')
        local vin_tx_vout_amount=$(echo $vin_tx_vout | jq -r '.value')

        echo $vin_tx_vout_amount
    done | awk '{s+=$1} END {print s}')

    local total_out=$(echo $tx | jq '[ .vout[] | .value ] | add')

    LC_ALL=C awk "BEGIN{printf \"%.8f\n\", $total_in - $total_out}"
}

# show_transaction_details - Muestra los detalles de una transacción.
#
# Muestra los detalles de la transacción indicada en el formato pedido por
# el ejercicio.
#
# Parámetros:
#   $1 - Hash de la transacción a mostrar.
show_transaction_details() {

    local tx_hash=$1

    local tx=$(bitcoin-cli getrawtransaction "$tx_hash" 3)
    local tx_fee=$(calculate_transaction_fee "$tx")

    local transformed_tx=$(echo $tx | jq '{
        input: .vin | map({txid: .txid, vout: .vout}),
        output: .vout | map({amount: .value, script_pubkey: .scriptPubKey.hex}),
        Fees: "'$tx_fee'",
        Weight: .weight | tostring
    }')

    echo $transformed_tx | jq
}


echo '''
***************
* Ejercicio 1 *
***************
'''
echo "Creando cartera 'Miner'"
create_wallet "Miner"
echo "Creando cartera 'Trader'"
create_wallet "Trader"

echo '''
***************
* Ejercicio 2 *
***************
'''
echo "Creando dirección para recompensa de minado en la cartera 'Miner'"
miner_address=$(create_address "Miner" "Recompensa de Minería")
echo "Creada dirección: '$miner_address'"

mine_until_balance_equals "Miner" "$miner_address" "150"

echo '''
***************
* Ejercicio 3 *
***************
'''
echo "Creando dirección para recepción de bitcoins en la cartera 'Trader'"
trader_address=$(create_address "Trader" "Recibido")
echo "Creada dirección: '$trader_address'"

echo ""
echo "Creando dirección para recibir el cambio en la cartera 'Miner'"
miner_change_address=$(create_change_address "Miner")
echo "Creada dirección: '$miner_change_address'"

echo ""
echo "Componiendo la transacción 'parent' con los 2 primeros UTXOs de 'Miner' y una comisión muy baja"
parent_utxos=$(find_first_utxos "Miner" "2")
amount="70"
change_amount="29.99999"
parent_tx=$(compose_rbf_transaction "$parent_utxos" "$trader_address" "$amount" "$miner_change_address" "$change_amount")

echo '''
***************
* Ejercicio 4 *
***************
'''
echo "Firmando la transacción y enviándola"
parent_tx_hash=$(sign_and_send_transaction "Miner" "$parent_tx")

echo '''
********************
* Ejercicios 5 y 6 *
********************
'''
echo "Mostrando el detalle solicitado de la transacción emitida:"
show_transaction_details "$parent_tx_hash"

echo '''
***************
* Ejercicio 7 *
***************
'''
echo "Creando dirección para autoenvío para CPFP en la cartera 'Miner'"
miner_cpfp_address=$(create_address "Miner" "Autoenvío para RBF")
echo "Creada dirección: '$miner_cpfp_address'"

echo ""
echo "Componiendo la transacción 'child' gastando la salida de la transacción 'parent'"
child_utxos='''[ { "txid": "'$parent_tx_hash'", "vout": 1 } ]'''
amount="29.99998"
child_tx=$(compose_transaction "$child_utxos" "$miner_cpfp_address" "$amount")

echo "Firmando la transacción y enviándola"
child_tx_hash=$(sign_and_send_transaction "Miner" "$child_tx")

echo '''
***************
* Ejercicio 8 *
***************
'''
echo "Mostrando el detalle de la transacción 'child' emitida (usando mempoolentry):"
bitcoin-cli getmempoolentry "$child_tx_hash" | jq

echo '''
***************
* Ejercicio 9 *
***************
'''
echo "Componiendo una transacción para sustituir a 'parent' con las mismas"
echo "entradas pero una comisión de 10000 satoshis"
amount="70"
change_amount="29.99989"
new_parent_tx=$(compose_rbf_transaction "$parent_utxos" "$trader_address" "$amount" "$miner_change_address" "$change_amount")

echo '''
****************
* Ejercicio 10 *
****************
'''
echo "Firmando la transacción y enviándola"
new_parent_tx_hash=$(sign_and_send_transaction "Miner" "$new_parent_tx")

echo '''
****************
* Ejercicio 11 *
****************
'''
echo "Mostrando de nuevo el detalle de la transacción 'child' (usando mempoolentry):"
bitcoin-cli getmempoolentry "$child_tx_hash" | jq

echo """
****************
* Ejercicio 11 *
****************

El comando anterior ha fallado porque la transacción 'child' era CPFP, es decir,
gastaba las salidas de la transacción 'parent' para incentivar al minero a minar
ambas, ya que la transacción 'parent' tenía una comisión demasiado baja e iba a
quedarse atascada en la mempool.

Sin embargo, tras enviar la transacción 'child', se ha generado una nueva transacción
'parent' que reemplazaba a la original aprovechando la funcionalidad RBF, es decir,
reemplazando completamente la transacción original con una nueva con mayor comisión.

Al reemplazar la transacción 'parent', la nueva transacción 'parent' ya no es la
original. Tiene un txid diferente, por lo que la transacción 'child' utiliza un UTXO
que ya no existe, y es eliminada de la mempool.
"""