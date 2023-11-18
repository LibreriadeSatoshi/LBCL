#!/bin/bash

# install_bitcoin_core - Instala bitcoin-core a partir de los binarios.
#
# Descarga los archivos binarios de bitcoin-core, comprueba las firmas de
# verificación, los instala, borra las descargas, crea el fichero de configuración
# e inicia el servicio.
install_bitcoin_core() {

    # Actualiza los paquetes del sistema
    sudo apt update
    sudo apt upgrade -y

    # Instala las dependencias requeridas por bitcoin
    sudo apt-get install haveged gnupg dirmngr xxd -y

    # Versión a descargar
    BITCOIN="bitcoin-core-25.1"
    BITCOINPLAIN=`echo $BITCOIN | sed 's/bitcoin-core/bitcoin/'`

    # Descargamos los binarios de Bitcoin Core
    wget https://bitcoincore.org/bin/$BITCOIN/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz
    # Y los archivos con las sumas de verificación y las firmas PGP
    wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS.asc
    wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS

    # Clonamos el repositorio con las claves públicas de los autores del proyecto
    git clone https://github.com/bitcoin-core/guix.sigs.git
    for file in ./guix.sigs/builder-keys/*.gpg; do gpg --import "$file"; done

    # Verificamos la autenticidad del archivo SHA256SUMS 
    SHASIG=`gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep "Good signature"`
    SHACOUNT=`gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep "Good signature" | wc -l`

    if [[ "$SHASIG" ]]
    then
        echo "$0 - Verificación de firma correcta: Encontradas $SHACOUNT firmas correctas."
        echo "$SHASIG"
    else
        (>&2 echo "$0 - Error de verificación de firmas: No se ha podido verificar el archivo SHA256SUMS")
    fi

    # Busca en el directorio actual los archivos indicados en SHA256SUMS y 
    # comprueba sus sumas de verificación
    SHACHECK=`sha256sum -c --ignore-missing < SHA256SUMS 2>&1 | grep "OK"`

    if [ "$SHACHECK" ]
    then
    echo "$0 - Verificación exitosa de la firma binaria. Comprobados los archivos: $SHACHECK"
    else
        (>&2 echo "$0 - Verificación de SHA incorrecta!")
    fi

    # Extrae los binarios
    tar xzf $BITCOINPLAIN-x86_64-linux-gnu.tar.gz

    # Instala los ejecutables en las rutas por defecto del sistema
    sudo install -m 0755 -o root -g root -t /usr/local/bin $BITCOINPLAIN/bin/*

    # Instala los manuales
    sudo cp -r $BITCOINPLAIN/share/man/man1 /usr/local/share/man
    command -v mandb && sudo mandb 

    # Elimina los archivos descargados
    rm -rf $BITCOINPLAIN $BITCOINPLAIN-x86_64-linux-gnu.tar.gz guix.sigs SHA256SUMS.asc SHA256SUMS

    # Crea la carpeta de datos del nodo en la ubicación por defecto
    mkdir ~/.bitcoin

    # Crea el archivo de configuración del nodo
    cat >> ~/.bitcoin/bitcoin.conf << EOF
regtest=1
fallbackfee=0.0001
server=1
txindex=1
EOF
}

# clean - Realiza limpieza de final de ejecución.
#
# Detiene bitcoin-core y borra los archivos de configuración.
clean() {

    echo "Deteniendo el servicio y borrando la configuración"
    #killall bitcoind
    #sleep 1
    #rm -fr ~/.bitcoin
    kill -s TERM $$
}

# create_wallet_without_descriptor - Crea una nueva billetera sin descriptor.
#
# Comprueba que se ha creado comparando el nombre de billetera devuelto por
# bitcoin-cli. Muestra un mensaje de error y detiene la ejecución si no es así.
#
# Parámetros:
#   $1 - El nombre de la billetera que se desea crear.
create_wallet_without_descriptor() {

    local wallet_name=$1
    
    local createwallet_output=$(bitcoin-cli -named createwallet wallet_name="$wallet_name" descriptors="false")
    local created_name=$(echo $createwallet_output | jq -r '.name')
    
    if [ "$created_name" != "$wallet_name" ]
    then
        (>&2 echo "Error. No se ha podido crear la cartera")
        clean
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
        clean
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
        clean
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
        clean
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
        clean
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
        clean
    fi

    local tx_hash=$(bitcoin-cli sendrawtransaction "$signed_tx")

    if [ ! -z "$tx_hash" ]
    then
        echo "$tx_hash"
    else
        (>&2 echo "Error. No se ha podido enviar la transacción firmada")
        clean
    fi
}

# format_btc_decimal - Muestra un decimal en formato BTC.
#
# Recibe una cadena de texto con formato numérico,
# o una suma de números y devuelve el número resultante con 
# 8 decimales y separador decimal '.'
format_btc_decimal() {
    echo "$(LC_ALL=C awk "BEGIN{printf \"%.8f\n\", $1}")"
}

# create_and_add_multisig_2_2 - Crea una dirección multifirma y guarda sus datos en las wallets.
#
# Crea una dirección multifirma 2 de 2, usando 'addmultisigaddress' para
# almacenar los datos de la dirección en las carteras de ambos participantes.
#
# Parámetros:
#   $1 - Nombre de la wallet del primer participante.
#   $2 - Clave pública de la dirección del primer participante.
#   $3 - Nombre de la wallet del segundo participante.
#   $4 - Clave pública de la dirección del segundo participante.
create_and_add_multisig_2_2() {

    local party_1_wallet=$1
    local party_1_pubkey=$2
    local party_2_wallet=$3
    local party_2_pubkey=$4

    local keys='''[ "'$party_1_pubkey'", "'$party_2_pubkey'" ]'''
    local address=$(bitcoin-cli -rpcwallet="$party_1_wallet" -named addmultisigaddress nrequired=2 keys="$keys" | jq -r '.address')
    # Se ejecuta una segunda vez descartando el resultado, para almacenar los datos
    # de la dirección multifirma en la segunda cartera
    bitcoin-cli -rpcwallet="$party_2_wallet" -named addmultisigaddress nrequired=2 keys="$keys" > /dev/null

    echo $address
}

# create_two_parties_funding_psbt - Crea una transacción PSBT para fondear una dirección entre dos participantes.
#
# Crea una transacción PSBT en la que dos participantes fondean conjuntamente
# una dirección. Esta función desempeña el rol 'Creator' en el flujo PSBT, por
# lo que únicamente define los 'vin' y 'vout'.
#
# Nota 1: Los parámetros relacionados con el cambio son opcionales, pero si se desea
#         incluir un cambio para el segundo participante únicamente, hay que incluir
#         los parámetros de cambio para el primer participante, aunque sean vacíos, ya
#         que los parámetros de la función son posicionales.
#
# Parámetros:
#   $1 - JSON con los UTXOs a incluir del primer participante.
#   $2 - JSON con los UTXOs a incluir del segundo participante.
#   $3 - Dirección de destino.
#   $4 - Importe a enviar.
#   $5 - Dirección de cambio del primer participante (opcional).
#   $6 - Importe a devolver al primer participante (opcional).
#   $7 - Dirección de cambio del segundo participante (opcional).
#   $8 - Importe a devolver al segundo participante (opcional).
create_two_parties_funding_psbt() {

    local party_1_utxos=$1
    local party_2_utxos=$2
    local destination_address=$3
    local amount=$4
    local party_1_change_address=$5
    local party_1_change_amount=$6
    local party_2_change_address=$7
    local party_2_change_amount=$8

    # Selecciona los campos de los UTXOs de entrada de ambos participantes
    local inputs_1=$(echo $party_1_utxos | jq 'map({ txid: .txid, vout: .vout })')
    local inputs_2=$(echo $party_2_utxos | jq 'map({ txid: .txid, vout: .vout })')
    local inputs=$(jq -s '.[0] + .[1]' <(echo $inputs_1) <(echo $inputs_2))
    # Salida (dirección de destino)
    local outputs='''{ "'$destination_address'": '$amount' }'''

    # Si se ha recibido cambio para el primer participante, lo agrega a la salida
    if [[ -n "$party_1_change_address" && -n "$party_1_change_amount" ]]
    then
        outputs=$(echo $outputs | jq '. + { "'$party_1_change_address'": '$party_1_change_amount' }')
    fi

    # Si se ha recibido cambio para el segundo participante, lo agrega a la salida
    if [[ -n "$party_2_change_address" && -n "$party_2_change_amount" ]]
    then
        outputs=$(echo $outputs | jq '. + { "'$party_2_change_address'": '$party_2_change_amount' }')
    fi

    # Crea la PSBT
    psbt=$(bitcoin-cli -named createpsbt inputs="$inputs" outputs="$outputs")

    if [ ! -z "$psbt" ]
    then
        echo "$psbt"
    else
        (>&2 echo "Error. No se ha podido componer la transacción solicitada")
        clean
    fi
}


echo """
**************************
* Descarga e instalación *
**************************
"""
#install_bitcoin_core

echo """
**********************
* Iniciando bitcoind *
**********************
"""
#bitcoind -daemon
#sleep 1

echo """
************************************
* Configurar multisig. Ejercicio 1 *
************************************
"""
echo "Creando cartera 'Miner'"
create_wallet_without_descriptor "Miner"
echo "Creando cartera 'Alice'"
create_wallet_without_descriptor "Alice"
echo "Creando cartera 'Bob'"
create_wallet_without_descriptor "Bob"

echo """
************************************
* Configurar multisig. Ejercicio 2 *
************************************
"""
echo "Creando dirección para recompensa de minado en la cartera 'Miner'"
miner_address=$(create_address "Miner" "Recompensa de Minería")
echo "Creada dirección: '$miner_address'"

mine_until_balance_equals "Miner" "$miner_address" "100"

echo ""
echo "Creando dirección de recepción para 'Alice'"
alice_address=$(create_address "Alice" "Recepción de fondos")
echo "Creada dirección: '$alice_address'"

echo ""
echo "Creando dirección para recibir el cambio en la cartera 'Miner'"
miner_change_address=$(create_change_address "Miner")
echo "Creada dirección: '$miner_change_address'"

echo ""
echo "Componiendo una transacción para 'Alice' con el primer UTXO de 'Miner'"
utxos=$(find_first_utxos "Miner" "1")
amount="21"
change_amount="28.9999"
send_alice_tx=$(compose_transaction "$utxos" "$alice_address" "$amount" "$miner_change_address" "$change_amount")

echo ""
echo "Firmando la transacción y enviándola"
send_alice_tx_hash=$(sign_and_send_transaction "Miner" "$send_alice_tx")

echo ""
echo "Creando dirección de recepción para 'Bob'"
bob_address=$(create_address "Bob" "Recepción de fondos")
echo "Creada dirección: '$bob_address'"

echo ""
echo "Creando otra dirección para recibir el cambio en la cartera 'Miner'"
miner_change_address_2=$(create_change_address "Miner")
echo "Creada dirección: '$miner_change_address_2'"

echo ""
echo "Componiendo una transacción para 'Bob' con el primer UTXO de 'Miner'"
utxos=$(find_first_utxos "Miner" "1")
amount="21"
change_amount="28.9999"
send_bob_tx=$(compose_transaction "$utxos" "$bob_address" "$amount" "$miner_change_address_2" "$change_amount")

echo ""
echo "Firmando la transacción y enviándola"
send_bob_tx_hash=$(sign_and_send_transaction "Miner" "$send_bob_tx")

echo ""
echo "Minando un bloque para procesar ambas transacciones"
bitcoin-cli -rpcwallet="Miner" -generate 1 > /dev/null

echo ""
echo "Saldos de cada participante:"
miner_balance=$(bitcoin-cli -rpcwallet="Miner" getbalance)
alice_balance=$(bitcoin-cli -rpcwallet="Alice" getbalance)
bob_balance=$(bitcoin-cli -rpcwallet="Bob" getbalance)
echo "Saldo de Miner: $miner_balance BTC"
echo "Saldo de Alice: $alice_balance BTC"
echo "Saldo de Bob: $bob_balance BTC"

echo """
************************************
* Configurar multisig. Ejercicio 3 *
************************************
"""
echo "Creando dirección para 'Alice', para su uso en la dirección multifirma junto a 'Bob'"
alice_multisig_address=$(create_address "Alice" "Dirección para multisig con Bob")
echo "Creada dirección: '$alice_multisig_address'"

echo ""
echo "Obteniendo la clave pública de la dirección de 'Alice'"
alice_multisig_address_pubkey=$(bitcoin-cli -rpcwallet="Alice" -named getaddressinfo address="$alice_multisig_address" | jq -r '.pubkey')
echo "Clave pública: '$alice_multisig_address_pubkey'"

echo ""
echo "Creando dirección para 'Bob', para su uso en la dirección multifirma junto a 'Alice'"
bob_multisig_address=$(create_address "Bob" "Dirección para multisig con Alice")
echo "Creada dirección: '$bob_multisig_address'"

echo ""
echo "Obteniendo la clave pública de la dirección de 'Bob'"
bob_multisig_address_pubkey=$(bitcoin-cli -rpcwallet="Bob" -named getaddressinfo address="$bob_multisig_address" | jq -r '.pubkey')
echo "Clave pública: '$bob_multisig_address_pubkey'"

echo ""
echo "Creando una dirección multifirma 2 de 2 para 'Alice' y 'Bob'."
echo "Se tomará ventaja de 'addmultisigaddress' para que la información del"
echo "script de redención quede almacenada en la wallet de cada uno de ellos."
multisig_address=$(create_and_add_multisig_2_2 "Alice" "$alice_multisig_address_pubkey" "Bob" "$bob_multisig_address_pubkey")
echo "Creada dirección multifirma: '$multisig_address'"

echo ""
echo "Importando la dirección multifirma en las carteras de ambos participantes"
bitcoin-cli -rpcwallet="Alice" -named importaddress address="$multisig_address" rescan="false"
bitcoin-cli -rpcwallet="Bob" -named importaddress address="$multisig_address" rescan="false"

echo """
************************************
* Configurar multisig. Ejercicio 4 *
************************************

Crearemos una PSBT para que 'Alice' y 'Bob' fondeen su cuenta conjunta a la vez
sin necesidad de confiar el uno en que el otro cumplirá su parte.
"""

echo "Creando dirección para recibir el cambio en la cartera 'Alice'"
alice_change_address=$(create_change_address "Alice")
echo "Creada dirección: '$alice_change_address'"

echo ""
echo "Creando dirección para recibir el cambio en la cartera 'Bob'"
bob_change_address=$(create_change_address "Bob")
echo "Creada dirección: '$bob_change_address'"

echo ""
echo "Seleccionando el único UTXO disponible de 'Alice'"
alice_utxos=$(find_first_utxos "Alice" "1")

echo ""
echo "Seleccionando el único UTXO disponible de 'Bob'"
bob_utxos=$(find_first_utxos "Bob" "1")

echo ""
echo "Componiendo la transacción PSBT. Este paso lo realiza el rol 'Creador'"
amount="20"
alice_change_amount="10.9999"
bob_change_amount="10.9999"

fund_psbt=$(create_two_parties_funding_psbt \
    "$alice_utxos" "$bob_utxos" "$multisig_address" "$amount" \
    "$alice_change_address" "$alice_change_amount" \
    "$bob_change_address" "$bob_change_amount" \
)

echo """
El siguiente paso es completar la PSBT con los datos de los UTXOs que contiene.
Este paso lo realiza el rol 'Actualizador'. Como en este caso contiene UTXOs de dos
participantes distintos, cada uno debe actualizar los inputs correspondientes a sus
UTXOs, por lo que la PSBT creada sería ENVIADA A CADA PARTICIPANTE INDIVIDUALMENTE y
cada uno actualizaría los datos que le corresponden.

Tras este paso, cada participante también firmaría la PSBT, TAMBIÉN INDIVIDUALMENTE,
desempeñando el rol 'Firmante'.

Estos dos pasos (actualización y firma) son realizados por el comando de bitcoin-cli 
'walletprocesspsbt'.
"""

echo "Actualizando y firmando la copia de 'Alice' de la PSBT"
echo "(Esta parte ocurriría en la máquina de 'Alice')"
alice_signed_psbt=$(bitcoin-cli --rpcwallet="Alice" walletprocesspsbt "$fund_psbt" | jq -r '.psbt')

echo ""
echo "Actualizando y firmando la copia de 'Bob' de la PSBT"
echo "(Esta parte ocurriría en la máquina de 'Bob')"
bob_signed_psbt=$(bitcoin-cli --rpcwallet="Bob" walletprocesspsbt "$fund_psbt" | jq -r '.psbt')

echo """
Ahora cada participante ha actualizado y firmado su copia de la PSBT. Estas copias
ya firmadas se han de enviar al componente que está ejecutando el rol de 'Finalizador'.

El finalizador combina ambas versiones, creando una que incluye los datos actualizados
de cada UTXO y las firmas de cada participante.

En bitcoin-cli este paso se realiza con el comando 'combinepsbt'.
"""

echo "Finalizando PSBT, combinando las transacciones parcialmente firmadas"
final_psbt=$(bitcoin-cli combinepsbt '''[ "'$alice_signed_psbt'", "'$bob_signed_psbt'" ]''')

echo """
Ahora la PSBT está finalizada (actualizada, firmada y combinada). El último paso
es realizado por el rol 'Extractor', que consiste en convertir la transacción PSBT al
formato transacción 'normal' para poder emitirla a la red.

En bitcoin-cli este paso lo realiza el comando 'finalizepsbt'.
"""

echo "Convirtiendo la transacción de PSBT a transacción estándar"
finalize_output=$(bitcoin-cli finalizepsbt "$final_psbt")

if [ "true" != "$(echo $finalize_output | jq -r '.complete')" ]
then
    echo "El campo 'complete' devuelto por 'finalizepsbt' debe ser true"
    clean
fi

echo ""
echo "Enviando la transacción a la red"
final_tx_hex=$(echo $finalize_output | jq -r '.hex')
final_tx_id=$(bitcoin-cli -named sendrawtransaction hexstring="$final_tx_hex")
echo "ID de transacción: '$final_tx_id'"

echo """
************************************
* Configurar multisig. Ejercicio 5 *
************************************

Minando un bloque para procesar la transacción
"""
bitcoin-cli -rpcwallet="Miner" -generate 1 > /dev/null

echo """
************************************
* Configurar multisig. Ejercicio 6 *
************************************
"""
echo "Saldos de cada participante:"
alice_balance=$(bitcoin-cli -rpcwallet="Alice" getbalance)
bob_balance=$(bitcoin-cli -rpcwallet="Bob" getbalance)
echo "Saldo de Alice: $alice_balance BTC"
echo "Saldo de Bob: $bob_balance BTC"

echo """
Los saldos no incluyen la cantidad disponible en la dirección multisig,
pero pueden verse con el comando 'getreceivedbyaddress', indicando la
dirección multisig:
"""
alice_multisig_balance=$(bitcoin-cli -rpcwallet="Alice" getreceivedbyaddress "$multisig_address")
bob_multisig_balance=$(bitcoin-cli -rpcwallet="Bob" getreceivedbyaddress "$multisig_address")
echo "Saldo multisig según Alice: $alice_multisig_balance BTC"
echo "Saldo multisig según Bob: $bob_multisig_balance BTC"



echo """
**************************
* Limpieza *
**************************
"""
clean
