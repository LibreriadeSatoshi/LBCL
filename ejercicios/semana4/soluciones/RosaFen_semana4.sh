#!/bin/bash

#Ejercicio nro 4, "Curso Bitcoin Linea de Comandos" por Rosa
echo "Ejercicio nro 4 Curso Bitcoin Linea de Comandos"

#Parar bitcoin si se está ejecutando
bitcoin-cli stop
sleep 5

#Borrar el directorio regtest para iniciar desde cero regtest
rm -rf ~/.bitcoin/regtest
#Ejecutar bitcoin
bitcoind -daemon
sleep 5

#Ejercicio punto 1. Crear wallets Miner, Empleado y Empleador
echo
echo "Punto 1. Creando carteras Miner Empleado y Empleador"
echo "Nota: para cuestiones internas debido a que empleado y empleador son palabras muy similares, llamare a mis carteras Jefe y Currante"
bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
bitcoin-cli -named createwallet wallet_name="Jefe" descriptors=true
bitcoin-cli -named createwallet wallet_name="Currante" descriptors=true

#Ejercicio punto 2. Minar unos bloques y enviar a Empleador
echo
echo "Punto 1.2. Minar unos bloques y enviar saldo al Empleador"
Mineria=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Mineria")

#Minamos unos bloques para que Mineria tengan saldo
bitcoin-cli generatetoaddress 103 "$Mineria"

#Preparamos datos para enviar a Empleador
Jefe1=$(bitcoin-cli -rpcwallet=Jefe getnewaddress "Jefe1")
echo "Nueva direccion para Empleador: $Jefe1"

#Enviamos 50BTC de Miner a Empleador
utxo0txid=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .vout')
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout'}  ]''' outputs='''[{ "'$Jefe1'": 49.99999 }]''')

#Firmar y transmitir la Transaccion
firmadotx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
minertx=$(bitcoin-cli sendrawtransaction $firmadotx)
echo "La transaccion se ha enviado su identificación es $minertx"
echo "Minamos un bloque para incluirla en la blockchain"
bitcoin-cli generatetoaddress 1 "$Mineria"
echo "El balance ahora de Empleador es $(bitcoin-cli -rpcwallet=Jefe getbalance)"
echo "Como podemos apreciar ya aparece el saldo en la cartera del Empleador"

#Punto 3 y 4. Enviamos 40BTC de Empleador a Empleado con un timelock de 500 bloques
echo
echo "#Punto 1.3 y 1.4. Enviamos 40BTC de Empleador a Empleado con un timelock de 500 bloques"
utxo0txid=$(bitcoin-cli -rpcwallet=Jefe listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=Jefe listunspent | jq -r '.[0] | .vout')
Jefecambio=$(bitcoin-cli -rpcwallet=Jefe getrawchangeaddress)
Currante1=$(bitcoin-cli -rpcwallet=Currante getnewaddress "Currante1")
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout'}  ]''' outputs='''[{ "'$Currante1'": 40 },{"'$Jefecambio'": 9.99998}]''' locktime=500)

#Firmar Transaccion
firmadotx=$(bitcoin-cli -rpcwallet=Jefe signrawtransactionwithwallet $rawtxhex | jq -r '.hex')

echo
echo "Punto 1.5 Informa en un comentario que sucede cuando intentas transmitir la informacion"
jefetx=$(bitcoin-cli sendrawtransaction $firmadotx)
echo "Como podemos ver la transaccion no se ha podido enviar ya que tiene un timelock"
echo "El balance ahora de Empleador es $(bitcoin-cli -rpcwallet=Jefe getbalance)"
echo "El balance ahora de Empleado es $(bitcoin-cli -rpcwallet=Currante getbalance)"

#Minamos hasta el bloque 500
echo
echo "Punto 1.6. Minamos hasta el bloque 500 y transmitimos de nuevo la transaccion"
bitcoin-cli generatetoaddress 400 "$Mineria"

#transmitimos de nuevo la transaccion
jefetx=$(bitcoin-cli sendrawtransaction $firmadotx)
echo "La transaccion se ha enviado su identificación es $jefetx"

#Minamos un bloque mas para incluir la transaccion en el blockchain
echo "Minamos un bloque para que se incluya la transaccion en el blockchain"
bitcoin-cli generatetoaddress 1 "$Mineria"
echo
echo "Punto 1.7. Imprimimos lo saldos del Empleado y el Empleador"
echo "El balance ahora de Empleador es $(bitcoin-cli -rpcwallet=Jefe getbalance)"
echo "El balance ahora de Empleado es $(bitcoin-cli -rpcwallet=Currante getbalance)"

#Punto 2.1. Gastar el Timelock Creamos una transaccion de Empleado a Empleado
echo
echo "Punto 2.1. Gastar el Timelock Creamos una transaccion de Empleado a Empleado"
CurranteCambio=$(bitcoin-cli -rpcwallet=Currante getrawchangeaddress)
echo
frase="He recibido mi salario, ahora soy rico"
echo "Punto 2.2. Agregamos a la salida OP_RETURN la frase: $frase "
op_return_data=$(echo $frase | hexdump --no-squeezing --format '/1 "%02x"')
#op_return_data=486520726563696269646f206d692073616c6172696f2c2061686f726120736f79207269636f
echo "Nuestra frase en hexadecimal es: $op_return_data"

#contruimos la transaccion
utxo0txid=$(bitcoin-cli -rpcwallet=Currante listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=Currante listunspent | jq -r '.[0] | .vout')
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout'}  ]''' outputs='''[{ "'$CurranteCambio'": 39.99999 },{ "data": "'$op_return_data'"}]''')

#Firmar y transmitir la Transaccion
firmadotx=$(bitcoin-cli -rpcwallet=Currante signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
currantetx=$(bitcoin-cli sendrawtransaction $firmadotx)
echo
echo "2.3 Extraemos y transmitimos la transaccion"
echo "Txid de la transaccion $currantetx"
echo "Minamos un bloque para que se incluya la transaccion en el blockchain"
bitcoin-cli generatetoaddress 1 "$Mineria"
echo
echo "Punto 2.4 Veremos los nuevos balances de Empleado y Empleador"
echo "El balance ahora de Empleador es $(bitcoin-cli -rpcwallet=Jefe getbalance)"
echo "El balance ahora de Empleado es $(bitcoin-cli -rpcwallet=Currante getbalance)"

#Vamos a ver el mensaje que hemos transmitdo
echo
echo "Anexo. Para comprobar que tenemos la frase He cobrado mi salario, ahora soy rico en el OP_RETURN de nuestra transaccion. Tomamos el dato gracias al comando getrawtransaction. Con JSON seleccionamos el dato hexadecimal del scriptPubKey de la segunda salida  y luego lo decodificaremos"
echo "Vemos la transaccion en JOSN"
bitcoin-cli -rpcwallet=Currante getrawtransaction $currantetx 1 | jq
dato=$(bitcoin-cli getrawtransaction $currantetx 1 | jq -r '.vout[1].scriptPubKey.asm')
echo "El mensaje en hexadecimal extraido es $dato"
datocorto=${dato:10}
Mensaje=$(echo $datocorto | perl -ne 's/([0-9a-f]{2})/print chr hex $1/gie' && echo '')
echo "El mensaje en lenguaje humano es: $Mensaje"

echo
echo "Fin del ejercicio de hoy. Gracias"

