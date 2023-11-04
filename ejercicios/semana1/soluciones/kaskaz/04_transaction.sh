#!/bin/bash

# Importa la funciones de creación de direcciones
source ./create_address_function.sh

# send_bitcoins - Realiza una transferencia de bitcoins.
#
# Comprueba que se han enviado verificando que bitcoin-cli ha devuelto una cadena
# de texto, que corresponde al ID de la transacción creada. Muestra un mensaje de 
# error y detiene la ejecución si no es así.
#
# Parámetros:
#   $1 - Nombre de la cartera origen de la transacción.
#   $2 - Dirección destino de la transacción.
#   $3 - Cantidad a transferir.
send_bitcoins() {

    origin_wallet_name=$1
    destination_address=$2
    amount=$3

    created_tx_output=$(bitcoin-cli -rpcwallet="$origin_wallet_name" sendtoaddress "$destination_address" $amount)

    if [ ! -z "$created_tx_output" ]
    then
        echo "$created_tx_output"
    else
        (>&2 echo "Error. No se ha podido enviar '$amount' bitcoins a la dirección '$destination_address'")
        exit 1
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

# show_tx_details - Muestra los detalles de una transacción.
#
# Obtiene los detalles de una transacción y muestra los valores
# requeridos por el ejercicio como texto formateado.
#
# Parámetros:
#   $1 - Nombre de la cartera origen de la transacción.
#   $2 - Dirección destino de la transacción.
#   $3 - Cantidad a transferir.
show_tx_details() {

    tx_id=$1

    gettx_output=$(bitcoin-cli -named getrawtransaction txid="$tx_id" verbose="2")

    from=$(         echo "$gettx_output" | jq -r '.vin[0].prevout.scriptPubKey.address')
    from_amount=$(  echo "$gettx_output" | jq -r '.vin[0].prevout.value')
    to=$(           echo "$gettx_output" | jq -r '.vout[1].scriptPubKey.address')
    to_amount=$(    echo "$gettx_output" | jq -r '.vout[1].value')
    change_addr=$(  echo "$gettx_output" | jq -r '.vout[0].scriptPubKey.address')
    change_amount=$(echo "$gettx_output" | jq -r '.vout[0].value')
    fee=$(          echo "$gettx_output" | jq -r '.fee')
    blockhash=$(    echo "$gettx_output" | jq -r '.blockhash')

    blockheight=$(bitcoin-cli getblock "$blockhash" | jq -r '.height')

    echo "ID de la transacción: '$tx_id'"
    echo ""
    echo "Dirección del remitente ('Miner'): '$from'"
    echo "Cantidad enviada: '$(format_btc_decimal $from_amount)'"
    echo ""
    echo "Dirección del destinatario ('Trader'): '$to'"
    echo "Cantidad recibida: '$(format_btc_decimal $to_amount)'"
    echo ""
    echo "Dirección de envío del cambio ('Miner'): '$change_addr'"
    echo "Cantidad enviada como cambio: '$(format_btc_decimal $change_amount)'"
    echo ""
    echo "Importe de la comisión: '$(format_btc_decimal $fee)'"
    echo "Cantidad recibida + cambio + fee = '$(format_btc_decimal "$to_amount + $change_amount + $fee")'"
    echo ""
    echo "Nº del bloque que incluye la transacción: '$blockheight'"
}

echo "Creando dirección para recepción de bitcoins en la cartera 'Trader'"
trader_address=$(create_address "Trader" "Recibido")
echo "Creada dirección: '$trader_address'"

echo ""
echo "Enviando fondos de la cartera 'Miner' a la dirección recién creada"
tx_id=$(send_bitcoins "Miner" "$trader_address" "20")
echo "Transacción generada con ID: '$tx_id'"

echo ""
echo "Mostrando datos de la transacción creada mientras está en la mempool:"
bitcoin-cli getmempoolentry "$tx_id"

echo ""
echo "Minando un bloque adicional para confirmar la transacción"
new_block_bash=$(bitcoin-cli -rpcwallet="Miner" -generate 1 | jq -r '.blocks[0]')
echo "Minado bloque con hash '$new_block_bash'"

echo ""
echo "Detalles de la transacción una vez confirmada:"
echo "----------------------------------------------"
show_tx_details "$tx_id"

echo ""
sender_balance=$(bitcoin-cli -rpcwallet="Miner" getbalance)
destination_balance=$(bitcoin-cli -rpcwallet="Trader" getbalance)
echo "Saldo del remitente ('Miner') tras la transacción: '$(format_btc_decimal $sender_balance)'"
echo "Saldo del destinatario ('Trader') tras la transacción: '$(format_btc_decimal $destination_balance)'"