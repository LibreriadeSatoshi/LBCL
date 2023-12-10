#! /bin/bash
# Transacciones En Bitcoin Core 25.0 -Regtest.
# Por: ToRy "☯The Purpple⚡ 🥷🏻ＮＩＮＪΛ🥷"

echo  " Iniciando Bitcoin... "
bitcoind-demonio

echo***********************************************************************

# Crea tres monederos: Miner, Empleado y Empleador.

bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true | jq
bitcoin-cli -named createwallet wallet_name="Empleado" descriptors=false | jq
bitcoin-cli -named createwallet wallet_name="Empleador" descriptors=false | jq

echo***********************************************************************

#Fondea los monederos generando algunos bloques para Miner y enviando algunas monedas al Empleador.

bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa Minera"`
bitcoin-cli generatetoaddress 103 "Recompensa Minera"
bitcoin-cli -rpcwallet=Miner getbalance
echo "revisar balance inicial"


echo "Creando dirección para recibir el cambio en la cartera 'Miner'"
miner_change_address=$(create_change_address "Miner")
echo "Creada dirección: '$miner_change_address'"

bitcoin-cli -rpcwallet=Empleador getnewaddress "Empleador Fondeo" 
echo generando...$Direccion Recepcion 
TXEmpleado=$bitcoin-cli -rpcwallet=Miner sendtoaddress "Empleador Fondeo" 50
TXID echo -e "ID de la transacción a Empleador: $txEmpleador Fondeo

#Enviamos 50BTC de Miner a Empleador 
utxo0txid=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .vout')
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout'}  ]''' outputs='''[{ "'$Jefe1'": 49.99999 }]''')

#Firmar y transmitir la Transaccion
firmadotx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
minertx=$(bitcoin-cli sendrawtransaction $firmadotx)

bitcoin-cli generatetoaddress 1 "$Recompensa Minera" | jq
echo minando un bloque para confirmar transacciones.

bitcoin-cli -rpcwallet=Empleador getbalance
echo "verificar balance Empleador"


echo***********************************************************************

#Crea una transacción de salario de 40 BTC, donde el Empleador paga al Empleado.

echo Creando direccion de Recepcion 
bitcoin-cli -rpcwallet=Empleado getnewaddress "Paga del Mes"
echo -e "Nueva direccion en la wallet $ Empleado: 

echo Enviando Paga del Mes 40 BTC
bitcoin-cli -rpcwallet=Empleador sendtoaddress "$addrPaga del Mes" 40`


echo  Creando un direccion de cambio
bitcoin-cli -rpcwallet=Empleador getnewaddress "Cambio Empleador")


echo***********************************************************************

#Agrega un timelock absoluto de 500 bloques para la transacción, es decir, la transacción no puede incluirse en el bloque hasta que se haya minado el bloque 500.

getblock=$(bitcoin-cli getblockcount | bc)
timelock500=$(echo "$getblock + 500" | bc)
echo aqui verificamos el Bloque en que nos encontramos

bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txid_empleador'", "vout": '0' } ]''' outputs='''{ "'$address_empleado'": 40, "'$address_cambio_empleador'": 29.999998 }''' locktime=$timelock500)	


echo***********************************************************************

#Informa en un comentario qué sucede cuando intentas transmitir esta transacción.

bitcoin-cli -rpcwallet=Empleador -named signrawtransactionwithwallet hexstring=$tx_timelock | jq -r '.hex')	
bitcoin-cli -named sendrawtransaction hexstring=$sig_timelock500
echo nos tropezamos con un error ya que no nos encontramos en aquel bloque

echo***********************************************************************

#Mina hasta el bloque 500 y transmite la transacción.

echo generando nuevos bloques para liberar el timelock
bitcoin-cli generatetoaddress 500 "Recompensa Minera" 
		
echo confirmamos que se minaran los bloques
bitcoin-cli getblockcount | bc

echo transmitiendo la transaccion
bitcoin-cli -named sendrawtransaction hexstring=$sig_timelock500

echo Minamos 1 bloque para que se confirme
bitcoin-cli generatetoaddress 1 "Recompensa Minera"

echo***********************************************************************

#Imprime los saldos finales del Empleado y Empleador.

bitcoin-cli -rpcwallet=Empledor getbalance
echo "Balance Final en wallet Empleador"

bitcoin-cli -rpcwallet=Empleado getbalance
echo "Balance Final en wallet Empleado

echo***********************************************************************

Gastar desde el Timelock
#Crea una transacción de gasto en la que el Empleado gaste los fondos a una nueva dirección de monedero del Empleado.


echo***********************************************************************

Agrega una salida OP_RETURN en la transacción de gasto con los datos de cadena "He recibido mi salario, ahora soy rico".
		
bitcoin-cli -rpcwallet=Empleado getnewaddress "Me la mekatie en cositas"`
echo "Nueva direccion en la cartera Empleado"

#convertimos el mensaje a HEXADECIMAL y eliminando espacios ya que bitcoin core solo acepta este tipo de codificacion
mensaje=$(echo -n "He recibido mi salario, ahora soy rico"|xxd -p -u)

op_return_datos=$(echo $mensaje| sed 's/ //g')
txsalarioEmpleado=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txidEmpleado'", "vout": '0' } ]''' outputs='''{ "data": 

"'$op_return_datos'", "'$addrs Me la mekatie en cositas'": 39.99999800 }''')		
echo -e "Hex de transaccion saliario de  Empleado: $tx Me la mekatie en cositas
bitcoin-cli decoderawtransaction $txMe la mekatie en cositas|jq 


echo***********************************************************************

#Extrae y transmite la transacción completamente firmada.

bitcoin-cli -rpcwallet=Empleado -named signrawtransactionwithwallet hexstring=$tx Me la mekatie en cositas | jq -r '.hex')
bitcoin-cli -named sendrawtransaction hexstring=$signedtx Me la mekatie en cositas)
echo -e "Id de transaccion salario de Empleado: $txid Me la mekatie en cositas 

		
echo***********************************************************************
#Imprime los saldos finales del Empleado y Empleador.

echo generando un nuevo bloque
bitcoin-cli generatetoaddress 1 "$Recompensa Minera" | jq
		
echo -e "Mensaje en hexadecimal en el $YELL OP_RETURN del script de bloqueo:" 
bitcoin-cli getrawtransaction $txid Me la mekatie en cositas |jq '.vout[0]| .scriptPubKey|.asm'
		
bitcoin-cli -rpcwallet=Empledor getbalance
echo "Balance Final en wallet Empleador"

bitcoin-cli -rpcwallet=Empleado getbalance
echo "Balance Final en wallet Empleado
		
echo***********************************************************************

		
bitcoin-cli stop
echo Bitcoin Core deteniéndose

fin...
