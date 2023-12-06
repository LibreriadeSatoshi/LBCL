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
    killall bitcoind
    sleep 1
    rm -fr ~/.bitcoin
    kill -s TERM $$
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


echo """
**************************
* Descarga e instalación *
**************************
"""
install_bitcoin_core

echo """
**********************
* Iniciando bitcoind *
**********************
"""
bitcoind -daemon
sleep 1

echo """
************************************************
* Configurar un Timelock relativo. Ejercicio 1 *
************************************************
"""
echo "Creando cartera 'Miner'"
bitcoin-cli -named createwallet wallet_name="Miner" > /dev/null
echo "Creando cartera 'Alice'"
bitcoin-cli -named createwallet wallet_name="Alice" > /dev/null

echo """
************************************************
* Configurar un Timelock relativo. Ejercicio 2 *
************************************************
"""
echo "Creando dirección para recompensa de minado en la cartera 'Miner'"
miner_address=$(bitcoin-cli -rpcwallet="Miner" -named getnewaddress label="Recompensa de Minería")
echo "Creada dirección: '$miner_address'"

mine_until_balance_equals "Miner" "$miner_address" "100"

echo ""
echo "Creando dirección de recepción para 'Alice'"
alice_address=$(bitcoin-cli -rpcwallet="Alice" -named getnewaddress label="Recepción de fondos")
echo "Creada dirección: '$alice_address'"

echo ""
echo "Creando dirección para recibir el cambio en la cartera 'Miner'"
miner_change_address=$(bitcoin-cli -rpcwallet="Miner" getrawchangeaddress legacy)
echo "Creada dirección: '$miner_change_address'"

echo ""
echo "Componiendo una transacción para 'Alice' con el primer UTXOs de 'Miner'"
utxos=$(find_first_utxos "Miner" "1")
amount="20"
change_amount="29.9999"

inputs=$(echo $utxos | jq 'map({ txid: .txid, vout: .vout })')
outputs='''{ "'$alice_address'": '$amount', "'$miner_change_address'": '$change_amount' }'''
send_alice_tx=$(bitcoin-cli -named createrawtransaction inputs="$inputs" outputs="$outputs")

echo ""
echo "Firmando la transacción y enviándola"
send_alice_tx_signed=$(bitcoin-cli -rpcwallet="Miner" signrawtransactionwithwallet $send_alice_tx | jq -r '.hex')
send_alice_tx_hash=$(bitcoin-cli sendrawtransaction "$send_alice_tx_signed")
echo "Enviada transacción '$send_alice_tx_hash'"

echo """
************************************************
* Configurar un Timelock relativo. Ejercicio 3 *
************************************************
"""
echo "Minando un bloque para procesar la transacción"
bitcoin-cli -rpcwallet="Miner" -generate 1 > /dev/null

echo ""
alice_balance=$(bitcoin-cli -rpcwallet="Alice" getbalance)
echo "Saldo de Alice: $alice_balance BTC"

echo """
************************************************
* Configurar un Timelock relativo. Ejercicio 4 *
************************************************
"""
echo "Creando dirección de recepción para 'Miner'"
miner_receive_address=$(bitcoin-cli -rpcwallet="Miner" -named getnewaddress label="Recepción de fondos")
echo "Creada dirección: '$miner_receive_address'"

echo ""
echo "Creando dirección para recibir el cambio en la cartera 'Alice'"
alice_change_address=$(bitcoin-cli -rpcwallet="Alice" getrawchangeaddress legacy)
echo "Creada dirección: '$alice_change_address'"

echo """
Componiendo una transacción para 'Miner' con el primer UTXOs de 'Alice' y
un timelock relativo de 10
"""
utxos=$(find_first_utxos "Alice" "1")
amount="10"
change_amount="9.9999"

inputs=$(echo $utxos | jq 'map({ txid: .txid, vout: .vout, sequence: 10 })')
outputs='''{ "'$miner_receive_address'": '$amount', "'$alice_change_address'": '$change_amount' }'''
send_miner_tx=$(bitcoin-cli -named createrawtransaction inputs="$inputs" outputs="$outputs")

echo """
************************************************
* Configurar un Timelock relativo. Ejercicio 5 *
************************************************
"""
echo "Firmando la transacción y enviándola"
send_miner_tx_signed=$(bitcoin-cli -rpcwallet="Alice" signrawtransactionwithwallet $send_miner_tx | jq -r '.hex')
send_miner_tx_hash=$(bitcoin-cli sendrawtransaction "$send_miner_tx_signed")

echo """
En la transacción que acabamos de componer, se ha asociado al UTXO de entrada un valor
'sequence' de 10. Esto significa que dicha transacción sólo podrá ser enviada cuando
hayan pasado 10 bloques desde que ese UTXO fue gastado (desde que la transacción que lo 
generó fue incluida en un bloque).

El envío de la transacción falla por esa razón. No puede ser aceptada hasta que no se dé
esa condición.
"""

echo """
**************************************************
* Gastar desde el Timelock relativo. Ejercicio 1 *
**************************************************
"""
echo "Minando 10 bloques para habilitar el gasto"
bitcoin-cli -rpcwallet="Miner" -generate 10 > /dev/null

echo "Enviando la transacción"
send_miner_tx_hash=$(bitcoin-cli sendrawtransaction "$send_miner_tx_signed")
echo "Enviada transacción '$send_miner_tx_hash'"

echo ""
alice_balance=$(bitcoin-cli -rpcwallet="Alice" getbalance)
echo "Saldo de Alice: $alice_balance BTC"

echo """
**************************
* Limpieza *
**************************
"""
clean
