#! /bin/bash
# Transacciones En Bitcoin Core 25.0 -Regtest.
# Por: ToRy "☯The Purpple⚡ 🥷🏻ＮＩＮＪΛ🥷"

echo  " Iniciando Bitcoin... "
bitcoind-demonio

echo***********************************************************************

# Crear tres monederos: Miner, Alice y Bob:

bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true | jq
bitcoin-cli -named createwallet wallet_name="Alice" descriptors=false | jq
bitcoin-cli -named createwallet wallet_name="Bob" descriptors=false | jq

echo***********************************************************************

#Fondear los monederos generando algunos bloques para Miner y enviando algunas monedas a Alice y Bob:

bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa Minera"`
bitcoin-cli generatetoaddress 103 "Recompensa Minera"
bitcoin-cli -rpcwallet=Miner getbalance
echo "revisar balance inicial"

bitcoin-cli -rpcwallet=Alice getnewaddress "Alice Fondeo" 
echo generando...$Direccion Recepcion 
TXAlice=$bitcoin-cli -rpcwallet=Miner sendtoaddress "$Alice Fondeo" 50
TXID echo -e "ID de la transacción a Alice: $txAlice Fondeo

bitcoin-cli -rpcwallet=Bob getnewaddress  "Bob Fondeo" 
echo generando...$Direccion Recepcion 
TXBob=$bitcoin-cli -rpcwallet=Miner sendtoaddress "$Bob Fondeo" 50
TXID echo -e "ID de la transacción a Bob: $txBob Fondeo

bitcoin-cli generatetoaddress 1 "$Recompensa Minera" | jq
echo minando un bloque para confirmar transacciones.

bitcoin-cli -rpcwallet=Alice getbalance
echo "verificar balance Alice"

bitcoin-cli -rpcwallet=Alice getbalance
echo "verificar balance Alice"

echo***********************************************************************

#Crear una dirección Multisig 2-de-2 combinando las claves públicas de Alice y Bob:

echo Creando Multisig...
bitcoin-cli -rpcwallet=Alice getnewaddress "Alice Multisig"
echo -e "Nueva direccion en la wallet $ Alice: 

bitcoin-cli -rpcwallet=Bob getnewaddress "Bob Multisig"
echo -e "Nueva direccion en la wallet $ Bob: 

echo Verificando LLaves Publicas...
bitcoin-cli -rpcwallet=Alice -named getaddressinfo address=$Alice Multisig | jq -r '.pubkey')
echo "Comprobando Llave Publica Alice $pubkey Alice"
bitcoin-cli -rpcwallet=Bob -named getaddressinfo address=$Bob Multisig | jq -r '.pubkey')
echo "Comprobando Llave Publica Bob $pubkey Bob"

echo creando Direccion Multifirma...
bitcoin-cli -named -rpcwallet=Alice addmultisigaddress nrequired=2 keys='''["'$pubkey Alice'","'$pubkey Bob'"]'''|jq -r .address`
echo -e "Detalles de dirección multifirma $YELL $addrMultifirma $NC"

echo***********************************************************************

#Crear una Transacción Bitcoin Parcialmente Firmada (PSBT) para financiar la dirección multisig con 20 BTC, tomando 10 BTC de Alice y 10 BTC de Bob, y proporcionando el cambio correcto a cada uno de ellos.

bitcoin-cli -rpcwallet=Alice getnewaddress "Cambio Alice"`
echo "Direccion de cambio wallet $Alice: $addrCambioAlice 
bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .vout'

bitcoin-cli -rpcwallet=Bob getnewaddress "Cambio Bob"`
echo "Direccion de cambio wallet $Bob: $addrCambioBob
bitcoin-cli -rpcwallet=Bob listunspent | jq -r '.[0] | .vout'


echo Creando PSBT...
bitcoin-cli -named createpsbt inputs='''[ { "txid": "'$txAlice'", "vout": '$vouttxAlice' }, { "txid": "'$txBob'", "vout": '$vouttxBob' } ]''' outputs='''[ { "'$addrMulti'": 20 }, { "'$addrCambioAlice'": 40 }, { "'$addrCambioBob'": 39.9999 } ]''')
echo "PSBT sin firmas: $YELL $psbtraw"
bitcoin-cli analyzepsbt $psbtraw | jq

echo PSBT Firmada Alice...
bitcoin-cli -rpcwallet=Alice walletprocesspsbt $psbtraw | jq -r '.psbt')
echo "PSBT de Alice $psbtfirmadaAlice "
bitcoin-cli -named analyzepsbt psbt=$psbtfirmadaAlice | jq

echo PSBT Firmada Bob...
bitcoin-cli -rpcwallet=Bob walletprocesspsbt $psbtraw | jq -r '.psbt')
echo -e "PSBT de Bob $psbtfirmadaBob "
bitcoin-cli -named analyzepsbt psbt=$psbtfirmadaBob | jq

echo PSBT Transaccion Combinada...
bitcoin-cli combinepsbt '''["'$psbtfirmadaAlice'", "'$psbtfirmadaBob'"]''')
echo "Transacción PSBT combinada: $psbtcombinada

echo PSBT Transaccion decodificada...
bitcoin-cli -named analyzepsbt psbt=$psbtcombinada |jq
		
bitcoin-cli finalizepsbt $psbtcombinada | jq -r '.hex')
bitcoin-cli -named sendrawtransaction hexstring=$psbthex)
echo "TXID PSBT enviada:$txpsbt 

echo***********************************************************************

#Confirmar el saldo mediante la minería de algunos bloques adicionales.

bitcoin-cli generatetoaddress 1 "$Recompensa Minera"
bitcoin-cli -rpcwallet=Miner getbalance
echo "revisar balance"

echo***********************************************************************

#Imprimir los saldos finales de Alice y Bob.

bitcoin-cli -rpcwallet=Alice getbalance
echo "Balance Final en wallet Alice $saldoAlice

bitcoin-cli -rpcwallet=Bob getbalance
echo "Balance Final en wallet Bob $saldoBob

bitcoin-cli getrawtransaction $txpsbt 1|jq '.vout[0] |.value')
echo -e "Balance Final Multifirma $saldomulti \n"

echo***********************************************************************

#Liquidar Multisig
Crear una PSBT para gastar fondos del multisig, asegurando que se distribuyan igualmente 10 BTC entre Alice y Bob después de tener en cuenta las tarifas


echo Avisando a las wallets que la multifirma fue creada con ella.
echo "Importando y creando la Direccion Multi firma en ambas carteras de otra forma el comando walletprocesspsbt NO PODRA FIRMAR LA TRANSACCIÓN "	

bitcoin-cli -named -rpcwallet=Bob addmultisigaddress nrequired=2 keys='''["'$pubkeyAlice'","'$pubkeyBob'"]'''|jq -r .address
bitcoin-cli -named -rpcwallet=Alice importaddress address="$addrMulti" rescan=false
bitcoin-cli -named -rpcwallet=Bob importaddress address="$addrMulti" rescan=false

# Variables para crear la TX 	

txidMulti=$txpsbt
vouttxMulti=0

bitcoin-cli -rpcwallet=Alice getnewaddress "Cambio Alice"`
echo "Direccion de vuelta a la cartera Alice: $addrCambioAlice 

bitcoin-cli -rpcwallet=Bob getnewaddress "Cambio Bob"`
echo "Direccion de vuelta a la cartera Bob: $addrCambioBob 

# calculando tarifa, que ambos paguen 350
Cambio=$(echo 10 - 0.00000350|bc)
echo Alice y Bob van a pagar 350 sats de fee de mineria y recibiran $cambio sats de vuelta"

# creando la PSBT:
bitcoin-cli -named createpsbt inputs='''[ { "txid": "'$txidMulti'", "vout": '$vouttxMulti' } ]''' outputs='''[ { "'$addrCambioAlice'": '$Cambio' }, { "'$addrCambioBob'": '$Cambio' } ]''')

bitcoin-cli -named analyzepsbt psbt=$vpsbtraw |jq
echo "Transaccion sin firmar: $vpsbtraw 

echo***********************************************************************
		
Firma PSBT por Alice."
bitcoin-cli -rpcwallet=Alice walletprocesspsbt $vpsbtraw | jq -r '.psbt')

bitcoin-cli -named analyzepsbt psbt=$vpsbtfirmadaAlice |jq
echo  "PSBT de Alice $vpsbtfirmadaAlice 
		
echo***********************************************************************

Firma PSBT por Bob."
bitcoin-cli -rpcwallet=Bob walletprocesspsbt $vpsbtraw | jq -r '.psbt')

bitcoin-cli -named analyzepsbt psbt=$vpsbtfirmadaBob |jq
echo "PSBT de Bob $vpsbtfirmadaBob 
		
echo***********************************************************************

Extraer y transmitir la transacción completamente firmada."

bitcoin-cli combinepsbt '''["'$vpsbtfirmadaAlice'", "'$vpsbtfirmadaBob'"]''')
echo Alice y Bob firmaron por separado su transaccion y luego la envian a quien la combina y finaliza 

echo "Transacción PSBT combinada:$vpsbtcombinada 
echo "Transacción PSBT decodificada:"

bitcoin-cli -named analyzepsbt psbt=$vpsbtcombinada |jq
bitcoin-cli finalizepsbt $vpsbtcombinada | jq -r '.hex')
bitcoin-cli -named sendrawtransaction hexstring=$vpsbthex)
echo -e "ID de Transacción PSBT enviada al mempool: $txvpsbt 
		
echo***********************************************************************

#Imprimir los saldos finales de Alice y Bob.
	
echo Confirmando transaccion en nuevo bloque porque sino el saldo no cambia 
bitcoin-cli generatetoaddress 1 "$Recompensa Minera"
		
		
bitcoin-cli -rpcwallet=Alice getbalance
echo "Balance Final en wallet Alice $saldoAlice 
		
bitcoin-cli -rpcwallet=Bob getbalance
echo "Balance Final en wallet Bob $saldoBob 

		
bitcoin-cli stop
echo Bitcoin Core deteniéndose

fin...
