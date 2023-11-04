#!/bin/bash

# Este script requiere instalar 'jq' para procesar objetos JSON
# sudo apt install jq -y

# Importa la funciones de creación de direcciones
source ./create_address_function.sh

# create_wallet - Crea una nueva billetera.
#
# Comprueba que se ha creado comparando el nombre de billetera devuelto por
# bitcoin-cli. Muestra un mensaje de error y detiene la ejecución si no es así.
#
# Parámetros:
#   $1 - El nombre de la billetera que se desea crear.
create_wallet() {

    wallet_name=$1
    
    createwallet_output=$(bitcoin-cli -named createwallet wallet_name="$wallet_name")
    created_name=$(echo $createwallet_output | jq -r '.name')
    
    if [ "$created_name" != "$wallet_name" ]
    then
        (>&2 echo "Error. No se ha podido crear la cartera")
        exit 1
    fi
}

# mine_until_balance - Mina bloques hasta que haya saldo disponible en la cartera.
#
# Mina nuevos bloques recibiendo la recompensa en la dirección indicada. Tras cada
# bloque comprueba el saldo y si no hay saldo disponible, mina otro bloque hasta que
# lo haya.
#
# Nota 1: Esta función da por hecho que el saldo inicial es cero. Si no, no mina nuevos bloques.
# Nota 2: Esto es necesario porque el protocolo bitcoin no confirma los saldos recibidos
#         por minería de bloques hasta que se han minado X bloques tras él. (En el caso del
#         modo regtest, se necesitan 100 bloques tras el bloque en cuestión).
# Nota 3: Si se indica una dirección que no pertenece a la cartera indicada, seguirá minando
#         bloques hasta que se cancele el proceso manualmente.
#
# Parámetros:
#   $1 - Nombre de la cartera asociada a la dirección de recompensa.
#   $2 - Dirección de recompensa.
mine_until_balance() {

    wallet_name=$1
    mining_address=$2

    blocks_mined=0
    balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance)

    echo ""
    echo -n "Minando bloques... "

    while (( $(echo "$balance" | awk '{if ($1 <= "0.00000000") print 1; else print 0;}') ))
    do
        bitcoin-cli generatetoaddress 1 "$mining_address" > /dev/null
        blocks_mined=$(($blocks_mined + 1))
        echo -n "$blocks_mined "
        balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance)
    done

    echo ""
    echo "Se minaron $blocks_mined bloques hasta que el saldo se incrementó"
    echo ""
    echo "Balance actual: $balance"
}

echo "Creando cartera 'Miner'"
create_wallet "Miner"
echo "Creando cartera 'Trader'"
create_wallet "Trader"

echo ""
echo "Creando dirección para recompensa de minado en la cartera 'Miner'"
miner_address=$(create_address "Miner" "Recompensa de Minería")
echo "Creada dirección: '$miner_address'"

mine_until_balance "Miner" "$miner_address"