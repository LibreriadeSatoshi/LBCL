#!/bin/bash 
#El código está escrito en Bash, que es un lenguaje de scripting utilizado comúnmente en sistemas Unix y 
#sistemas basados en Unix, como Linux. Bash se utiliza para escribir scripts de shell que ejecutan comandos en la línea de comandos #de forma secuencial y automatizada. 

#Script que automatiza la configuración de una instancia de Bitcoin Regtest, la minería de bloques y la realización de #transacciones, y finalmente genera un informe con detalles relevantes. Es importante mencionar que este script está diseñado para #fines educativos y de prueba en una red de prueba de Bitcoin, y no se debe utilizar en una red principal de Bitcoin.
#Autor: Alberto Sosa ALBitoken
#Nota Especial, me encanto el Shell de BlueMoon, agradecerle infinitamente, el cual utilice de base para el desarrollo #personalizado del Script, explicando #cada componente desde el porque de la definicion de colores, para los que como su servidor #no sabemos adentrarnos mucho al codigo #pero que ahora despacito lo vamos intentando.

# Imprimir la palabra "Bitcoin"

echo "  ____      __    _______    ____    _____    __    __    __  "
echo " |  _ \\    |  |  |_     _|  |  __|  |  _  |  |  |  |  \  |  |"
echo " | |_) |   |  |     | |     | |     |     |  |  |  |   \ |  | "
echo " |  _ <    |  |     | |     | |     | | | |  |  |  |    _   | "
echo " | |_) |   |  |     | |     | |__   |  _  |  |  |  |  |  \  | "
echo " |____/    |__|     |_|     |____|  |_____|  |__|  |__|   \_| "
echo " "
echo " >>> DESDE LA LINEA DE COMANDO - ALBitoken - Alberto Sosa <<<"

#Sección 1: Encabezado y definición de colores

#Definición de colores: Estas líneas definen variables que contienen códigos de escape ANSI para cambiar el color del texto en la #terminal. Cada variable representa un color diferente

endColour="\033[0m\e[0m"
purpleColour="\033[0;35m\033[1m"    
appleColour="\033[0;32m\033[1m"   
fucsiaColour="\033[0;35m\033[1m"     

#Sección 2: Definición de variables
#Una variable es un contenedor o espacio de memoria que se utiliza para almacenar datos o valores que pueden cambiar a lo largo de
#la ejecución de este Script
#La declaración asigna un valor a una variable llamada version_bitcoin. En este caso, se le está asignando el valor de "25.0".
#Esta variable se utiliza para almacenar la versión específica de Bitcoin que se desea instalar o utilizar en el script. 
#Más adelante en el script, esta variable se utiliza para descargar la versión correcta de Bitcoin y realizar acciones específicas
#relacionadas con esa versión.

version_bitcoin="25.0"

#Sección 3: Funciones

#3.1 Interrupción por usuario
#Con la combinación de teclas Ctrl+C en la terminal mientras se ejecuta el Script 

function ctrl_c(){
        echo -e "\n\n${purpleColour}Saliendo...${endColour}\n"  
        tput cnorm && exit 1
}

trap ctrl_c INT 
#sleep 10

echo
echo -e "***${appleColour}INSTALACION DE BITCOIN CORE REGTEG${endColour}***\n"
echo
#3.2 Creando Directorio Temporal para Descargar archivos de bitcoin y validar firma
#3.2.1 Directorio Temporal
descargar_archivos(){ 
	#Colocar archivos descargados a /tmp
	cd /tmp
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}DESCARGA DE ARCHIVOS BITCOIN CORE Y VALIDACION .${endColour}\n"
	echo "**************************************"
	
#3.2.2 Descargar bitcoin desde el sitio web oficial de Bitcoin
	wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/bitcoin-${version_bitcoin}-x86_64-linux-gnu.tar.gz
	
#3.2.3 Descargar el archivo SHA256SUMS para verificar la integridad del binario.
	wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/SHA256SUMS

	echo "**************************************\n"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Verificar el hash del binario de bitcoin.${endColour}\n"

	sha256sum bitcoin-${versionBitcoin}-x86_64-linux-gnu.tar.gz 
	
#3.2.4 Verificar que el hash obtenido coincida con el hash del archivo SHA256SUMS 
	verify_sha256sum=$(sha256sum --ignore-missing --check SHA256SUMS 2>&1)
	ok_sha256sum=$(echo ${verify_sha256sum} | grep 'OK' -c)
	#ok_sha256sum=$(echo ${verify_sha256sum} | grep 'La suma coincide' -c)

	if [ ${ok_sha256sum} -lt 1 ]; then
		echo
		echo -e "\n${appleColour}[==]${endColour}${fucsiaColour}Verificación de SHA256SUMS incorrecta.${endColour}${appleColour}[==]${endColour}\n"
		echo
	else
		echo "\n****************************"
		echo -e "\n${fucsiaColour}[==]${endColour}${appleColour}Coincide con el hash del archivo SHA256SUMS${endColour}${fucsiaColour}[==]${endColour}\n"
		echo "****************************"
	fi
	
#3.2.5 Descargar las llaves publicas del equipo de Bitcoin Core.
	gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 01EA5486DE18A882D4C2684590C8019E36C2E964 

#3.2.6 Descargar SHA256SUMS.asc
	wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/SHA256SUMS.asc

#3.2.7 Verificar que el archivo checksums esté firmado criptográficamente
	verify_asc=$(gpg --verify SHA256SUMS.asc 2>&1)
	ok_asc=$(echo ${verify_asc} | grep 'Good signature' -c)
	#ok_asc=$(echo ${verify_asc} | grep 'Firma correcta' -c)

	if [ ${ok_asc} -lt 1 ]; then
		echo
		echo -e "\n${purpleColour}[+]${endColour}${fucsiaColour}Verificación de PGP incorrecta.${endColour}\n"
		echo
	else
		echo "****************************"
		echo -e "\n${fucsiaColour}[+]${endColour}${appleColour}Verificación exitosa de la firma binaria.${endColour}\n"
		echo "****************************"
	fi
}
#3.3 Extraer, copiar, crear e instalar los binarios
#3.3.1 Extraer los binarios de Bitcoin Core
extrar_binarios(){
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Extrayendo los binarios de Bitcoin Core.${endColour}\n"

	tar -xvf bitcoin-${version_bitcoin}-x86_64-linux-gnu.tar.gz > /dev/null 

#3.3.2 Copiar los binarios descargados a la carpeta /usr/local/bin/.
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Copiando los binarios descargados a la carpeta${endColour} ${appleColour}/usr/local/bin/.${endColour}\n"

	sudo mv bitcoin-${version_bitcoin} /usr/local/bin/

#3.3.3 Crear un archivo bitcoin.conf en el directorio de datos /home/<nombre-de-usuario>/.bitcoin/
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Crear directorio llamado .bitcoin y archivo bitcoin.conf en el directorio de datos del usuario.${endColour}\n"

	cd $HOME && mkdir .bitcoin
	cd $HOME/.bitcoin/
	echo -e "regtest=1\nfallbackfee=0.0001\nserver=1\ntxindex=1" > bitcoin.conf 

#3.3.4 Instalar los binarios de bitcoin core en el sistema operativo
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Instalar los binarios de en el Sistema Operativo.${endColour}\n"

	cd /usr/local/bin/
	sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${version_bitcoin}/bin/*
	sleep 3
	
#3.3.5 Borrar archivos /tmp
	cd /tmp 
	rm -rf bitcoin* SHA256SUMS*
}

#3.4 Iniciar bitcoin

#3.4.1 Iniciar una instancia de Bitcoin Regtest en modo daemon.
iniciar_bitcoin(){
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Verificar version Bitcoin.${endColour}\n"

#3.4.2 Verificar version instalada sea la correcta
	install_ok=$(sudo bitcoind --version | grep "${version_bitcoin}" -c)

	if [ ${install_ok} -lt 1 ]; then
		echo
		echo -e "\n${appleColour}[==]${endColour}${fucsiaColour}Instalación de binarios de Bitcoin incorrecta.${endColour}${appleColour}[==]${endColour}\n"
		echo
	else
		echo "****************************"
		echo -e "\n${fucsiaColour}[==]${endColour}${appleColour}Instalación de binarios de Bitcoin correcta ${versionBitcoin}.${endColour}${fucsiaColour}[==]${endColour}\n"
		echo "****************************"
	fi

	#Iniciar bitcoin regtest
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Iniciar bitcoind regtest.${endColour}\n"

	bitcoind -regtest -daemon
	#bitcoind -regtest -daemon -fallbackfee=1.0 -maxtxfee=1.1
	#bitcoind >/dev/null &
	sleep 10s
}

#3.5 Proceso de Mineria y Transacciones
#3.5.1 Procesar Minado
proceso_minado(){

#3.5.2 Crear dos billeteras llamadas Miner y Trader.
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Crear dos billeteras llamadas Miner y Trader.${endColour}\n"

	bitcoin-cli -regtest -named createwallet wallet_name="Miner" > /dev/null
	bitcoin-cli -regtest -named createwallet wallet_name="Trader" > /dev/null

	#Generar una dirección desde la billetera Miner con una etiqueta "Recompensa de Minería".
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Generar una dirección desde la billetera Miner con una etiqueta Recompensa de Minería.${endColour}\n"

#3.5.3 Cargar wallet
	#3.5.3.1 bitcoin-cli loadwallet Miner 
	#3.5.3.2 Generar direccion
	address_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa de Minería")
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Direccion Miner:${endColour}  ${appleColour}${address_miner}.${endColour}\n"

#3.5.4 Extraer nuevos bloques a esta dirección hasta obtener un saldo de billetera positivo. 
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Extraer nuevos bloques a esta dirección hasta obtener un saldo de billetera positivo.${endColour}\n"
	bitcoin-cli generatetoaddress 101 ${address_miner} >/dev/null
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Obtener informacion de la Cadena de bloques.${endColour}\n"
	bitcoin-cli getblockchaininfo | jq -C

#3.5.5 Imprimir el saldo de la billetera Miner.
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Saldo de la billetera Miner .${endColour}\n"
	bitcoin-cli -rpcwallet=Miner getbalance 

	sleep 10s

	echo 
#3.5.6 Crear una dirección receptora con la etiqueta Recibido desde la billetera Trader.
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Crear una dirección receptora con la etiqueta Recibido desde la billetera Trader.${endColour}\n"

	#3.5.6.1 Cargar wallet de Trader
	#3.5.6.2 bitcoin-cli loadwallet Trader 
	#3.5.6.3 Generar direccion
	address_trader=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Recibido")
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Direccion del Trader:${endColour} ${appleColour} ${address_trader}.${endColour}\n"

#3.5.7 Enviar una transacción que pague 20 BTC desde la billetera Miner a la billetera del Trader.
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Enviar una transacción que pague 20 BTC desde la billetera Miner a la billetera del Trader.${endColour}\n"

#3.5.8 Cargar wallet Miner
	#3.5.8.1 bitcoin-cli loadwallet Miner 

#3.5.9 Enviar sats
	txid_trader=$(bitcoin-cli -rpcwallet=Miner sendtoaddress ${address_trader} 20 "Envio a Trader")

	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Transaccion: ${endColour} ${appleColour}${txid_trader}.${endColour}\n"

	sleep 10s

#3.5.10 Obtener la transacción no confirmada desde el mempool del nodo y mostrar el resultado.
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Obtener la transacción no confirmada desde el mempool del nodo y mostrar el resultado.${endColour}\n"

	bitcoin-cli getmempoolentry ${txid_trader} | jq -C

#3.5.11 Confirmar la transacción creando 1 bloque adicional.
	echo "**************************************"
	echo -e "\n${fucsiaColour}[+]${endColour}${purpleColour}Confirmar la transacción creando 1 bloque adicional.${endColour}\n"
	bitcoin-cli generatetoaddress 1 ${address_miner} >/dev/null

}
#4 Generacion de Reportes
#4.1 Generar Reporte de Transacciones 
genera_reporte(){
	#4.1.1 Transaccion Trader
	raw_transaction_trader=$(bitcoin-cli getrawtransaction $txid_trader)
	#4.1.2 Transaccion del Miner
	txid_miner=$(bitcoin-cli decoderawtransaction $raw_transaction_trader | jq -r .vin[0].txid)

	#4.1.3 Mostrar datos de la transaccion del Miner
	raw_transaction_miner=$(bitcoin-cli getrawtransaction $txid_miner)
	 
	#4.1.4 Transaccion input, obtener la cantidad de la transaccion del Miner
	value_miner=$(bitcoin-cli decoderawtransaction $raw_transaction_miner | jq -r .vout[0].value)

	#4.1.5 Transaccion output 0 obtener datos del minado
	#4.1.6 address_trader=$(bitcoin-cli decoderawtransaction $raw_transaction_trader | jq -r .vout[0].scriptPubKey.address)
	value_trader=$(bitcoin-cli decoderawtransaction $raw_transaction_trader | jq -r .vout[0].value)

	#4.1.7 Transaccion output 1 obtener datos del cambio
	address_cambio=$(bitcoin-cli decoderawtransaction $raw_transaction_trader | jq -r .vout[1].scriptPubKey.address)
	value_cambio=$(bitcoin-cli decoderawtransaction $raw_transaction_trader | jq -r .vout[1].value)

	#4.1.8 Comisiones: Cantidad pagada en comisiones.
	fee=$(echo $value_miner - $value_cambio - $value_trader | bc)

	#4.1.9 Bloque: Altura del bloque en el que se confirmó la transacción.
	block=$(bitcoin-cli -rpcwallet=Trader gettransaction $txid_trader | jq -Cr '.blockheight')
	#4.1.10 Saldo de Miner: Saldo de la billetera Miner después de la transacción.
	balance_trader=$(bitcoin-cli -rpcwallet=Trader getbalance)
	#4.1.11 Saldo de Trader: Saldo de la billetera Trader después de la transacción.
	balance_miner=$(bitcoin-cli -rpcwallet=Miner getbalance)

	echo
	echo -e "***${fucsiaColour}REPORTE.${endColour}***"
	echo

	echo -e "${appleColour}DIRECCION MINER:${endColour} ${address_miner} ${appleColour}CANTIDAD:${endColour} ${value_miner}"
	echo -e "${appleColour}DIRECCION TRADER:${endColour} ${address_trader} ${appleColour}CANTIDAD:${endColour} ${value_trader}"
	echo -e "${appleColour}DIRECCION DE CAMBIO:${endColour} ${address_cambio} ${appleColour}CANTIDAD:${endColour} ${value_cambio}"

	echo -e "\n${purpleColour}FEE       BLOQUE	  BALANCE TRADER	  BALANCE MINER${endColour}"
	echo -e "----------  ----------  ----------------  ----------------"
	echo -e "$(printf %9s "$fee") $(printf %19s "$block") $(printf %18s "$balance_trader") $(printf %20s "$balance_miner")"

	echo
	echo -e "***${fucsiaColour}GRACIAS LIBRERIA DE SATOSHI POR LA EDUCACION DE CALIDAD Y POR TODO EL POW QUE HACE FUERTE A LA COMUNIDAD BITCOINER${endColour}***"
	echo 
}

# 5.Llamar las funciones
# Se llaman las funciones del script para asegurar que se ejecuten en el orden correcto y de forma estructurada para realizar las 
# tareas específicas relacionadas con Bitcoin Regtest. 
descargar_archivos
extrar_binarios
iniciar_bitcoin
proceso_minado
genera_reporte
