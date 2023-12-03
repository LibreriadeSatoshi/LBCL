#!/bin/bash

# Prints an info message
# $1 - Text to print out
print_info() {
  echo -e "\n${color_none}$1"
}

# Prints success message in green
# $1 - Text to print out
print_success() {
  echo -e "\n${color_green}$1${color_none}"
}

# Prints an error message in red
# $1 - Text to print out
print_error() {
  echo -e "\n${color_red}$1${color_none}"
}

# Prints a warning message in yellow
# $1 - Text to print out
print_warning() {
  echo -e "\n${color_yellow}$1${color_none}"
}

limpieza () {
	# Detener bitcoind y limpiar los archivos descargados para empezar de 0.
	bitcoin-cli stop
	rm -r $HOME/.bitcoin
	
sleep 3
}

inicio () {
		
 mkdir -p "$HOME/.bitcoin"
 cat >>  "$HOME/.bitcoin/bitcoin.conf" << EOF
 regtest=1
 fallbackfee=0.0001
 server=1
 txindex=1
EOF

 # inciando bircoind
 bitcoind -daemon 2>&1
 sleep 5
}

# Create all wallets
create_wallet() {

 nombre_wallet=$1
 bitcoin-cli -regtest -named createwallet wallet_name="$nombre_wallet" descriptors=false > /dev/null  
}


generate_address() {
  ADDRESS=$(bitcoin-cli -rpcwallet="$1" getnewaddress "$2")
}

get_balance() { 
    
    wallet_name=$1
    balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance | bc)
    #balance_entero=$(echo "($balance + 0.5) / 1" | bc)
    print_success "El balance en la billetera '$wallet_name' es de  $balance"

}

mine_until_balance() {

    wallet_name=$1
    mining_address=$2
    target_balance=$3
    
    target_blocks=$(echo "($target_balance / 50 + 0.5) / 1 + 100" | bc)

    echo ""
    echo -n "Minando bloques... "

    bitcoin-cli generatetoaddress $target_blocks $mining_address >/dev/null

    sleep 3

    balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance | bc)
    balance_entero=$(echo "($balance + 0.5) / 1" | bc)
    echo $balance_entero
    
    if [ $target_balance -eq $balance_entero ]; then
    	print_success "Se genero un balance de  '$balance' en la billetera '$wallet_name'"
    else
    	print_error "No se pudo genera el balance"
    fi
}

mine_until_block() {

    wallet_name="Minero"
    mining_address=$(bitcoin-cli -rpcwallet="Miner" getnewaddress)
    
    target_block=$1

    actual_block=$(bitcoin-cli getblockcount)

    required_blocks=$(echo "($target_block - $actual_block)" | bc)

    echo ""
    echo -n "Minando bloques... "

    bitcoin-cli generatetoaddress $required_blocks $mining_address >/dev/null

    sleep 2
  
    actual_block=$(bitcoin-cli getblockcount)

    if [ $target_block -eq $actual_block ]; then
        print_success "Se llego al bloque objetivo: $target_block"
    else
        print_error "No se llego al bloque objetivo"
    fi
}

limpieza
inicio

#### Configurar un contrato Timelock ####

# Punto 1. Crea tres monederos: Miner, Empleado y Empleador.
echo "Creando los monederos Miner, Empleado y Empleador"

create_wallet "Miner"
create_wallet "Empleado"
create_wallet "Empleador"

sleep 2

# Punto 2. Fondea los monederos generando algunos bloques para Miner y enviando algunas monedas al Empleador.
echo "Fondeando monederos Miner y Empleador..."

# Fondeo con 150 BTC a Minero

address_minero=$(bitcoin-cli -rpcwallet="Miner" getnewaddress "Recompensa de Mineria")
mine_until_balance "Miner" $address_minero 150

## Envio 50 BTC a empleador ##

# creo address para Empleador
address_empleador=$(bitcoin-cli -rpcwallet="Empleador" getnewaddress)

# envio monedas a Empleador
bitcoin-cli -rpcwallet="Miner" sendtoaddress $address_empleador 50 >/dev/null

# confirmo el bloque
bitcoin-cli generatetoaddress 1 $address_minero >/dev/null

sleep 2

# chequeo saldo Empleador
echo "Chequeando si el empleador tiene fondos..:"

get_balance "Empleador"

sleep 2

# Punto 3. Crea una transacción de salario de 40 BTC, donde el Empleador paga al Empleado.
# Punto 4. Agrega un timelock absoluto de 500 bloques para la transacción, es decir, la transacción no puede incluirse en el bloque hasta que se haya minado el bloque 500.

### preparo raw transaction de empleador a empleado empleado

# UTXO
utxo_txid=$(bitcoin-cli -rpcwallet="Empleador" listunspent | jq -r '.[0] | .txid')
utxo_vout=$(bitcoin-cli -rpcwallet="Empleador" listunspent | jq -r '.[0] | .vout')

# sanity check de txid y vout
#bitcoin-cli -rpcwallet="Empleador" listunspent
#echo $utxo_txid
#echo $utxo_vout

# genero un address de cambio para el empleador
changeaddress=$(bitcoin-cli -rpcwallet="Empleador"  getrawchangeaddress)

# genero una direccion para empleado
address_empleado=$(bitcoin-cli -rpcwallet="Empleado" getnewaddress)


rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo_txid'", "vout": '$utxo_vout' } ]''' outputs='''{ "'$address_empleado'": 40, "'$changeaddress'": 9.9999 }''' locktime=500)

# Chequeo tx
#bitcoin-cli decoderawtransaction $rawtxhex

# Punto 5. Informa en un comentario qué sucede cuando intentas transmitir esta transacción.
signedtx=$(bitcoin-cli -rpcwallet="Empleador" -named signrawtransactionwithwallet hexstring=$rawtxhex | jq -r '.hex')

bitcoin-cli -rpcwallet="Empleador" -named sendrawtransaction hexstring=$signedtx

echo "Como no se llego al bloque 500 la transaccion no es final y no puede incluirse en el bloque"

#Mina hasta el bloque 500 y transmite la transacción.

mine_until_block 500
txid_empleador=$(bitcoin-cli -rpcwallet="Empleador" -named sendrawtransaction hexstring=$signedtx)

bitcoin-cli generatetoaddress 1 $address_minero >/dev/null

# Punto 7. Imprime los saldos finales del Empleado y Empleador
get_balance "Empleador"
get_balance "Empleado"

#### Gastar desde el Timelock ###
# Punto 1. Crea una transacción de gasto en la que el Empleado gaste los fondos a una nueva dirección de monedero del Empleado.
utxo_txid=$(bitcoin-cli -rpcwallet="Empleado" listunspent | jq -r '.[0] | .txid')
utxo_vout=$(bitcoin-cli -rpcwallet="Empleado" listunspent | jq -r '.[0] | .vout')

changeaddress=$(bitcoin-cli -rpcwallet="Empleado" getrawchangeaddress)

# Punto 2. Agrega una salida OP_RETURN en la transacción de gasto con los datos de cadena "He recibido mi salario, ahora soy rico".

op_return_data=$(echo -n "He recibido mi salario, ahora soy rico"| sha256sum | cut -d ' ' -f 1)

#echo "$op_return_data"

rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo_txid'", "vout": '$utxo_vout' } ]''' outputs='''{ "data": "'$op_return_data'", "'$changeaddress'": 39.9998 }''')

#bitcoin-cli decoderawtransaction $rawtxhex

# Punto 3. Extrae y transmite la transacción completamente firmada.

signedtx=$(bitcoin-cli -rpcwallet="Empleado" -named signrawtransactionwithwallet hexstring=$rawtxhex | jq -r '.hex')

txid_empleado=$(bitcoin-cli -rpcwallet="Empleado" -named sendrawtransaction hexstring=$signedtx)

bitcoin-cli generatetoaddress 1 $address_minero >/dev/null

#Imprime los saldos finales del Empleado y Empleador

get_balance "Empleador"
get_balance "Empleado"
