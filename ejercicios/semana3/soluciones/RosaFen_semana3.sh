#!/bin/bash

#Ejercicio nro 3, "Curso Bitcoin Linea de Comandos" por Rosa
echo "Ejercicio nro 3 Curso Bitcoin Linea de Comandos"

#Parar bitcoin si se está ejecutando
bitcoin-cli stop
sleep 5

#Borrar el directorio regtest para iniciar desde cero regtest
rm -rf ~/.bitcoin/regtest
#Ejecutar bitcoin
bitcoind -daemon
sleep 5

#Ejercicio punto 1.1. Crear wallets Miner, Alice y Bob
echo
echo "Punto 1.1. Creando carteras Miner, Alice y Bob"
bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
bitcoin-cli -named createwallet wallet_name="Alice" descriptors=false
bitcoin-cli -named createwallet wallet_name="Bob" descriptors=false

#Ejercicio punto 1.2. Minamos unos bloques y enviamos a Alice y Bob para que tengan saldo sus direcciones
DireccionMineria=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Mineria")

#Minamos unos bloques para que Mineria tengan saldo
echo
echo "Punto 1.2. Para tener saldo en las 3 carteras, minamos en Miner y enviamos a Alice y Bob"
echo "Minaremos bloques direccion Mineria $DireccionMineria."
bitcoin-cli generatetoaddress 101 "$DireccionMineria"
echo "Nuestra cartera Miner tiene ahora un saldo de: $(bitcoin-cli -rpcwallet=Miner getbalance) BTC"

DireccionAlice1=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alice1" "legacy")
DireccionBob1=$(bitcoin-cli -rpcwallet=Bob getnewaddress  "Bob1" "legacy")
echo "Nueva direccion para Alice: $DireccionAlice1"
echo "Nueva direccion para Bob: $DireccionBob1"

echo "Enviamos 40BTC de Miner a Alice y a Bob"

#Transaccion en crudo
utxo0txid=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .vout')
Cambio=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Miner")
echo "Nueva direccion de Miner para el cambio: $Cambio"

rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout'}]''' outputs='''[{ "'$DireccionAlice1'": 20 },{ "'$DireccionBob1'": 20 },{ "'$Cambio'": 9.99998 }]''')
echo "Hemos creado una transaccion en crudo donde enviamos 20BTC a Alice y 20BTC a Bob desde Miner"

echo "Firmamos y transmitimos la Transaccion."
firmadotx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
echo "La transaccion ya está firmada"
identtx=$(bitcoin-cli sendrawtransaction $firmadotx)
echo "La transaccion se ha enviado su identificación es $identtx"
echo "Minamos un bloque para que aparezca el balance de las carteras" #¿sera suficiente con 1 blque?
bitcoin-cli generatetoaddress 1 "$DireccionMineria"
echo "Usamos el comando getbalance para saber los saldos de Miner, Alice y Bob"
echo "Nuestra cartera Miner tiene ahora un saldo de: $(bitcoin-cli -rpcwallet=Miner getbalance) BTC"
echo "Nuestra cartera Alice tiene ahora un saldo de: $(bitcoin-cli -rpcwallet=Alice getbalance) BTC"
echo "Nuestra cartera Miner tiene ahora un saldo de: $(bitcoin-cli -rpcwallet=Bob getbalance) BTC"

#Punto 1.3. Creamos una direcion Miltisig 2 de 2 con los claves pubilcas de Alice y Bob
echo
echo "Punto 1.3. Creamos una direcion Miltisig 2 de 2 con los claves pubilcas de Alice y Bob"
Alicemulti=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alicemulti" "legacy")
echo "Direccion de Alice $Alicemulti"
Bobmulti=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Bobmulti" "legacy")
echo "Direccion de Bob $Bobmulti"
pubkeyalice=$(bitcoin-cli -named -rpcwallet=Alice getaddressinfo address=$Alicemulti | jq -r .pubkey)
echo "Necesitaresmos el pubkey de Alice $pubkeyalice"
pubkeybob=$(bitcoin-cli -named -rpcwallet=Bob getaddressinfo address=$Bobmulti | jq -r .pubkey)
echo "Y tambien el pubkey de Bob $pubkeybob"
direccionmultifirma=$(bitcoin-cli -named createmultisig nrequired=2 keys='''["'$pubkeyalice'","'$pubkeybob'"]''' | jq -r '.address')
redeemScript=$(bitcoin-cli -named createmultisig nrequired=2 keys='''["'$pubkeyalice'","'$pubkeybob'"]''' | jq -r '.redeemScript')
descriptormulti=$(bitcoin-cli -named createmultisig nrequired=2 keys='''["'$pubkeyalice'","'$pubkeybob'"]''' | jq -r '.descriptor')
echo "Guardamos los datos de la multifirma Alice y Bob direccion $direccionmultifirma"
echo "Tambien necesitaremos el dato redeemScript: $redeemScript"
echo "y el Descriptor: $descriptormulti"

#Punto 1.4. Crear transaccion parcialmente firmada PSBT para financiar esta direccion multisig con 10BTC de Alice y 10BTC de Bob
echo
echo "Punto 1.4. Crear transaccion parcialmente firmada PSBT para financiar esta direccion multisig con 10BTC de Alice y 10BTC de Bob"
#Buscamos los datos necesarios en carteras de Alice y Bob
utxo0txidA=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .txid')
utxo0voutA=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .vout')
CambioA=$(bitcoin-cli -rpcwallet=Alice getrawchangeaddress "legacy")
echo "Direccion cambio Alice $CambioA"
utxo0txidB=$(bitcoin-cli -rpcwallet=Bob listunspent | jq -r '.[0] | .txid')
utxo0voutB=$(bitcoin-cli -rpcwallet=Bob listunspent | jq -r '.[0] | .vout')
CambioB=$(bitcoin-cli -rpcwallet=Bob getrawchangeaddress "legacy")
echo "Direccion cambio Bob $CambioB"
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txidA'", "vout": '$utxo0voutA' }, { "txid": "'$utxo0txidB'", "vout": '$utxo0voutB' } ]''' outputs='''[{ "'$direccionmultifirma'": 20 },{ "'$CambioA'": 9.99999 },{ "'$CambioB'": 9.99999 }]''')
echo "rawtxhex $rawtxhex"
psbt=$(bitcoin-cli converttopsbt $rawtxhex)

echo "Ahora va a firmar Alice y Bob"
psbt_a=$(bitcoin-cli -rpcwallet=Alice walletprocesspsbt $psbt | jq -r '.psbt')
psbt_f=$(bitcoin-cli -rpcwallet=Bob walletprocesspsbt $psbt_a | jq -r '.psbt')
echo "Ahora finalizamos la PSBT"
psbt_hex=$(bitcoin-cli finalizepsbt $psbt_f | jq -r '.hex')
echo "Ahora enviamos la PSBT"
bitcoin-cli sendrawtransaction $psbt_hex

#1.5. Confirmar el saldo mediante mineria de algunos bloques
echo
echo "Punto 1.5. Minaremos unos bloques y veremos el saldo de nuestras carteras"
bitcoin-cli generatetoaddress 1 "$DireccionMineria"

#1.6. Vemos los saldos finales de Bob y Alice
echo
echo "Punto 1.6. Mostramos a continuacion los saldos de Bob y Alice"
echo "Nuestra cartera Alice tiene ahora un saldo de: $(bitcoin-cli -rpcwallet=Alice getbalance) BTC"
echo "Nuestra cartera Bob tiene ahora un saldo de: $(bitcoin-cli -rpcwallet=Bob getbalance) BTC"

#2.1. Crear una PSBT para gastar los fondos del multisig igualmente 10 entre Alice y Bob
echo
echo
echo "Punto 2.1 Crear una PSBT para gastar 10BTC del multisig igualmente entre Alice y Bob"

bitcoin-cli -named createwallet wallet_name="multi" disable_private_keys="true" descriptors=false
bitcoin-cli -rpcwallet=multi importaddress $direccionmultifirma false
echo "Balance en nuestra direccion multifirma de Alice y Bob antes de la transaccion $(bitcoin-cli -rpcwallet=multi getbalance)"
utxo0txid=$(bitcoin-cli -rpcwallet=multi listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=multi listunspent | jq -r '.[0] | .vout')
utxo_spk=$(bitcoin-cli  getrawtransaction $utxo0txid 1 | jq -r '.vout[0].scriptPubKey.hex')
echo "Recogemos los datos para la transaccion de la direccion multifirma:"
echo "El utxo $utxo0txid"
echo "El utxo vout $utxo0vout"
echo "Y el utxo_spk $utxo_spk"
#Creamos nuevas direcciones de Alice y Bob para el cambio
DireccionAlice1=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alice1" "legacy")
DireccionBob1=$(bitcoin-cli -rpcwallet=Bob getnewaddress  "Bob1" "legacy")
echo "Nueva direccion para el cambio Alice: $DireccionAlice1"
echo "Nueva direccion para el cambio Bob: $DireccionBob1"
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout' } ]''' outputs='''[{ "'$DireccionAlice1'": 9.99999 },{ "'$DireccionBob1'": 9.99999 }]''')
echo "Con estos datos usamos createrawtransaction, obtenemos el dato hex: $rawtxhex"

#Punto 2.2. Alice firma la transaccion
echo
echo "Punto 2.2. Alice firma la transaccion "
echo "Obtenemos las privekey de Alice y Bob con dumpprivkey"
privkeyalice=$(bitcoin-cli -rpcwallet=Alice -named dumpprivkey address=$Alicemulti)
echo "Privkey de Alice $privkeyalice"
privkeybob=$(bitcoin-cli -rpcwallet=Bob -named dumpprivkey address=$Bobmulti)
echo "Privkey de Bob $privkeybob"
txfda=$(bitcoin-cli -named signrawtransactionwithkey hexstring=$rawtxhex prevtxs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout', "scriptPubKey": "'$utxo_spk'", "redeemScript": "'$redeemScript'" } ]''' privkeys='["'$privkeyalice'"]' | jq -r '.hex')
echo "Ha firmado Alice hex de salida: $txfda"

#PUnto 2.3. Bob firma la transaccion
echo
echo "Punto 2.3. Bob firma la transaccion"
txfdb=$(bitcoin-cli -named signrawtransactionwithkey hexstring=$txfda prevtxs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout', "scriptPubKey": "'$utxo_spk'", "redeemScript": "'$redeemScript'" } ]''' privkeys='["'$privkeybob'"]' | jq -r '.hex')
echo "Ha firmado Bob hex de salida: $txfdb"

#Punto 2.4. Extraemos y transmitimos la transaccion
echo
echo "Punto 2.4. Extraemos y transmitimos la transaccion"
echo "Enviamos transaccion con sendrawtransaction"
finaltx=$(bitcoin-cli -named sendrawtransaction hexstring=$txfdb)
echo "Obtenemos el txid $finaltx"
echo "Minamos un bloque"
bitcoin-cli generatetoaddress 1 "$DireccionMineria"

#Punto 2.5. Balance final de Alice y Bob
echo
echo "Punto 2.5. Se muestra el balance final de nuestras carteras: Alice, Bob y el de la direccion multifirma"
echo "Balance en la cartera de Alice $(bitcoin-cli -rpcwallet=Alice getbalance)"
echo "Balance en la cartera de Bob $(bitcoin-cli -rpcwallet=Bob getbalance)"
echo "Balance en nuestra direccion multifirma de Alice y Bob $(bitcoin-cli -rpcwallet=multi getbalance)"
