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
#
# Parámetros:
#   $1 - JSON con los UTXOs a incluir.
#   $2 - Dirección de destino.
#   $3 - Importe a enviar.
#   $4 - Dirección de cambio.
#   $5 - Importe a devolver.
compose_rbf_transaction() {

    local utxos=$1
    local destination_address=$2
    local amount=$3
    local change_address=$4
    local change_amount=$5

    local inputs=$(echo $utxos | jq 'map({ txid: .txid, vout: .vout, sequence: 1 })')
    local outputs='''
        { 
            "'$destination_address'": '$amount', 
            "'$change_address'": '$change_amount' 
        }
    '''

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

show_transaction_details() {

    local tx_hash=$1

    local tx=$(bitcoin-cli getrawtransaction "$tx_hash" 3)
    local transformed_tx=$(echo $tx | jq '{
        input: .vin | map({txid: .txid, vout: .vout}),
        output: .vout | map({amount: .value, script_pubkey: .scriptPubKey.hex}),
        Fees: "'$tx_fee'",
        Weight: "'$tx_weight'"
    }')
}

show_mempool_transactions_details() {

    local txs_hashes=$(bitcoin-cli getrawmempool)

    if [ -z "$txs_hashes" ]
    then
        (>&2 echo "Error. No se ha podido obtener el contenido de la mempool")
        kill -s TERM $$
    fi

    local txs_count=$(echo $txs_hashes | jq 'length')
    echo "La mempool contiene $txs_count transacciones"

    local tx_idx
    for (( tx_idx=0; tx_idx<$txs_count; tx_idx++ ))
    do
        echo ""
        echo "Transacción $(($tx_idx + 1)):"

        local tx_hash=$(echo $txs_hashes | jq -r '.['$tx_idx']')
        show_transaction_details "$tx_hash"
    done
}

echo "Creando cartera 'Miner'"
create_wallet "Miner"
echo "Creando cartera 'Trader'"
create_wallet "Trader"

echo ""
echo "Creando dirección para recompensa de minado en la cartera 'Miner'"
miner_address=$(create_address "Miner" "Recompensa de Minería")
echo "Creada dirección: '$miner_address'"

mine_until_balance_equals "Miner" "$miner_address" "150"

echo "Creando dirección para recepción de bitcoins en la cartera 'Trader'"
trader_address=$(create_address "Trader" "Recibido")
echo "Creada dirección: '$trader_address'"

echo ""
echo "Creando dirección para recibir el cambio en la cartera 'Miner'"
miner_change_address=$(create_change_address "Miner")
echo "Creada dirección: '$miner_change_address'"

echo ""
echo "Componiendo la transacción 'parent' con los 2 primeros UTXOs de 'Miner' y una comisión muy baja"
utxos=$(find_first_utxos "Miner" "2")
amount="70"
change_amount="29.99999"
parent_tx=$(compose_rbf_transaction "$utxos" "$trader_address" "$amount" "$miner_change_address" "$change_amount")

echo "Firmando la transacción y enviándola"
parent_tx_hash=$(sign_and_send_transaction "Miner" "$parent_tx")

show_mempool_transactions_details