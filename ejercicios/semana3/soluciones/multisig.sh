#!/bin/bash 
#Shell para ejecutar la instalaciìon de Bitcoin Regtest y miner bloques.
#Autor: BlueMoon

#Colores
endColour="\033[0m\e[0m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
redColour="\e[0;31m\033[1m"


#Definir una variables.
version_bitcoin="25.0"

#Ctrl+c
function ctrl_c(){
        echo -e "\n\n${blueColour}Saliendo...${endColour}\n"  
        tput cnorm && exit 1
}

trap ctrl_c INT 
#sleep 10

echo
echo -e "***${yellowColour}BIENVENIDO A LA INSTALACION DE BITCOIN CORE.${endColour}***\n"
echo

#Descar bitcoin y validar firma
descargar_archivos(){ 
	#Colocar archivos descargados a /tmp
	cd /tmp
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Descargando archivos para la instalaciòn y validarlos.${endColour}\n"
	echo "**************************************"

	#Descargar bitcoin
	wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/bitcoin-${version_bitcoin}-x86_64-linux-gnu.tar.gz
	#Descargar el archivo SHA256SUMS
	wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/SHA256SUMS

	echo "**************************************\n"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Verificar el hash del binario de bitcoin.${endColour}\n"

	sha256sum bitcoin-${versionBitcoin}-x86_64-linux-gnu.tar.gz 
	
	#Verificamos que el hash obtenido coincida con el hash del archivo SHA256SUMS 
	verify_sha256sum=$(sha256sum --ignore-missing --check SHA256SUMS 2>&1)
	ok_sha256sum=$(echo ${verify_sha256sum} | grep 'OK' -c)
	#ok_sha256sum=$(echo ${verify_sha256sum} | grep 'La suma coincide' -c)

	if [ ${ok_sha256sum} -lt 1 ]; then
		echo
		echo -e "\n${yellowColour}[==]${endColour}${redColour}Verificación de SHA256SUMS incorrecta.${endColour}${yellowColour}[==]${endColour}\n"
		echo
	else
		echo "\n****************************"
		echo -e "\n${redColour}[==]${endColour}${yellowColour}Coincide con el hash del archivo SHA256SUMS${endColour}${redColour}[==]${endColour}\n"
		echo "****************************"
	fi
	#Descargar las llaves publicas del equipo de Bitcoin Core.
	gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 01EA5486DE18A882D4C2684590C8019E36C2E964 

	#Descargar SHA256SUMS.asc
	wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/SHA256SUMS.asc

	#Verifique que el archivo checksums esté firmado criptográficamente
	verify_asc=$(gpg --verify SHA256SUMS.asc 2>&1)
	ok_asc=$(echo ${verify_asc} | grep 'Good signature' -c)
	#ok_asc=$(echo ${verify_asc} | grep 'Firma correcta' -c)

	if [ ${ok_asc} -lt 1 ]; then
		echo
		echo -e "\n${blueColour}[+]${endColour}${redColour}Verificación de PGP incorrecta.${endColour}\n"
		echo
	else
		echo "****************************"
		echo -e "\n${redColour}[+]${endColour}${yellowColour}Verificación exitosa de la firma binaria.${endColour}\n"
		echo "****************************"
	fi
}
#Extraer los binarios de Bitcoin Core.
extrar_binarios(){
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Extrayendo los binarios de Bitcoin Core.${endColour}\n"

	tar -xvf bitcoin-${version_bitcoin}-x86_64-linux-gnu.tar.gz > /dev/null 

	#Copiar los binarios descargados a la carpeta /usr/local/bin/.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Copiando los binarios descargados a la carpeta${endColour} ${yellowColour}/usr/local/bin/.${endColour}\n"

	sudo mv bitcoin-${version_bitcoin} /usr/local/bin/

	#Crear un archivo bitcoin.conf en el directorio de datos /home/<nombre-de-usuario>/.bitcoin/
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear directorio llamado .bitcoin y archivo bitcoin.conf en el directorio de datos del usuario.${endColour}\n"

	cd $HOME && mkdir .bitcoin
	cd $HOME/.bitcoin/
	echo -e "regtest=1\nfallbackfee=0.0001\nserver=1\ntxindex=1" > bitcoin.conf 

	#Instalar los binarios de en el sistema operativo
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Instalar los binarios de en el Sistema Operativo.${endColour}\n"

	cd /usr/local/bin/
	sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${version_bitcoin}/bin/*
	sleep 3
	
	#Borrar archivos /tmp
	cd /tmp 
	rm -rf bitcoin* SHA256SUMS*
}
#Iniciar bitcoin
iniciar_bitcoin(){
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Verificar version Bitcoin.${endColour}\n"

	#Verificar version
	install_ok=$(sudo bitcoind --version | grep "${version_bitcoin}" -c)

	if [ ${install_ok} -lt 1 ]; then
		echo
		echo -e "\n${yellowColour}[==]${endColour}${redColour}Instalación de binarios de Bitcoin incorrecta.${endColour}${yellowColour}[==]${endColour}\n"
		echo
	else
		echo "****************************"
		echo -e "\n${redColour}[==]${endColour}${yellowColour}Instalación de binarios de Bitcoin correcta ${versionBitcoin}.${endColour}${redColour}[==]${endColour}\n"
		echo "****************************"
	fi

	#Iniciar bitcoin regtest
	echo -e "\n${redColour}[+]${endColour}${blueColour}Iniciar bitcoind regtest.${endColour}\n"

	bitcoind -regtest -daemon
	#bitcoind -regtest -daemon -fallbackfee=1.0 -maxtxfee=1.1
	#bitcoind >/dev/null &
	sleep 10s
}
#Proceso de Minado Semana 1
proceso_minado(){
	#Crear dos billeteras llamadas Miner y Trader.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear dos billeteras llamadas Miner y Trader.${endColour}\n"

	bitcoin-cli -regtest -named createwallet wallet_name="Miner" > /dev/null
	bitcoin-cli -regtest -named createwallet wallet_name="Trader" > /dev/null

	#Generar una dirección desde la billetera Miner con una etiqueta "Recompensa de Minería".
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Generar una dirección desde la billetera Miner con una etiqueta Recompensa de Minería.${endColour}\n"

	#Cargar wallet
	#bitcoin-cli loadwallet Miner 
	#Generar direccion
	address_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa de Minería")
	echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion Miner:${endColour}  ${yellowColour}${address_miner}.${endColour}\n"

	#Extraer nuevos bloques a esta dirección hasta obtener un saldo de billetera positivo. 
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Extraer nuevos bloques a esta dirección hasta obtener un saldo de billetera positivo.${endColour}\n"
	bitcoin-cli generatetoaddress 101 ${address_miner} >/dev/null
	echo -e "\n${redColour}[+]${endColour}${blueColour}Obtener informacion de la Cadena de bloques.${endColour}\n"
	bitcoin-cli getblockchaininfo | jq -C

	#Imprimir el saldo de la billetera Miner.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Saldo de la billetera Miner .${endColour}\n"
	bitcoin-cli -rpcwallet=Miner getbalance 

	sleep 10s

	echo 
	#Crear una dirección receptora con la etiqueta Recibido desde la billetera Trader.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear una dirección receptora con la etiqueta Recibido desde la billetera Trader.${endColour}\n"

	#Cargar wallet de Trader
	#bitcoin-cli loadwallet Trader 
	#Generar direccion
	address_trader=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Recibido")
	echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion del Trader:${endColour} ${yellowColour} ${address_trader}.${endColour}\n"

	#Enviar una transacción que pague 20 BTC desde la billetera Miner a la billetera del Trader.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Enviar una transacción que pague 20 BTC desde la billetera Miner a la billetera del Trader.${endColour}\n"

	#Cargar wallet Miner
	#bitcoin-cli loadwallet Miner 

	#Enviar sats
	txid_trader=$(bitcoin-cli -rpcwallet=Miner sendtoaddress ${address_trader} 20 "Envio a Trader")

	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Transaccion: ${endColour} ${yellowColour}${txid_trader}.${endColour}\n"

	sleep 10s

	#Obtener la transacción no confirmada desde el mempool del nodo y mostrar el resultado.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Obtener la transacción no confirmada desde el mempool del nodo y mostrar el resultado.${endColour}\n"

	bitcoin-cli getmempoolentry ${txid_trader} | jq -C

	#Confirmar la transacción creando 1 bloque adicional.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Confirmar la transacción creando 1 bloque adicional.${endColour}\n"
	bitcoin-cli generatetoaddress 1 ${address_miner} >/dev/null

}
#Crear reporte semana 1
genera_reporte(){
	#Transaccion Trader
	raw_transaction_trader=$(bitcoin-cli getrawtransaction $txid_trader)
	#Transaccion del Miner
	txid_miner=$(bitcoin-cli decoderawtransaction $raw_transaction_trader | jq -r .vin[0].txid)

	#Mostrar datos de la transaccion del Miner
	raw_transaction_miner=$(bitcoin-cli getrawtransaction $txid_miner)
	 
	#Transaccion input, obtener la cantidad de la transaccion del Miner
	value_miner=$(bitcoin-cli decoderawtransaction $raw_transaction_miner | jq -r .vout[0].value)

	#Transaccion output 0 obtener datos del minado
	#address_trader=$(bitcoin-cli decoderawtransaction $raw_transaction_trader | jq -r .vout[0].scriptPubKey.address)
	value_trader=$(bitcoin-cli decoderawtransaction $raw_transaction_trader | jq -r .vout[0].value)

	#Transaccion output 1 obtener datos del cambio
	address_cambio=$(bitcoin-cli decoderawtransaction $raw_transaction_trader | jq -r .vout[1].scriptPubKey.address)
	value_cambio=$(bitcoin-cli decoderawtransaction $raw_transaction_trader | jq -r .vout[1].value)

	#Comisiones: Cantidad pagada en comisiones.
	fee=$(echo $value_miner - $value_cambio - $value_trader | bc)

	#Bloque: Altura del bloque en el que se confirmó la transacción.
	block=$(bitcoin-cli -rpcwallet=Trader gettransaction $txid_trader | jq -Cr '.blockheight')
	#Saldo de Miner: Saldo de la billetera Miner después de la transacción.
	balance_trader=$(bitcoin-cli -rpcwallet=Trader getbalance)
	#Saldo de Trader: Saldo de la billetera Trader después de la transacción.
	balance_miner=$(bitcoin-cli -rpcwallet=Miner getbalance)

	echo
	echo -e "***${redColour}REPORTE.${endColour}***"
	echo

	echo -e "${yellowColour}DIRECCION MINER:${endColour} ${address_miner} ${yellowColour}CANTIDAD:${endColour} ${value_miner}"
	echo -e "${yellowColour}DIRECCION TRADER:${endColour} ${address_trader} ${yellowColour}CANTIDAD:${endColour} ${value_trader}"
	echo -e "${yellowColour}DIRECCION DE CAMBIO:${endColour} ${address_cambio} ${yellowColour}CANTIDAD:${endColour} ${value_cambio}"

	echo -e "\n${blueColour}FEE       BLOQUE	  BALANCE TRADER	  BALANCE MINER${endColour}"
	echo -e "----------  ----------  ----------------  ----------------"
	echo -e "$(printf %9s "$fee") $(printf %19s "$block") $(printf %18s "$balance_trader") $(printf %20s "$balance_miner")"

	echo
	echo -e "***${redColour}GRACIAS${endColour}***"
	echo 
}

#Semana 2
#Crear wallet ´
create_wallet(){
	#Crear dos billeteras llamadas Miner y Trader (descriptors vienen por default en true, no es necesario ponerlos).
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear dos billeteras llamadas Miner y Trader.${endColour}\n"

	bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true > /dev/null
	bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true > /dev/null
	
	#Fondear la billetera Miner con al menos el equivalente a 3 recompensas en bloque en satoshis (Saldo inicial: 150 BTC).
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Fondeaando la billetera de Miner ${endColour}\n"
	
	address_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Saldo Miner")
	echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion Miner:${endColour}  ${yellowColour}${address_miner}.${endColour}\n"
	
	#Extraer nuevos bloques con al menos el equivalente a 3 recompensas en bloque en satoshis (Saldo inicial: 150 BTC).
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Extraer nuevos bloques con al menos el equivalente a 3 recompensas en bloque en satoshis (Saldo inicial: 150 BTC).${endColour}\n"
	bitcoin-cli generatetoaddress 103 ${address_miner} >/dev/null
	
	sleep 10s
	
	#Imprimir el saldo de la billetera Miner.
	echo "**************************************"
	saldo_mnier=$(bitcoin-cli -rpcwallet=Miner getbalance)
	echo -e "\n${redColour}[+]${endColour}${blueColour}Saldo de la billetera Miner:${endColour} ${yellowColour}${saldo_mnier}.${endColour}\n"
	
	#Crear una transacción desde Miner a Trader con la siguiente estructura (llamémosla la transacción parent).
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear una transacción desde Miner a Trader con la siguiente estructura (llamémosla la transacción parent).${endColour}\n"
	
	txid_miner_cero=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r .[0].txid)
	txid_miner_uno=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r .[1].txid)
	vout_miner_cero=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r .[0].vout)
	vout_miner_uno=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r .[1].vout)
	

	echo -e "${yellowColour}Entrada[0]: Recompensa en bloque de 50 BTC:${endColour}"
	echo -e "\n${blueColour}TRANSACCION ID       OUTPUT DE LA TRANSACCION${endColour}"
	echo -e "----------------------------------------- -----------"
	echo -e "$(printf %25s "$txid_miner_cero") $(printf %25s "$vout_miner_cero")"

	echo "**************************************"
	echo -e "${yellowColour}Entrada[1]: Recompensa en bloque de 50 BTC.${endColour}"
	echo -e "\n${blueColour}TRANSACCION ID       OUTPUT DE LA TRANSACCION${endColour}"
	echo -e "----------  ----------  ----------------  ----------------"
	echo -e "$(printf %9s "$txid_miner_uno") $(printf %25s "$vout_miner_uno")"
	
	
	#Salida[0]: 70 BTC para Trader.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Salida[0]: 70 BTC para Trader.${endColour}\n"
	
	#Fondear wallet para Trader.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Fondear wallet para Trader.${endColour}\n"

	#Generar direccion Trader
	address_trader=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Recibido Trader")
	echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion del Trader:${endColour} ${yellowColour} ${address_trader}.${endColour}\n"
	
	#Depositar 70 BTC para Trader, primero generaremos un address para el cambio y activaremos RBF.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Generar address de cambio.${endColour}\n"
	
	address_cambio_miner=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Cambio Miner")
	
	#Salida[0]: 70 BTC para Trader.
    #Salida[1]: 29.99999 BTC de cambio para Miner.
	
	#Variables para los valores monetarios.
	deposito_coins_trader=70.00000000
	cambio_coins_miner=29.99999
	
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Depositar 70 BTC para el Trader activando RBF.${endColour}\n"
	#Activar RBF (Habilitar RBF para la transacción).

	tx_padre=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txid_miner_cero'", "vout":'$vout_miner_cero', "sequence": 1}, {"txid": "'$txid_miner_uno'", "vout":'$vout_miner_uno', "sequence": 1 } ]''' outputs='''[ { "'$address_trader'":'$deposito_coins_trader'}, {"'$address_cambio_miner'":'$cambio_coins_miner' } ]''')
	
	echo $tx_padre
	
	bitcoin-cli decoderawtransaction $tx_padre| jq -r '.vin | .[]'
	
	#Firmar y transmitir la transacción parent, pero no la confirmes aún.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Firmar y transmitir la transacción parent, pero no la confirmes aún.${endColour}\n"
	signed_tx_padre=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $tx_padre | jq -r .hex)
	txid_padre=$(bitcoin-cli sendrawtransaction $signed_tx_padre)
	
	sleep 3
	#Realizar consultas al "mempool" del nodo para obtener los detalles de la transacción parent. Utiliza los detalles para crear una variable JSON con la siguiente estructura.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Realizar consultas al mempool del nodo para obtener los detalles de la transacción parent. Utiliza los detalles para crear una variable JSON con la siguiente estructura.${endColour}\n"
	

	input=$(bitcoin-cli decoderawtransaction $signed_tx_padre | jq -r '.vin[].txid ')
	vout=$(bitcoin-cli decoderawtransaction $signed_tx_padre | jq -r '.vin[].vout')
	script_pubkey=$(bitcoin-cli decoderawtransaction $signed_tx_padre | jq -r '.vout[].scriptPubKey.type')
	amount=$(bitcoin-cli decoderawtransaction $signed_tx_padre | jq -r '.vout[].value')
	fees=$(bitcoin-cli getmempoolentry $txid_padre | jq -r '.fees.base')
	weight=$(bitcoin-cli getmempoolentry $txid_padre | jq -r .weight)
	
	json='{"input": [ {"txid":'$input[0]', "vout": '$vout[0]'}, {"txid":'$input[1]', "vout": '$vout[1]'} ], "output": [ {"script_pubkey": '$script_pubkey[0]', "amount":'$amount[0]'},{"script_pubkey": '$script_pubkey[1]', "amount":'$amount[1]'}, ],"Fees": '$fees',"Weight": '$weight' (weight of the tx in vbytes)}'
	
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Imprime el JSON anterior en la terminal.${endColour}\n"
	
	echo $json | jq
	
	#Crea una nueva transmisión que gaste la transacción anterior (parent). Llamémosla transacción child. 
	
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crea una nueva transmisión que gaste la transacción anterior (parent). Llamémosla transacción child.${endColour}\n"
	echo -e "\n${blueColour}[-]${endColour}${redColour}Entrada[0]: Salida de Miner de la transacción parent.${endColour}\n"
	echo -e "\n${blueColour}[-]${endColour}${redColour}Salida[0]: Nueva dirección de Miner. 29.99998 BTC.${endColour}\n"
	
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Generar una nueva dirección para deposito del hijo.${endColour}\n"
	address_hijo=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Deposito hijo")
	
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Depositar 70 BTC para el Trader activando RBF a esta dirección:${endColour} ${yellowColour}${address_hijo}.${endColour}\n".
	#De la misma manera que la anterior, pero sin sequence activado y enviandose al padre
	
	#variable para valor monetario
	deposito_coins_hijo=29.99998
	tx_hijo=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txid_padre'", "vout": 1} ]''' outputs='''[ { "'$address_hijo'": 29.99998 } ]''')
	
	echo $tx_hijo
		
	#Firmar y transmitir la transacción hijo.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Firmar y transmitir la transacción parent, pero no la confirmes aún.${endColour}\n"
	signed_tx_hijo=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $tx_hijo | jq -r .hex)
	txid_hijo=$(bitcoin-cli sendrawtransaction $signed_tx_hijo)
	
	#Realiza una consulta getmempoolentry para la tranasacción child y muestra la salida.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Realiza una consulta getmempoolentry para la tranasacción child y muestra la salida.${endColour}\n"
	
	getmempoolentry_hijo=$(bitcoin-cli getmempoolentry $txid_hijo | jq)
	echo $getmempoolentry_hijo
	
	#Ahora, aumenta la tarifa de la transacción parent utilizando RBF. No uses bitcoin-cli bumpfee, en su lugar, crea manualmente una transacción conflictiva que tenga las mismas entradas que la transacción parent pero salidas diferentes, ajustando sus valores para aumentar la tarifa de la transacción parent en 10,000 satoshis.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crea manualmente una transacción conflictiva que tenga las mismas entradas que la transacción parent pero salidas diferentes${endColour}\n"
	
	cambio_up=$(echo "${cambio_coins_miner} - 0.00010000" | bc)
	tx_padre_up$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txid_miner_cero'", "vout":'$vout_miner_cero', "sequence": 1}, {"txid": "'$txid_miner_uno'", "vout":'$vout_miner_uno', "sequence": 1 } ]''' outputs='''[ { "'$address_trader'":'$deposito_coins_trader'}, {"'$address_cambio_miner'":'$cambio_up'} ]''')
	
	#Firmar y transmitir la transacción parent, pero no la confirmes aún.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Firmar y transmitir la transacción parent, pero no la confirmes aún.${endColour}\n"
	signed_tx_padre_up=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $tx_padre_up | jq -r .hex)
	txid_padre=$(bitcoin-cli sendrawtransaction $signed_tx_padre_up)
	
	#Realiza otra consulta getmempoolentry para la transacción child y muestra el resultado.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Realiza otra consulta getmempoolentry para la transacción child y muestra el resultado.${endColour}\n"
	
	bitcoin-cli getmempoolentry $txid_hijo | jq
	
	#Imprime una explicación en la terminal de lo que cambió en los dos resultados de getmempoolentry para las transacciones child y por qué.
	
	
	sleep 3
#Semana 3
transaccion_multisig(){
	#Crear tres monederos: Miner, Alice y Bob.
	#Es importante usar billeteras sin descriptores, ya que sino lo hacemos, nos encontraremos con problemas al usar la opción de bitcoin-cli addmultisigaddress. 
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear tres monederos: Miner, Alice y Bob.${endColour}\n"
	
		bitcoin-cli -regtest -named createwallet wallet_name=Alice descriptors=false > /dev/null
		bitcoin-cli -regtest -named createwallet wallet_name=Bob descriptors=false > /dev/null
		bitcoin-cli -regtest -named createwallet wallet_name=Miner descriptors=false > /dev/null
	
	#Fondear los monederos generando algunos bloques para Miner y enviando algunas monedas a Alice y Bob.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Fondear la billetera de Miner ${endColour}\n"
		
		address_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Saldo Miner")
		echo -e "\n${redColour}[+]${endColour}${blueColour}Dirección Miner:${endColour}${yellowColour} ${address_miner}.${endColour}\n"
	
	#Generando algunos bloques para Miner.
		echo "**************************************"
		echo -e "\n${redColour}[+]${endColour}${blueColour}Generando algunos bloques para Miner.${endColour}\n"
		bitcoin-cli generatetoaddress 103 ${address_miner} >/dev/null

	#Imprimir el saldo de la billetera Miner.
		echo "**************************************"
		echo -e "\n${redColour}[+]${endColour}${blueColour}Saldo de la billetera Miner .${endColour}\n"
		bitcoin-cli -rpcwallet=Miner getbalance 

	sleep 10s

	echo 
	#Crear una dirección receptora para Alice.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear una dirección receptora para Alice.${endColour}\n"
		echo 
		echo "*************************************"
		echo "*************ALICIA******************"
		echo "*************************************"
		
		address_alice=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alice Recibido")
		echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion de Alice:${endColour} ${yellowColour} ${address_alice}.${endColour}\n"
	
	#Enviar 30 BTC desde la billetera Miner a la billetera del Alice.
		echo "**************************************"
		echo -e "\n${redColour}[+]${endColour}${blueColour}Enviar 30 BTC desde la billetera Miner a la billetera del Alice.${endColour}\n"

		#Enviar sats
		txid_alice=$(bitcoin-cli -rpcwallet=Miner sendtoaddress ${address_alice} 33 "Envio a Alice")

		echo "**************************************"
		echo -e "\n${redColour}[+]${endColour}${blueColour}Transaccion de Alice: ${endColour} ${yellowColour}${txid_alice}.${endColour}\n"
	
	#Crear una dirección receptora para Bob.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear una dirección receptora para Bob.${endColour}\n"
		echo 
		echo "*************************************"
		echo "*************BOB*********************"
		echo "*************************************"
	
		address_bob=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Bob Recibido")
		echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion de Bob:${endColour} ${yellowColour} ${address_bob}.${endColour}\n"

		#Enviar 30 BTC desde la billetera Miner a la billetera del Bob.
		echo "**************************************"
		echo -e "\n${redColour}[+]${endColour}${blueColour}Enviar 30 BTC desde la billetera Miner a la billetera del Bob.${endColour}\n"

		#Enviar sats
		txid_bob=$(bitcoin-cli -rpcwallet=Miner sendtoaddress ${address_bob} 33 "Envio a Bob")

		echo "**************************************"
		echo -e "\n${redColour}[+]${endColour}${blueColour}Transaccion de Bob: ${endColour} ${yellowColour}${txid_bob}.${endColour}\n"
		
	#Confirmar las transacciones creando 1 bloque adicional.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Confirmar la transacción creando 1 bloque adicional.${endColour}\n"
		bitcoin-cli generatetoaddress 1 ${address_miner} >/dev/null

	#Imprimir balances.
	echo "**************************************"
		echo -e "\n${redColour}[+]${endColour}${blueColour}Saldo en la billetera de Alice.${endColour}\n"
		bitcoin-cli -rpcwallet=Alice getbalance
		echo -e "\n${redColour}[+]${endColour}${blueColour}Saldo en la billetera de Bob.${endColour}\n"
		bitcoin-cli -rpcwallet=Bob getbalance
		
	sleep 3s

	#Crear una dirección Multisig 2-de-2 combinando las claves públicas de Alice y Bob.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear una dirección Multisig 2-de-2 combinando las claves públicas de Alice y Bob.${endColour}\n"
		address_alice_multisig=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alice Multisig")
		echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion de Alice Multisig:${endColour} ${yellowColour} ${address_alice_multisig}.${endColour}\n"
		address_bob_multisig=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Bob Multisig")
		echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion de Bob Multisig:${endColour} ${yellowColour} ${address_bob_multisig}.${endColour}\n"
	
	#Obtener las claves públicas de Alice y Bob.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Claves públicas de Alice y Bob.${endColour}\n"
	echo
	llave_alice=$(bitcoin-cli -rpcwallet=Alice -named getaddressinfo address=$address_alice_multisig | jq -r '.pubkey')
	echo -e "\n${redColour}[+]${endColour}${blueColour}Clave pública de Alice: ${endColour} ${yellowColour}${llave_alice}.${endColour}\n"
	llave_bob=$(bitcoin-cli -rpcwallet=Bob -named getaddressinfo address=$address_bob_multisig | jq -r '.pubkey')
	echo -e "\n${redColour}[+]${endColour}${blueColour}Clave pública de Bob: ${endColour} ${yellowColour}${llave_bob}.${endColour}\n"
	echo
	
	#Creando dirección Multisig 2-de-2.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Creando dirección Multisig 2-de-2.${endColour}\n"
	echo
		dir_multisig=$(bitcoin-cli -named -rpcwallet=Alice addmultisigaddress nrequired=2 keys='''["'$llave_alice'","'$llave_bob'"]''' | jq -r '.address')
		echo -e "\n${redColour}[+]${endColour}${blueColour}Dirección Multisig 2-de-2: ${endColour} ${yellowColour}${dir_multisig}.${endColour}\n"
		echo
	
	#Crear una Transacción Bitcoin Parcialmente Firmada (PSBT) para financiar la dirección multisig con 20 BTC, tomando 10 BTC de Alice y 10 BTC de Bob, y proporcionando el cambio correcto a cada uno de ellos.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear una Transacción Bitcoin Parcialmente Firmada (PSBT) para financiar la dirección multisig con 20 BTC.${endColour}\n"
	#Tomar 10 BTC de Alice y 10 BTC de Bob, y proporcionando el cambio correcto a cada uno de ellos.
	echo -e "${redColour}[+]${endColour}${blueColour}Tomar 10 BTC de Alice y 10 BTC de Bob, y proporcionando el cambio correcto a cada uno de ellos.${endColour}\n"
	echo "**************************************"
	
	#Crear direcciones de cambio
		echo -e "\n${redColour}[+]${endColour}${blueColour}Crear direcciones de cambio.${endColour}\n"
		address_alice_cambio=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Cambio Alice")
		echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion de cambio para Alice:${endColour} ${yellowColour} ${address_alice_cambio}.${endColour}\n"
		addr_bob_cambio=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Cambio Bob")
		echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion de cambio Bob:${endColour} ${yellowColour} ${addr_bob_cambio}.${endColour}\n"
	
		vout_alice_cero=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .vout')
		vout_bob_cero=$(bitcoin-cli -rpcwallet=Bob listunspent | jq -r '.[0] | .vout')
	
	#Crear la Transacción Bitcoin Parcialmente Firmada (PSBT).
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear la Transacción Bitcoin Parcialmente Firmada (PSBT).${endColour}\n"
		tx_psbt=$(bitcoin-cli -named createpsbt inputs='''[ { "txid": "'$txid_alice'", "vout": '$vout_alice_cero' }, { "txid": "'$txid_bob'", "vout": '$vout_bob_cero' } ]''' outputs='''[ { "'$dir_multisig'": 20 }, { "'$address_alice_cambio'": 23 }, { "'$addr_bob_cambio'": 22.9999 } ]''')
	echo			
	#Transacción PSBT 
		echo -e "\n${redColour}[+]${endColour}${blueColour}Transacción PSBT:${endColour} ${yellowColour} ${tx_psbt}.${endColour}\n"
		
	#Firmar transacción de Alice.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Firmar la PSBT por Alice.${endColour}\n"
		psbt_sig_alice=$(bitcoin-cli -rpcwallet=Alice walletprocesspsbt $tx_psbt | jq -r '.psbt')
	
	#Firmar transacción de Bob.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Firmar la PSBT por Bob.${endColour}\n"
		psbt_sig_bob=$(bitcoin-cli -rpcwallet=Bob walletprocesspsbt $tx_psbt | jq -r '.psbt')
		
	sleep 3s
	
	#Combinar las transacciones parcialmente firmadas.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Combinar las transacciones parcialmente firmadas.${endColour}\n"
		psbt_combinada=$(bitcoin-cli combinepsbt '''["'$psbt_sig_alice'", "'$psbt_sig_bob'"]''')
		echo -e "\n${redColour}[+]${endColour}${blueColour}Transacción PSBT combinada:${endColour} ${yellowColour} ${psbt_combinada}.${endColour}\n"
	
	#Enviar transacción
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Enviar transacción.${endColour}\n"
		bitcoin-cli -named analyzepsbt psbt=$psbt_combinada |jq
		hex_psbt=$(bitcoin-cli finalizepsbt $psbt_combinada | jq -r '.hex')
		send_psbt=$(bitcoin-cli -named sendrawtransaction hexstring=$hex_psbt)
		echo -e "\n${redColour}[+]${endColour}${blueColour}ID de la transacción PSBT:${endColour} ${yellowColour} ${send_psbt}.${endColour}\n"
	sleep 3s
	
	#Confirmar el saldo mediante la minería de algunos bloques adicionales.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Confirmar el saldo mediante la minería de algunos bloques adicionales.${endColour}\n"
		bitcoin-cli generatetoaddress 1 "$address_miner"
	
	#Imprimir los saldos finales de Alice y Bob.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Imprimir los saldos finales de Alice y Bob.${endColour}\n"
		echo -e "\n${redColour}[+]${endColour}${blueColour}Saldo en la billetera de Alice.${endColour}\n"
		bitcoin-cli -rpcwallet=Alice getbalance
		echo -e "\n${redColour}[+]${endColour}${blueColour}Saldo en la billetera de Bob.${endColour}\n"
		bitcoin-cli -rpcwallet=Bob getbalance
	sleep 3s
	
	#**************************************
	#********Liquidar Multisig*************
	#**************************************
	
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Liquidar Multisig.${endColour}\n"
	echo "**************************************"
	echo
	#Crear una PSBT para gastar fondos del multisig, asegurando que se distribuyan igualmente 10 BTC entre Alice y Bob después de tener en cuenta las tarifas.
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear una PSBT para gastar fondos del multisig, asegurando que se distribuyan igualmente 10 BTC entre Alice y Bob después de tener en cuenta las tarifas.${endColour}\n"
	
	#Se debe ejecutar por segunda vez el comando addmultisigaddress ya que se almacenarna los datos en la segunda cartera.
	bitcoin-cli -named -rpcwallet=Bob addmultisigaddress nrequired=2 keys='''["'$llave_alice'","'$llave_bob'"]'''|jq -r .address
	#Asi mismo se deben importar las direcciones para encontrar los fondos (el rescan es para que no vuelva a escanear en la cadena de bloques).
	bitcoin-cli -named -rpcwallet=Alice importaddress address="$dir_multisig" rescan=false > /dev/null
	bitcoin-cli -named -rpcwallet=Bob importaddress address="$dir_multisig" rescan=false > /dev/null
	
	#Crear direcciones de cambio para Alice y Bob
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear direcciones de cambio para Alice y Bob.${endColour}\n"
		address_alice_change=`bitcoin-cli -rpcwallet=Alice getnewaddress "Cambio para Alice"`
		echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion de cambio para ALice:${endColour} ${yellowColour} ${address_alice_change}.${endColour}\n"
		address_bob_change=`bitcoin-cli -rpcwallet=Bob getnewaddress "CAmbio para Bob"`
		echo -e "\n${redColour}[+]${endColour}${blueColour}Direccion de cambio para Bob:${endColour} ${yellowColour} ${address_bob_change}.${endColour}\n"
		
	#Definir el cambio de la transacción
		cambio=$(echo 10 - 0.00000200 | bc)
	
	#Crear transacción PSBT.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear transacción PSBT.${endColour}\n"
		tx_psbt_2=$(bitcoin-cli -named createpsbt inputs='''[ { "txid": "'$send_psbt'", "vout": 0 } ]''' outputs='''[ { "'$address_alice_change'": '$cambio' }, { "'$address_bob_change'": '$cambio' } ]''')
		
	#Transacción PSBT.
	#Firmar transacción de Alice.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Firmar la PSBT por Alice.${endColour}\n"
		psbt_sig_alice_2=$(bitcoin-cli -rpcwallet=Alice walletprocesspsbt $tx_psbt_2 | jq -r '.psbt')
	
	#Firmar transacción de Bob.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Firmar la PSBT por Bob.${endColour}\n"
		psbt_sig_bob_2=$(bitcoin-cli -rpcwallet=Bob walletprocesspsbt $tx_psbt_2 | jq -r '.psbt')
		
	#Extraer y transmitir la transacción completamente firmada.
	
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Extraer y transmitir la transacción completamente firmada.${endColour}\n"
	echo
	#Combinar las transacciones parcialmente firmadas.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Combinar las transacciones parcialmente firmadas.${endColour}\n"
		psbt_combinada_2=$(bitcoin-cli combinepsbt '''["'$psbt_sig_alice_2'", "'$psbt_sig_bob_2'"]''')
		echo -e "\n${redColour}[+]${endColour}${blueColour}Transacción PSBT combinada:${endColour} ${yellowColour} ${psbt_combinada_2}.${endColour}\n"
		
	#Enviar transacción.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Enviar transacción.${endColour}\n"
		hex_psbt_2=$(bitcoin-cli finalizepsbt $psbt_combinada_2 | jq -r '.hex')
		tx_psbt_2=$(bitcoin-cli -named sendrawtransaction hexstring=$hex_psbt_2)
		echo -e "\n${redColour}[+]${endColour}${blueColour}ID de la transacción PSBT:${endColour} ${yellowColour} ${tx_psbt_2}.${endColour}\n"
	
	sleep 3s
	
	#Confirmar el saldo mediante la minería de algunos bloques adicionales.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Confirmar el saldo mediante la minería de algunos bloques adicionales.${endColour}\n"
		bitcoin-cli generatetoaddress 1 "$address_miner"
	
	#Imprimir los saldos finales de Alice y Bob.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Imprimir los saldos finales de Alice y Bob.${endColour}\n"
		echo -e "\n${redColour}[+]${endColour}${blueColour}Saldo en la billetera de Alice.${endColour}\n"
		bitcoin-cli -rpcwallet=Alice getbalance
		echo -e "\n${redColour}[+]${endColour}${blueColour}Saldo en la billetera de Bob.${endColour}\n"
		bitcoin-cli -rpcwallet=Bob getbalance
	sleep 3s
	
}

descargar_archivos
extrar_binarios
iniciar_bitcoin
#proceso_minado
#genera_reporte
#create_wallet
transaccion_multisig

