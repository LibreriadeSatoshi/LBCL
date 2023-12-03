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

#### Configurar timelock relativo ####

# Punto 1. Crear dos billeteras: Miner, Alice
echo "Creando los monederos Miner, Alice"

create_wallet "Miner"
create_wallet "Alice"

sleep 2

# Punto 2. Fondear las billeteras generando algunos bloques para Miner y enviando algunas monedas a Alice
echo "Fondeando monederos Miner y enviando monedas a Alice..."

# Fondeo con 150 BTC a Minero

address_minero=$(bitcoin-cli -rpcwallet="Miner" getnewaddress "Recompensa de Mineria")

mine_until_balance "Miner" $address_minero 150

## Envio 50 BTC a Alice ##

# creo address para Empleador
address_alice=$(bitcoin-cli -rpcwallet="Alice" getnewaddress)

# envio monedas a Alice
bitcoin-cli -rpcwallet="Miner" sendtoaddress $address_alice 50 >/dev/null

# Punto 3. Confirmar la transacción y chequar que Alice tiene un saldo positivo
echo "Confirmando transaccion..."

bitcoin-cli generatetoaddress 1 $address_minero >/dev/null

sleep 2

# chequeo saldo Empleador
echo "Chequeando saldo positivo de Alice..."

get_balance "Alice"

sleep 2

### preparo raw transaction de Alice a minero

# Punto 4. Crear una transacción en la que Alice pague 10 BTC al Miner, pero con un timelock relativo de 10 bloques

# UTXO
utxo_txid=$(bitcoin-cli -rpcwallet="Alice" listunspent | jq -r '.[0] | .txid')
utxo_vout=$(bitcoin-cli -rpcwallet="Alice" listunspent | jq -r '.[0] | .vout')


# genero un address de cambio para Alice
changeaddress=$(bitcoin-cli -rpcwallet="Alice"  getrawchangeaddress)

# genero otrA direccion para Minero
address_minero2=$(bitcoin-cli -rpcwallet="Miner" getnewaddress)


rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo_txid'", "vout": '$utxo_vout', "sequence": '10'}]''' outputs='''{ "'$address_minero2'": 10, "'$changeaddress'": 39.9998 }''')

# Chequeo tx
#bitcoin-cli decoderawtransaction $rawtxhex

# Punto 5. Informa en un comentario qué sucede cuando intentas transmitir esta transacción.
signedtx=$(bitcoin-cli -rpcwallet="Alice" -named signrawtransactionwithwallet hexstring=$rawtxhex | jq -r '.hex')

bitcoin-cli -rpcwallet="Alice" -named sendrawtransaction hexstring=$signedtx


####  Gastar desde el timelock relativo  ####

bitcoin-cli generatetoaddress 10 $address_minero >/dev/null

echo "Difundir la segunda transacción. Confirmarla generando un bloque más
"
bitcoin-cli -rpcwallet="Alice" -named sendrawtransaction hexstring=$signedtx


echo "Confirmando transaccion..."
bitcoin-cli generatetoaddress 1 $address_minero >/dev/null

sleep 2

# chequeo saldo Alice
echo "Chequeando saldo  Alice..."

get_balance "Alice"


