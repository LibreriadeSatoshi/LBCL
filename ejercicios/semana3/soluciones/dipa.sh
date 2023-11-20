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

limpieza
inicio

#echo "Punto 1.Crear dos billeteras llamadas Miner y Trader."
#create_wallets
#ADDRESS_MINERO=$(bitcoin-cli -rpcwallet="Miner" getnewaddress "Recompensa de Mineria")


#echo "Punto 2.Crear una transacción desde Miner a Trader con la siguiente estructura (llamémosla la transacción parent):"
#mine_until_balance "Miner" $ADDRESS_MINERO 150



#### Configurar Multisig ####
# Punto 1. Crear tres monederos: Miner, Alice y Bob. Es importante usar billeteras sin descriptores, ya que sino lo hacemos, nos encontraremos con problemas al usar la opción de bitcoin-cli addmultisigaddress"
echo "Punto 1: Crear wallets: Miner, Alice y bob"

create_wallet "Miner"
create_wallet "Alice"
create_wallet "Bob"

sleep 2

# Punto 2.Fondear los monederos generando algunos bloques para Miner y enviando algunas monedas a Alice y Bob
echo "Fondeo Miner con 150, envio 50 BTC a Alice y a Bob, creo una multisig 2-de-2 con las pubKey de Alice y Bob"

# genero una direccion para la recompensa de mineria
address_minero=$(bitcoin-cli -rpcwallet="Miner" getnewaddress "Recompensa de Mineria")
mine_until_balance "Miner" $address_minero 150


# creo address para Alice y Bob
address_alice=$(bitcoin-cli -rpcwallet="Alice" getnewaddress)
#echo "Address de Alice: $address_alice"

address_bob=$(bitcoin-cli -rpcwallet="Bob" getnewaddress)
#echo "Address de Bob $address_bob"

# enviar algunas monedas a Bob y Alice
bitcoin-cli -rpcwallet="Miner" sendtoaddress $address_alice 20
bitcoin-cli -rpcwallet="Miner" sendtoaddress $address_bob 20

# confirmo el bloque
bitcoin-cli generatetoaddress 1 $address_minero >/dev/null

# chequeo balance
get_balance "Alice"
get_balance "Bob"

# Punto 3.Crear una dirección Multisig 2-de-2 combinando las claves públicas de Alice y Bob
echo "Crear una dirección Multisig 2-de-2 combinando las claves públicas de Alice y Bob"

pubKey_alice=$(bitcoin-cli -rpcwallet='Alice' -named getaddressinfo address=$address_alice | jq -r '.pubkey')
pubKey_bob=$(bitcoin-cli -rpcwallet='Bob' -named getaddressinfo address=$address_bob | jq -r '.pubkey')


multisig_alice=$(bitcoin-cli -rpcwallet='Alice' -named addmultisigaddress nrequired=2 keys='["'$pubKey_alice'","'$pubKey_bob'"]')
multisig_bob=$(bitcoin-cli -rpcwallet='Bob' -named addmultisigaddress nrequired=2 keys='["'$pubKey_alice'","'$pubKey_bob'"]')

address_multisig=$(echo $multisig_alice | jq -r '.'address)

sleep 3

# Punto 4.Crear una Transacción Bitcoin Parcialmente Firmada (PSBT) para financiar la dirección multisig con 20 BTC, tomando 10 BTC de Alice y 10 BTC de Bob, y proporcionando el cambio correcto a cada uno de ellos.
echo "Crear una Transacción Bitcoin Parcialmente Firmada (PSBT) para financiar la dirección multisig con 20 BTC, tomando 10 BTC de Alice y 10 BTC de Bob, y proporcionando el cambio correcto a cada uno de ellos."

utxo_txid_alice=$(bitcoin-cli -rpcwallet="Alice" listunspent | jq -r '.[0] | .txid')
utxo_vout_alice=$(bitcoin-cli -rpcwallet="Alice" listunspent | jq -r '.[0] | .vout')

utxo_txid_bob=$(bitcoin-cli -rpcwallet="Bob" listunspent | jq -r '.[0] | .txid')
utxo_vout_bob=$(bitcoin-cli -rpcwallet="Bob" listunspent | jq -r '.[0] | .vout')


changeaddress_alice=$(bitcoin-cli -rpcwallet="Alice"  getrawchangeaddress)
changeaddress_bob=$(bitcoin-cli -rpcwallet="Bob"  getrawchangeaddress)


psbt=$(bitcoin-cli -named createpsbt inputs='''[ { "txid": "'$utxo_txid_alice'", "vout": '$utxo_vout_alice' }, { "txid": "'$utxo_txid_bob'", "vout": '$utxo_vout_bob' } ]''' outputs='''{ "'$address_multisig'": 20, "'$changeaddress_alice'": 9.9998, "'$changeaddress_bob'": 9.9998 }''')

#firma alice
psbt_signed_alice=$(bitcoin-cli -rpcwallet="Alice" walletprocesspsbt $psbt | jq -r '.psbt')
#echo $psbt_signed_alice
#bitcoin-cli -named analyzepsbt psbt=$psbt_signed_alice | jq

#firma bob
psbt_signed_bob=$(bitcoin-cli -rpcwallet="Bob" walletprocesspsbt $psbt_signed_alice| jq -r '.psbt')
#bitcoin-cli analyzepsbt $psbt_signed_bob | jq

#finalizo psbt
psbt_hex=$(bitcoin-cli finalizepsbt $psbt_signed_bob | jq -r '.hex')
psbt_tx=$(bitcoin-cli -named sendrawtransaction hexstring=$psbt_hex)

# Punto 5. Confirmar el saldo mediante la minería de algunos bloques adicionales.
echo "Confirmar el saldo mediante la minería de algunos bloques adicionales" 
bitcoin-cli generatetoaddress 3 $address_minero >/dev/null

# Punto 6.Imprimir los saldos finales de Alice y Bob.
echo "los saldos finales de Alice y Bob son:"
get_balance "Alice"
get_balance "Bob"


#### Liquidar Multisig ####
# Punto 7. Crear una PSBT para gastar fondos del multisig, asegurando que se distribuyan igualmente 10 BTC entre Alice y Bob después de tener en cuenta las tarifas.
echo "Crear una PSBT para gastar fondos del multisig, asegurando que se distribuyan igualmente 10 BTC entre Alice y Bob después de tener en cuenta las tarifas" 
# incorporo el address de la multisig a la wallet de Alice y de Bob
bitcoin-cli -named -rpcwallet="Alice" importaddress address=$address_multisig
bitcoin-cli -named -rpcwallet="Alice" importaddress address=$address_multisig

# creo direcciones de cambio
changeaddress_alice_2=$(bitcoin-cli -rpcwallet="Alice"  getrawchangeaddress)
changeaddress_bob_2=$(bitcoin-cli -rpcwallet="Bob"  getrawchangeaddress)

# creo psbt
psbt_multi=$(bitcoin-cli -named createpsbt inputs='''[ { "txid": "'$psbt_tx'", "vout": 0 } ]''' outputs='''{ "'$changeaddress_alice_2'": 9.9998, "'$changeaddress_bob_2'": 9.9998 }''')

#Punto 8. Firmar la PSBT por Alice.
psbt_signed_alice_multi=$(bitcoin-cli -rpcwallet="Alice" walletprocesspsbt $psbt_multi | jq -r '.psbt')

#Punto 9. Firmar la PSBT por Bob.
psbt_signed_bob_multi=$(bitcoin-cli -rpcwallet="Bob" walletprocesspsbt $psbt_signed_alice_multi | jq -r '.psbt')

#Extraer y transmitir la transacción completamente firmada.
psbt_multi_hex=$(bitcoin-cli finalizepsbt $psbt_signed_bob_multi | jq -r '.hex')
psbt_multi_tx=$(bitcoin-cli -named sendrawtransaction hexstring=$psbt_multi_hex)

# Punto 10. Confirmar el saldo mediante la minería de algunos bl	oques adicionales.
bitcoin-cli generatetoaddress 3 $address_minero >/dev/null

# Punto 11.Imprimir los saldos finales de Alice y Bob.           
get_balance "Alice"
get_balance "Bob"

