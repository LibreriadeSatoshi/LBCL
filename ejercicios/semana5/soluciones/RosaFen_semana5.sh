#!/bin/bash

#Ejercicio nro 5, "Curso Bitcoin Linea de Comandos" por Rosa
echo "Ejercicio nro 5 Curso Bitcoin Linea de Comandos. Bloqueo de tiempo relativo"

#Parar bitcoin si se está ejecutando
bitcoin-cli stop
sleep 2

#Borrar el directorio regtest para iniciar desde cero regtest
rm -rf ~/.bitcoin/regtest
#Ejecutar bitcoin
bitcoind -daemon
sleep 2

#Ejercicio punto 1. Crear wallets Alice y Miner
echo
echo "Punto 1. Creando billetera Miner y Alice"
bitcoin-cli -named createwallet wallet_name="Alice" descriptors=true
bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true

#Ejercicio punto 2.  En la billetera Miner vamos a crear una direccion Mineria
echo
echo "Punto 2. Minar para tener saldo en Miner y enviar unas monedas a Alice"
Mineria=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Mineria")

#Minamos unos bloques para que Mineria tengan saldo
echo "Creamos direccion Mineria $Mineria."
echo "Minaremos bloques para tener saldo en billetera Miner"
bitcoin-cli generatetoaddress 101 "$Mineria"
echo "Nuestra billetera Miner tiene ahora un saldo de: $(bitcoin-cli -rpcwallet=Miner getbalance) BTC"


#Creamos una direccion en Alice para enviar 10 BTC
echo "Enviamos 10BTC de Miner a Alice"
Recibido=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alice")
echo "Nueva direccion para Alice: $Recibido"
Cambio=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Miner")
echo "Nueva direccion de Miner para el cambio: $Cambio"

#Transacion en crudo, necesitaremos 1 utxos
utxo0txid=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .vout')
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout'}]''' outputs='''[{ "'$Recibido'": 40 },{ "'$Cambio'": 9.99999 }]''')
echo "Hemos creado una transaccion en crudo donde enviamos 40BTC a Alice desde Miner"

#Firmar y transmitir la Transaccion
echo "Firmamos y transmitimos la Transaccion."
firmadotx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
echo "La transaccion ya está firmada"
txid=$(bitcoin-cli sendrawtransaction $firmadotx)
echo "La transaccion se ha enviado su identificación es $txid"

#Punto 3. Confirmar la transaccion y ver saldo de Alice
echo
echo "Punto 3. Minamos un bloque y miramos saldo de Alice"

bitcoin-cli generatetoaddress 1 "$Mineria"

echo "El balance ahora de Miner es $(bitcoin-cli -rpcwallet=Miner getbalance)"
echo "El balance ahora de Alice es $(bitcoin-cli -rpcwallet=Alice getbalance)"

#Transaccion de Alice a Miner con timelock relativo de 10 bloques

#Punto 4. Creamos transaccion de Alice a Miner con un timelock relativo de 10 bloques
#Transacion en crudo, necesitaremos 1 utxos
echo
echo "Punto 4. Creamos transaccion de Alice a Miner con un timelock relativo de 10 bloques"
utxo0txid=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .vout')
DirMiner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Miner")
Cambio=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alice")
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout', "sequence": '10' }  ]''' outputs='''[{ "'$DirMiner'": 9.99998 } , {"'$Cambio'":30}]''')
echo "Hemos creado una transaccion en crudo donde enviamos 10BTC a Miner desde Alice con una marca de tiempo de 10 bloques"


echo "Firmamos la Transaccion."
firmadotx=$(bitcoin-cli -rpcwallet=Alice signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
echo "La transaccion ya está firmada su id es $firmadotx"
echo
echo "Punto 5. Informar en la termianal que sucede al intentar enviar la transaccion con el timelock relativo"
echo "Enviamos la transaccion"
txid=$(bitcoin-cli sendrawtransaction $firmadotx)
echo "La transaccion no se ha podido enviar"

echo
echo "Segunda parte punto 1. Minamos 10 bloques adicionales"

bitcoin-cli generatetoaddress 10 "$Mineria"

echo
echo "Segunda parte punto 2. Difundimos de nuevo la transaccion y generamos un bloque mas"
txid=$(bitcoin-cli sendrawtransaction $firmadotx)
echo "Ahora si hemos podido enviar la transaccion, su identificacion es $txid"

echo "Minamos un bloque"
bitcoin-cli generatetoaddress 1 "$Mineria"

echo
echo "Segunda parte punto 3. Informar del saldo de Alice"
echo "El balance ahora de Alice es $(bitcoin-cli -rpcwallet=Alice getbalance)"

echo
echo "Anexo. Vamos a probar enviar una transaccion con dos entradas en una con un bloqueo relativo de 5 bloques y la otra con un bloqueo relativo de 2 bloques, ¿que pasara?"
echo "Enviaremos desde Miner una cantidad a Alice del primer UTXO con un bloqueo de 2 y del segundo UTXO con un bloqueo de 5"

#Datos para nuestra transaccion
utxo0txid=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .vout')
Monto0=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .amount')
utxo1txid=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[1] | .txid')
utxo1vout=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[1] | .vout')
Monto1=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[1] | .amount')
echo "Los dos primeros UTXOS de Miner tienen un monto de $Monto0 BTC y $Monto1 BTC, Alice tiene un balance de $(bitcoin-cli -rpcwallet=Alice getbalance)"
MontoEnvio=$(echo "($Monto0 + $Monto1 - 0.001)" | bc)
Cambio=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Miner")
Alice=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alice")

#Transaccion
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout', "sequence": '2' } , { "txid": "'$utxo1txid'", "vout": '$utxo1vout', "sequence": '5' }  ]''' outputs='''[{ "'$Alice'": '$MontoEnvio'}]''')

#Firmamos la transaccion
firmadotx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
echo "Antes de transmitir la transaccion vamos a ver los detalles:"
bitcoin-cli decoderawtransaction $firmadotx
echo "Enviamos la transaccion"
txid=$(bitcoin-cli sendrawtransaction $firmadotx)

echo "Si no ve un mensaje de error es que se ha enviado la transaccion $txid"
echo "Balance de Alice $(bitcoin-cli -rpcwallet=Alice getbalance)"
echo "Minamos 2 bloques"
bitcoin-cli generatetoaddress 2 "$Mineria"

echo "Transmitimos de nuevo"
txid=$(bitcoin-cli sendrawtransaction $firmadotx)

echo "Si no ve un mensaje de error es que se ha enviado la transaccion o se transmitio en el comando anterior $txid"

echo "Balance de Alice $(bitcoin-cli -rpcwallet=Alice getbalance)"

echo "Minamos 3 bloques mas"

bitcoin-cli generatetoaddress 3 "$Mineria"

echo "Balance de Alice $(bitcoin-cli -rpcwallet=Alice getbalance)"
echo "Al tratar de hacer un bloqueo diferente en cada entrada el programa tiene un comportamiento incongruente, el uso de sequence como bloqueo relativo se implemento para la transaccion.  Conclusion: no se debe poner diferentes sequence cuando estamos haciendo un bloqueo relativo de tiempo"

echo "Fin. Gracias"
