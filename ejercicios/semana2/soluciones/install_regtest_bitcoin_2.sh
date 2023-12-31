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
	vout_miner_cero=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r .[0].vout)
	
	txid_miner_uno=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r .[1].txid)
	vout_miner_uno=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r .[1].vout)
	

	#Entradas
	echo "*************ENTRADAS*****************"
	echo "*************************************"
	echo -e "${blueColour}Entrada[0]:${endColour}${yellowColour} Recompensa en bloque de 50 BTC:${endColour}"
	echo -e "${blueColour}TRANSACCION ID[0]:${endColour} ${yellowColour}$txid_miner_cero${endColour}"
	echo
	echo -e "${blueColour}Entrada[1]:${endColour}${yellowColour} Recompensa en bloque de 50 BTC:${endColour}"
	echo -e "${blueColour}TRANSACCION ID[1]:${endColour} ${yellowColour}$txid_miner_uno${endColour}"
	echo
	#Salidas
	echo "*************SALIDAS*****************"
	echo "*************************************"
	#Generar direccion Trader
	address_trader=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Recibido Trader")
	
	echo -e "${blueColour}Salida[0]:${endColour}${yellowColour}70 BTC para Trader.${endColour}"
	echo -e "${blueColour}Direccion del Trader:${endColour} ${yellowColour} ${address_trader}.${endColour}\n"

	#Generar direccion Cambio
	address_cambio_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Cambio Miner")
	
	echo -e "${blueColour}Salida[1]:${endColour}${yellowColour} 29.99999 BTC de cambio para Miner.${endColour}"
	echo -e "${blueColour}Direccion de cambio:${endColour} ${yellowColour} ${address_cambio_miner}.${endColour}\n"
	
	echo
	
	#Variables para los valores monetarios.
	deposito_coins_trader=70.00000000
	cambio_coins_miner=29.99999
	
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Depositar 70 BTC para el Trader activando RBF.${endColour}\n"
	#Activar RBF (Habilitar RBF para la transacción).

	tx_padre=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txid_miner_cero'", "vout":'$vout_miner_cero', "sequence": 1}, {"txid": "'$txid_miner_uno'", "vout":'$vout_miner_uno', "sequence": 1 } ]''' outputs='''[ { "'$address_trader'":'$deposito_coins_trader'}, {"'$address_cambio_miner'":'$cambio_coins_miner' } ]''')
	
	
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
	
	json='{"input": [{"txid":"'$(echo $input | awk '{print $1}')'","vout":"'$(echo $vout | awk '{print $1}')'"},{"txid":"'$(echo $input | awk '{print $2}')'","vout":"'$(echo $vout | awk '{print $2}')'"}], "output": [{"script_pubkey":"'$(echo $script_pubkey | awk '{print $1}')'","amount":"'$(echo $amount | awk '{print $1}')'"},{"script_pubkey":"'$(echo $script_pubkey | awk '{print $2}')'","amount":"'$(echo $amount | awk '{print $2}')'"}],"Fees": '$fees',"Weight": '$weight'}' 
	
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
	echo -e "\n${redColour}[+]${endColour}${blueColour}Dirección hijo:${endColour} ${yellowColour}${address_hijo}.${endColour}\n".
	echo
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crear transacciòn de Parent a hijo:${endColour} ${yellowColour}${address_hijo}.${endColour}\n".
	
	#variable para valor monetario
	deposito_coins_hijo=29.99998
	tx_hijo=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txid_padre'", "vout": 1} ]''' outputs='''[ { "'$address_hijo'": 29.99998 } ]''')
		
	#Firmar y transmitir la transacción hijo.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Firmar y transmitir la transacción hijo.${endColour}\n"
	signed_tx_hijo=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $tx_hijo | jq -r .hex)
	txid_hijo=$(bitcoin-cli sendrawtransaction $signed_tx_hijo)
	
	#Realiza una consulta getmempoolentry para la tranasacción child y muestra la salida.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Realiza una consulta getmempoolentry para la tranasacción child y muestra la salida.${endColour}\n"
	
	bitcoin-cli getrawmempool | jq
	bitcoin-cli getmempoolentry $txid_hijo | jq
	
	#Ahora, aumenta la tarifa de la transacción parent utilizando RBF. No uses bitcoin-cli bumpfee, en su lugar, crea manualmente una transacción conflictiva que tenga las mismas entradas que la transacción parent pero salidas diferentes, ajustando sus valores para aumentar la tarifa de la transacción parent en 10,000 satoshis.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Crea manualmente una transacción conflictiva que tenga las mismas entradas que la transacción parent pero salidas diferente, amentando la tarifa de la transacción parent en 10,0000.${endColour}\n"
	
	cambio_up=$(echo "${cambio_coins_miner} - 0.00010000" | bc)
	tx_padre_up=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txid_miner_cero'", "vout":'$vout_miner_cero', "sequence": 1}, {"txid": "'$txid_miner_uno'", "vout":'$vout_miner_uno', "sequence": 1 } ]''' outputs='''[ { "'$address_trader'":'$deposito_coins_trader'}, {"'$address_cambio_miner'":'$cambio_up'} ]''')
	
	#Firmar y transmitir la nueva transacción parent.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Firmar y transmitir la nueva transacción parent.${endColour}\n"
	signed_tx_padre_up=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $tx_padre_up | jq -r .hex)
	txid_padre=$(bitcoin-cli sendrawtransaction $signed_tx_padre_up)
	
	#Realiza otra consulta getmempoolentry para la transacción child y muestra el resultado.
	echo "**************************************"
	echo -e "\n${redColour}[+]${endColour}${blueColour}Realiza otra consulta getmempoolentry para la transacción child y muestra el resultado.${endColour}\n"
	
	bitcoin-cli getrawmempool | jq
	bitcoin-cli getmempoolentry $txid_hijo | jq
	
	#Imprime una explicación en la terminal de lo que cambió en los dos resultados de getmempoolentry para las transacciones child y por qué.
	
	echo -e "\n${redColour}[+]${endColour}${blueColour}Imprime una explicación en la terminal de lo que cambió en los dos resultados de getmempoolentry para las transacciones child y por qué.${endColour}\n"
	echo
	echo -e "\n${redColour}[+]${endColour}${blueColour}Al crear una nueva transacción a partir de Parent que gasta las mismas monedas pero con una fee superior, se invalida la anterior, asì que el hijo queda sin padre por asì decirlo, y la transacción es rechazada.${endColour}\n"
	
	sleep 3
	
}

descargar_archivos
extrar_binarios
iniciar_bitcoin
#proceso_minado
#genera_reporte
create_wallet

