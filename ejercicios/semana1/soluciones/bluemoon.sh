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
#Proceso de Minado
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
#Crear reporte
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

descargar_archivos
extrar_binarios
iniciar_bitcoin
proceso_minado
genera_reporte
