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

# Create all wallets ("Miner" and "Trader")
create_wallets() {
 bitcoin-cli -regtest -named createwallet wallet_name="Miner" > /dev/null  
 bitcoin-cli -regtest -named createwallet wallet_name="Trader" > /dev/null
}


generate_address() {
  ADDRESS=$(bitcoin-cli -rpcwallet="$1" getnewaddress "$2")
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


echo "Punto 1.Crear dos billeteras llamadas Miner y Trader."

create_wallets

ADDRESS_MINERO=$(bitcoin-cli -rpcwallet="Miner" getnewaddress "Recompensa de Mineria")


echo "Punto 2.Crear una transacción desde Miner a Trader con la siguiente estructura (llamémosla la transacción parent):"
mine_until_balance "Miner" $ADDRESS_MINERO 150

echo "Punto 3. Realizar consultas al "mempool" del nodo para obtener los detalles de la transacción parent. Utiliza los detalles para crear una variable JSON con la siguiente estructura:"

recipient=$(bitcoin-cli -rpcwallet="Trader" getnewaddress)

changeaddress=$(bitcoin-cli -rpcwallet="Miner"  getrawchangeaddress)

utxo_txid_1=$(bitcoin-cli -rpcwallet="Miner" listunspent | jq -r '.[0] | .txid')
utxo_vout_1=$(bitcoin-cli -rpcwallet="Miner" listunspent | jq -r '.[0] | .vout')

utxo_txid_2=$(bitcoin-cli -rpcwallet="Miner" listunspent | jq -r '.[1] | .txid')
utxo_vout_2=$(bitcoin-cli -rpcwallet="Miner" listunspent | jq -r '.[1] | .vout')

parent=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo_txid_1'", "vout": '$utxo_vout_1', "sequence": 1}, { "txid": "'$utxo_txid_2'", "vout": '$utxo_vout_2' } ]''' outputs='''{ "'$recipient'": 70.00000, "'$changeaddress'": 29.99999 }''')


echo "Punto 4. Firmar y transmitir la Transaccion"

signed_parent=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet "$parent" | jq -r '.hex')
txid_parent=$(bitcoin-cli -rpcwallet=Miner sendrawtransaction $signed_parent)

echo "Punto 5.Realizar consultas al "mempool" del nodo para obtener los detalles de la transacción parent"

input_trader=$(bitcoin-cli decoderawtransaction $signed_parent | jq -r '.vin[0] | { txid: .txid, vout: .vout }')
input_miner=$(bitcoin-cli decoderawtransaction $signed_parent | jq -r '.vin[1] | { txid: .txid, vout: .vout }')

output_trader=$(bitcoin-cli decoderawtransaction $signed_parent | jq -r '.vout[0] | { script_pubkey: .scriptPubKey.hex , amount: .value }')

output_miner=$(bitcoin-cli decoderawtransaction $signed_parent | jq -r '.vout[1] | { script_pubkey: .scriptPubKey.hex , amount: .value }')
		
tx_fee=$(bitcoin-cli getmempoolentry $txid_parent | jq -r '.fees .base')

tx_weight=$(bitcoin-cli getmempoolentry $txid_parent | jq -r '.vsize')

json='{ "input": [ '$input_trader', '$input_miner' ], "output": [ '$output_miner', '$output_trader' ], "Fees": '$tx_fee', "Weight": '$tx_weight' }'

echo "Punto 6.Imprime el JSON anterior en la terminal."
echo $json | jq

echo "Punto 7. Vamos a crear la transaccion child que gaste uno de las salidas de la transaccion parent anterior"
changeaddress_2=$(bitcoin-cli -rpcwallet=Miner getrawchangeaddress)

child=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txid_parent'", "vout": '1' } ]''' outputs='''{ "'$changeaddress_2'": 29.99998 }''')

signed_child=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $child | jq -r '.hex')

txid_child=$(bitcoin-cli sendrawtransaction $signed_child)

bitcoin-cli decoderawtransaction $signed_parent

echo "Punto 8. A continuacion los detalles de la transaccion child en la mempool mediante el comando getmempoolentry"
bitcoin-cli getmempoolentry $txid_child

echo "Punto 9. Vamos a aumentar la tarifa de la transaccion parent usando RBF"

parent_rbf=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo_txid_1'", "vout": '$utxo_vout_1', "sequence": 1}, { "txid": "'$utxo_txid_2'", "vout": '$utxo_vout_2' } ]''' outputs='''{ "'$recipient'": 70.00000, "'$changeaddress'": 29.9999 }''')

echo "Punto 10. Firmamos y transmitimos la transaccion"

signed_parent_rbf=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $parent_rbf | jq -r '.hex')
txid_parent_rbf=$(bitcoin-cli sendrawtransaction $signed_parent_rbf)


echo "Punto 11. Consultar transaccion child"

bitcoin-cli getmempoolentry $txid_child
echo "La transaccion child no se encuentra en la mempool"
bitcoin-cli getmempoolentry $txid_parent
echo "La transaccion parent tampoco se encuentra en la mempool"

echo "Punto 12. Imprime una explicación en la terminal de lo que cambió en los dos resultados de getmempoolentry para las transacciones child y por qué."

echo "Después de transmitir la transacción RBF, esta reemplazó a la transacción principal. La transacción secundaria, que utilizaba una de las salidas de la transacción principal, ya no era válida debido a la actualización, por lo que fue eliminada de la mempool."
