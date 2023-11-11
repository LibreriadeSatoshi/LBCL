#!/bin/bash

#Ejercicio nro 2, "Curso Bitcoin Linea de Comandos" por Rosa
echo "Ejercicio nro 2 Curso Bitcoin Linea de Comandos"

#Parar bitcoin si se está ejecutando
bitcoin-cli stop
sleep 5

#Borrar el directorio regtest para iniciar desde cero regtest
rm -rf ~/.bitcoin/regtest
#Ejecutar bitcoin
bitcoind -daemon
sleep 5

#Ejercicio punto 1. Crear wallets Trader y Miner
echo "Punto 1. Creando billetera Miner y Trader"
bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true
bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true

#Ejercicio punto 2.  En la billetera Miner vamos a crear una direccion Mineria
DireccionMineria=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Mineria")

#Minamos unos bloques para que Mineria tengan saldo
echo "Punto 2. Creamos direccion Mineria $DireccionMineria."
echo "Minaremos bloques para tener saldo en billetera Miner"
bitcoin-cli generatetoaddress 103 "$DireccionMineria"
echo "Nuestra billetera Miner tiene ahora un saldo de: $(bitcoin-cli -rpcwallet=Miner getbalance) BTC"

#Ejercicio punto 3. Transacion Miner a Trader
#Creamos una direccion en Trader para enviar 70 BTC
echo "Punto 3. Enviamos 70BTC de Miner a Trader"
Recibido=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Trader")
echo "Nueva direccion para Trader: $Recibido"
Cambio=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Miner")
echo "Nueva direccion de Miner para el cambio: $Cambio"

#Transacion en crudo, necesitaremos 2 utxos
utxo0txid=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .vout')
utxo1txid=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[1] | .txid')
utxo1vout=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[1] | .vout')
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout', "sequence":1}, {"txid": "'$utxo1txid'", "vout": '$utxo1vout', "sequence":1}  ]''' outputs='''[{ "'$Recibido'": 70 },{ "'$Cambio'": 29.99999 }]''')
echo "Hemos creado una transaccion en crudo donde enviamos 70BTC a Trader desde Miner"

#Ejercicio punto 4. Firmar y transmitir la Transaccion
echo "Punto 4. Firmamos y transmitimos la Transaccion."
firmadotx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
echo "La transaccion ya está firmada"
parent=$(bitcoin-cli sendrawtransaction $firmadotx)
echo "La transaccion se ha enviado su identificación es $parent"

#Ejercicio punto 5. Detalles de la Transacion
echo "Punto 5. Ahora vamos a organizar los detalles de nuestra transaccion en formato JSON:"
#Primero vemos todos los valores que necesitamos
Tradertxid=$(bitcoin-cli getrawtransaction $parent 1| jq -r '.vin[1].txid')
Tradervout=$(bitcoin-cli getrawtransaction $parent 1| jq -r '.vin[1].vout')
Minertxid=$(bitcoin-cli getrawtransaction $parent 1| jq -r '.vin[0].txid')
Minervout=$(bitcoin-cli getrawtransaction $parent 1| jq -r '.vin[0].vout')
Minerscpk=$(bitcoin-cli getrawtransaction $parent 1 | jq -r '.vout[0].scriptPubKey.hex')
Mineramount=$(bitcoin-cli getrawtransaction $parent 1 | jq -r '.vout[0].value')
Traderscpk=$(bitcoin-cli getrawtransaction $parent 1 | jq -r '.vout[1].scriptPubKey.hex')
Traderamount=$(bitcoin-cli getrawtransaction $parent 1 | jq -r '.vout[1].value')
fees=$(bitcoin-cli getmempoolentry $parent | jq -r '.fees.base')
weight=$(bitcoin-cli getmempoolentry $parent | jq -r '.vsize') #es en vbytes, sino podemos tomar el dato en weight hay que dividirlo por 4 y redondearlo hacia arriba
#Ahora construimos el Json
inner1=$(jq -n  --arg txid "$Tradertxid"\
                --arg vout "$Tradervout"\
                '$ARGS.named'
)
inner2=$(jq -n  --arg txid "$Minertxid"\
                --arg vout "$Minervout"\
                '$ARGS.named'
)
inner3=$(jq -n  --arg script_pubkey "$Minerscpk"\
                --arg amount "$Mineramount"\
                '$ARGS.named'
)
inner4=$(jq -n  --arg script_pubkey "$Traderscpk"\
                --arg amount "$Traderamount"\
                '$ARGS.named'
)
final=$(jq -n   --argjson input "[$inner1, $inner2]"\
                --argjson output "[$inner3, $inner4]"\
                --arg Fees "$fees"\
                --arg Weight "$weight"\
                '$ARGS.named'
)

# Ejercicio punto 6. Mostrar el Json anterior
echo "Punto 6. Mostraremos el JSON contruido"
echo "$final"
echo "El dato Weight: $weight es en vbytes pues lo tomamos de vsize, si tomamos de weight hay que dividir entre 4 y redondear"

# Ejercio punto 7. Crearemos transmision que gaste la transaccion anterior parent y la llamaremos child
echo "Punto 7. Vamos a crear la transaccion child que gaste uno de las salidas de la transaccion parent anterior"

#Datos para construir la transaccion
Cambio2=$(bitcoin-cli -rpcwallet=Miner getrawchangeaddress)
echo "La nueva direcccion de cambio será $Cambio2"
rawtxhexchild=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$parent'", "vout": '1' } ]''' outputs='''{ "'$Cambio2'": 29.99998 }''')
signedtxchild=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhexchild | jq -r '.hex')
child=$(bitcoin-cli sendrawtransaction $signedtxchild)

#Ejercicio punto 8. Mostrar La transaccion child
echo "Punto 8. A continuacion los detalles de la transaccion child en la mempool mediante el comando getmempoolentry"
bitcoin-cli getmempoolentry $child
echo "Vemos en el mempool aparecen las dos transacciones parent y child mediante el comando getrawmempool"
bitcoin-cli getrawmempool

#Ejercicio punto 9. Vamos a aumentar la tarifa de parent usando RBF
echo "Punto 9. Vamos a aumentar la tarifa de la transaccion parent usando RBF"
rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout', "sequence":1}, {"txid": "'$utxo1txid'", "vout": '$utxo1vout', "sequence":1}  ]''' outputs='''[{ "'$Recibido'": 70 },{ "'$Cambio'": 29.9999 }]''')
#echo "El codigo de la transaccion en crudo es $rawtxhex"

#Ejercicio punto 10. Firmar y transmitir la Transaccion
echo "Punto 10. Firmamos y transmitimos la transaccion"
firmadotx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
#echo "Ya está firmada $firmadotx"
rbf=$(bitcoin-cli sendrawtransaction $firmadotx)
echo "La transaccion RBF tiene un txid $rbf"

#Ejercico punto 11. Consultar transaccion child
echo "Despues de transmitir RBF buscamos la transaccion child en la mempool con getmempoolentry:"
bitcoin-cli getmempoolentry $child
echo "La transaccion child ha desaparecido"
echo "Ahora buscamos la transaccion parent en la mempool:"
bitcoin-cli getmempoolentry $parent
echo "La transaccion parent tambien ha desaparecido"

#Ejercicio punto 12. Que cambio en mempoolentry antes y despues de RBF
echo "Punto 12: Que cambio en mempool antes y despues de transmitir RBF: MAGIA"
echo "Despues de transmitir la transaccion RBF la transaccion parent fue reemplazada por la nueva."
echo "La transaccion child que utilizaba uno de los outputs de parent ya no era valida su entrada por lo que salio de la mempool."
echo "Usaremos el comando getrawmempool para ver que solo hay una transaccion que es la RBF que sustituyo a parent:"
bitcoin-cli getrawmempool

echo "Fin. Gracias"
