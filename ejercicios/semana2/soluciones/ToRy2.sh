#! /bin/bash
# Transacciones En Bitcoin Core 25.0 -Regtest.
# Por: ToRy "☯The Purpple⚡ 🥷🏻ＮＩＮＪΛ🥷"

echo  " Iniciando Bitcoin... "
bitcoind-demonio

# creando dos billeteras
bitcoin-cli -named createwallet wallet_name= " Minero " descriptores=true
bitcoin-cli -named createwallet wallet_name= " Comerciante " descriptores=true

# Obtenemos el saldo y 150 minando 103 bloques
dirección_minería= $( bitcoin-cli -rpcwallet=Minero getnewaddress " Mineria " )
bitcoin-cli generar dirección 103 " $ dirección_minería "


balance_final= $( bitcoin-cli -rpcwallet=Miner getbalance )
echo  " Saldo final de la billetera Miner: $final_balance "

# Dirección de Trader para recibir + Dirección de Miner Cambio
dirección_traderreceiver= $( bitcoin-cli -rpcwallet=Trader getnewaddress " Recibido " )
dirección_minergiveback= $( bitcoin-cli -rpcwallet=Minero getnewaddress " Cambio " )

# Transacción en crudo + jq
utxo_txid_0= $( bitcoin-cli -rpcwallet=Lista de mineros no gastados | jq -r ' .[0] | .txid ' )
utxo_vout_0= $( bitcoin-cli -rpcwallet=Lista de mineros no gastados | jq -r ' .[0] | .vout ' )
utxo_txid_1= $( bitcoin-cli -rpcwallet=Lista de mineros no gastados | jq -r ' .[1] | .txid ' )
utxo_vout_1= $( bitcoin-cli -rpcwallet=Lista de mineros no gastados | jq -r ' .[1] | .vout ' )

# Armando la transacción + 2 salidas + 1 entrada
txParent= $( bitcoin-cli -named createrawtransaction inputs= ' ' ' [ { "txid": " ' $utxo_txid_0 ' ", "vout": ' $utxo_vout_0 ' , "sequence":1}, {"txid": " ' $utxo_txid_1 ' ", "vout": ' $utxo_vout_1 ' , "sequence":1} ] ' ' ' salidas= ' ' ' [{ " ' $address_traderrecibido ' ": 70 },{ " ' $address_minercambio ' ": 29.99999 }] ' ' ' )
echo  " creamos una transaccion en crudo donde enviamos 70BTC a Trader=Recibido desde Miner y 29.99999 a Miner=Cambio "

# FIrmando y Transmisión.
echo  " Transaccion en crudo(hex) donde se envia 70 a Trader: $txParent "

toSingtx= $( bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $txParent  | jq -r ' .hex ' )
echo  " transacción firmada "

padre = $( bitcoin-cli sendrawtransaction $toSingtx )
echo  " La transacción se ha enviado su identificación es $parent "

echo  " Muestra el id de la transacción padre $parent "
# Consulta a la mempool nuestra transacción, se debe obtener los datos para armar el json

# Primero vemos todos los valores que necesitamos
echo  " Punto 5.Realizar consultas al " mempool " del nodo para obtener los detalles de la transacción parent "

input_trader= $( bitcoin-cli decoderrawtransaction $signed_parent  | jq -r ' .vin[0] | { txid: .txid, vout: .vout } ' )
input_miner= $( bitcoin-cli decoderrawtransaction $signed_parent  | jq -r ' .vin[1] | { txid: .txid, vout: .vout } ' )

output_trader= $( bitcoin-cli decoderrawtransaction $signed_parent  | jq -r ' .vout[0] | { script_pubkey: .scriptPubKey.hex , cantidad: .value } ' )

output_miner= $( bitcoin-cli decoderrawtransaction $signed_parent  | jq -r ' .vout[1] | { script_pubkey: .scriptPubKey.hex , cantidad: .value } ' )

tx_fee= $( bitcoin-cli getmempoolentry $txid_parent  | jq -r ' .fees .base ' )

tx_weight= $( bitcoin-cli getmempoolentry $txid_parent  | jq -r ' .vsize ' )

json= ' { "entrada": [ ' $input_trader ' , ' $input_miner ' ], "salida": [ ' $output_miner ' , ' $output_trader ' ], "Tarifas": ' $tx_fee ' , "Peso": ' $tx_peso ' } '

echo  " Imprima el JSON anterior en la terminal. "
eco  $json  | jq

echo  " Vamos a crear la transaccion child que gaste uno de las salidas de la transaccion parent anterior "
changeaddress_2= $( bitcoin-cli -rpcwallet=Minero getrawchangeaddress )

child= $( bitcoin-cli -named createrawtransaction inputs= ' ' ' [ { "txid": " ' $txid_parent ' ", "vout": ' 1 ' } ] ' ' ' salidas= ' ' ' { " ' $changeaddress_2 ' ": 29.99998 } ' ' ' )

signed_child= $( bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $child  | jq -r ' .hex ' )

txid_child= $( bitcoin-cli sendrawtransaction $signed_child )

decodificador bitcoin-clirawtransaction $signed_parent

echo  " Punto 8. A continuacion los detalles de la transaccion child en la mempool mediante el comando getmempoolentry "
bitcoin-cli getmempoolentry $txid_child

echo  " Punto 9. Vamos a aumentar la tarifa de la transacción padre usando RBF "

parent_rbf= $( bitcoin-cli -named createrawtransaction inputs= ' ' ' [ { "txid": " ' $utxo_txid_1 ' ", "vout": ' $utxo_vout_1 ' , "sequence": 1}, { "txid": " ' $utxo_txid_2 ' ", "vout": ' $utxo_vout_2 ' } ] ' ' ' salidas= ' ' ' { " ' $destinatario ' ": 70.00000, " ' $cambiar dirección ' ": 29.9999 } ' ' ' )

echo  " Punto 10. Firmamos y transmitimos la transacción "

firmado_parent_rbf= $( bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $parent_rbf  | jq -r ' .hex ' )
txid_parent_rbf= $( bitcoin-cli sendrawtransaction $signed_parent_rbf )


echo  " Punto 11. Consultar transacción niño "

bitcoin-cli getmempoolentry $txid_child
echo  " La transaccion child no se encuentra en la mempool "
bitcoin-cli getmempoolentry $txid_parent
echo  " La transacción padre tampoco se encuentra en la mempool "


parada bitcoin-cli stop
eco        Bitcoin Core deteniéndose
fin...
