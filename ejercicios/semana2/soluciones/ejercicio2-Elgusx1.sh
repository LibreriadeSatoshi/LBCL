#!/bin/bash
echo "Ejercicio 1 de Elgusx1"
sudo apt-get install -y bc jq 
echo "Descargamos los binarios ya compilados"
wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-x86_64-linux-gnu.tar.gz
echo "Se verifican que los vinarios sean correctos por medio de los hashes y firmas publicas"
wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS
wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS.asc
#sha256sum --ignore-missing --check SHA256SUMS
# Verificar los hashes SHA256 de los archivos descargados
if sha256sum --ignore-missing --check SHA256SUMS; then
  echo "Todos los hashes coinciden. Los archivos son auténticos."
else
  echo "Advertencia: Al menos un archivo tiene un hash que no coincide. No se pueden verificar todos los archivos."
fi
sleep 3
#Se comprueban las llaves publicas
git clone https://github.com/bitcoin-core/guix.sigs
gpg --import guix.sigs/builder-keys/*
gpg --verify SHA256SUMS.asc
sleep 3
echo "Extraemos los binarios"
tar -xvf bitcoin-25.0-x86_64-linux-gnu.tar.gz
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-25.0/bin/*
echo "Creamos el directorio bitcoin y el archivo bitcoin.cof con su configuracion"
mkdir $HOME/.bitcoin
cat <<EOF >/root/.bitcoin/bitcoin.conf
    regtest=1
    fallbackfee=0.0001
    server=1
    txindex=1
EOF
sleep 3
echo "Comenzamos bitcoin"
bitcoind -daemon
sleep 3
#Se crean las carteras 
bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true
sleep 1
address_mining=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Direccion de Mineria")
bitcoin-cli generatetoaddress 103 "$address_mining"
#Obtenemos el balance

final_balance=$(bitcoin-cli -rpcwallet=Miner getbalance)
echo "Saldo final de la billetera Miner: $final_balance"
#Direccion de Trader para recibir
address_traderreceiver=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Trader-Recibido")
address_minergiveback=$(bitcoin-cli -rpcwallet=Miner getnewaddress "MinerCambio")
#Transaccion en crudo
utxo_txid_0=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .txid')
utxo_vout_0=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .vout')
utxo_txid_1=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[1] | .txid')
utxo_vout_1=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[1] | .vout')
#Armamos la transaccion
txParent=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo_txid_0'", "vout": '$utxo_vout_0', "sequence":1}, {"txid": "'$utxo_txid_1'", "vout": '$utxo_vout_1', "sequence":1}  ]''' outputs='''[{ "'$address_traderreceiver'": 70 },{ "'$address_minergiveback'": 29.99999 }]''')

echo "Transaccion en crudo(hex) donde se envia 70 a Traider: $txParent"
#FIrmando la transaccion y transmitiendola.
toSingtx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $txParent | jq -r '.hex')
parent=$(bitcoin-cli sendrawtransaction $toSingtx)

echo "Muestra el id de la transaccion padre $parent"
#Consulta a la mempool nuestra transaccion, se debe obtener los datos para armar el json

input_0=$(bitcoin-cli decoderawtransaction $toSingtx | jq -r '.vin[0] | { txid: .txid, vout: .vout }')
output_0=$(bitcoin-cli decoderawtransaction $toSingtx | jq -r '.vout[0] | { script_pubkey: .scriptPubKey , amount: .value }')
input_1=$(bitcoin-cli decoderawtransaction $toSingtx | jq -r '.vin[1] | { txid: .txid, vout: .vout }')
output_1=$(bitcoin-cli decoderawtransaction $toSingtx | jq -r '.vout[1] | { script_pubkey: .scriptPubKey , amount: .value }')
txfee=$(bitcoin-cli getmempoolentry $parent | jq -r '.fees .base')
txweight=$(bitcoin-cli getmempoolentry $parent | jq -r .weight)
#Se arma el json
json='{ "input": [ '$input_0', '$input_1' ], "output": [ '$output_0', '$output_1' ], "Fees": '$txfee', "Weight": '$txweight' }'

echo "$json"

#Se crea la transaccion child
#Està serà la nueva direccion del cambio
child_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "MinerChildCambio")
txchild=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$parent'", "vout": '1' } ]''' outputs='''{ "'$child_miner'": 29.99997 }''')
toSingtxchild=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $txchild | jq -r '.hex')

child=$(bitcoin-cli sendrawtransaction $toSingtxchild)
echo "se muestra la transaccion hija en la mempool"
bitcoin-cli getmempoolentry $child
echo "Se muestran las 2 transacciones en la mempool"
bitcoin-cli getrawmempool
#Usamos ahora RBF para aumentar el fee de la transaccion parent
echo "Se construye una transaccion rbf con los datos de la parent"
newtxParent=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo_txid_0'", "vout": '$utxo_vout_0', "sequence":1}, {"txid": "'$utxo_txid_1'", "vout": '$utxo_vout_1', "sequence":1}  ]''' outputs='''[{ "'$address_traderreceiver'": 70 },{ "'$address_minergiveback'": 29.999}]''')

#Se firma esta nueva transaccion y se transmite
toSingtxNewParent=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $newtxParent | jq -r '.hex')
rbf=$(bitcoin-cli sendrawtransaction $toSingtxNewParent)
echo "La transaccion rbf tiene el txid $rbf"
#Se consulta en la mempool si aun existe la transaccion child 
echo "Se consulta la mempool para saber si existe la transaccion child"
bitcoin-cli getrawmempool
