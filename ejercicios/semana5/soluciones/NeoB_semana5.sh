
# !/bin/bash
# Script curso Librería de satoshi - Aprendiendo Bitcoin desde la Línea de Comandos. Ejercicio semana 1.
# Autor: NeoBishop

limpio () {

echo
echo -e "Para iniciar las prácticas se aconseja disponer de un entorno de trabajo lo más estándard posible."
echo -e "La recomendación es un Ubuntu 22.04 LTS con los siguientes paquetes instalados"
echo
echo -e "bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd\n"



echo -e "******************************************"
echo -e "******INICIANDO INSTALACIÓN PAQUETES******"
echo -e "******************************************\n"

 sudo apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd

echo -e "Detener bitcoind y limpiar los archivos descargados para empezar de 0.\n"


 bitcoin-cli stop
 sleep 7
        sudo rm -r $HOME/.bitcoin
        sudo rm /usr/local/bin/bitcoin*
        sudo rm -r $HOME/bitcoin*
        sudo rm $HOME/SHA256SUMS*
        sudo rm -r $HOME/guix.sigs

sleep 3

}

configuracion () {

#Definir una variable.
version_bitcoin="25.0"

echo
echo -e "************************************************************"
echo -e "******INICIANDO DESCARGA E INSTALACION DE BITCOIN CORE******"
echo -e "************************************************************\n"



echo -e "Descargar los binarios principales de Bitcoin desde el sitio web de Bitcoin Core https://bitcoincore.org/\n"

wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/bitcoin-${version_bitcoin}-x86_64-linux-gnu.tar.gz
wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/SHA256SUMS
wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/SHA256SUMS.asc

echo
echo -e "Utilizar los hashes y la firma descargados para verificar que los binarios sean correctos."
echo -e "Imprimir un mensaje en la terminal: Verificación exitosa de la firma binaria\n"
echo

sha256sum --ignore-missing --check SHA256SUMS

echo
echo -e "Verificación exitosa del checksum\n"

sleep 5

git clone https://github.com/bitcoin-core/guix.sigs
gpg --import guix.sigs/builder-keys/*
gpg --verify SHA256SUMS.asc

echo
echo -e "Verificación exitosa de la firma binaria\n"
echo

sleep 5

echo
echo -e "Copiar los binarios descargados a la carpeta /usr/local/bin/.\n"
echo

tar -xvf bitcoin-${version_bitcoin}-x86_64-linux-gnu.tar.gz
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${version_bitcoin}/bin/*

sleep 5

}

inicio () {

echo
echo -e "Crear un archivo bitcoin.conf en el directorio de datos /home/<nombre-de-usuario>/.bitcoin/"
echo -e "Crear el directorio si no existe. Y agregar las siguientes líneas al archivo:\n"
echo

mkdir $HOME/.bitcoin
touch $HOME/.bitcoin/bitcoin.conf
echo "regtest=1" >> $HOME/.bitcoin/bitcoin.conf
echo "fallbackfee=0.0001" >> $HOME/.bitcoin/bitcoin.conf
echo "server=1" >> $HOME/.bitcoin/bitcoin.conf
echo "txindex=1" >> $HOME/.bitcoin/bitcoin.conf

echo "regtest=1"
echo "fallbackfee=0.0001"
echo "server=1"
echo "txindex=1"

echo
echo -e "******************************"
echo -e "******INICIANDO BITCOIND******"
echo -e "******************************\n"
echo

bitcoind -daemon
sleep 6
echo

}

regtest () {

#Parar bitcoin si se está ejecutando

bitcoin-cli stop
sleep 5

# Borrar el directorio regtest para iniciar desde cero regtest
rm -rf ~/.bitcoin/regtest

#Ejecutar bitcoin

bitcoind -daemon

sleep 5

}

semana5 () {

# Script curso Librería de satoshi - Aprendiendo Bitcoin desde la Línea de Comandos. Ejercicio semana 5.
# Autor: NeoB


# ENUNCIADO DEL PROBLEMA

# Los timelocks relativos se utilizan para crear bloqueos específicos para una entrada.
# Utilizando timelocks relativos, una transacción puede estar bloqueada hasta cierto número de bloques,
# desde el bloque en el que se ha minado la entrada a la que se hace referencia.

# El ejercicio a continuación demuestra el uso de un timelock relativo.

echo
echo -e "******************************"
echo -e "******EJERCICIO SEMANA 5******"
echo -e "******************************\n"

echo -e "*****CONFIGURAR UN TIMELOCK RELATIVO*****\n"

echo -e "*****************************************************"
echo -e "1. Crear dos  billeteras: Miner y Alice."
echo -e "*****************************************************\n"


	bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
	bitcoin-cli -named createwallet wallet_name="Alice" descriptors=true

echo
echo -e "*****************************************************************************************************"
echo -e "2. Fondea los monederos generando algunos bloques para Miner y enviando algunas monedas a Alice."
echo -e "*****************************************************************************************************\n"


	direc_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa Minería")
	echo -e "Nueva dirección para billetera Miner: $direc_miner "
	bitcoin-cli generatetoaddress 101 "$direc_miner"
	saldominer=$(bitcoin-cli -rpcwallet=Miner getbalance)
	echo -e "Saldo inicial billetera Miner= $saldominer \n"


	# Enviando monedas a Alice

	direc_alice=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Envio a Alice")
	echo -e "Nueva dirección para billetera Alice: $direc_alice "
	cambio=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Miner")
	echo -e "Nueva dirección para cambio billetera Miner: $cambio "

	#Transacion en crudo, necesitaremos 1 utxos

	utxo0txid=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .txid')
	utxo0vout=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .vout')
	rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout'}]''' outputs='''[{ "'$direc_alice'": 40 },{ "'$cambio'": 9.99999 }]''')

	echo -e "Hemos creado una transaccion en crudo donde enviamos 40BTC a Alice desde Miner \n"

	#Firmar y transmitir la Transaccion

	echo -e "Firmamos y transmitimos la Transaccion. \n"
	firmadotx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
	echo -e "La transaccion ya está firmada \n"
	txid=$(bitcoin-cli sendrawtransaction $firmadotx)
	echo -e "La transaccion se ha enviado su identificación es $txid \n"


echo -e "************************************************************************"
echo -e "3. Confirmar la transacción y chequear que Alice tiene un saldo positivo."
echo -e "************************************************************************\n"

	echo -e "Confirmando transacción en un nuevo bloque \n"
	bitcoin-cli generatetoaddress 1 "$direc_miner"
	saldoalice=$(bitcoin-cli -rpcwallet=Alice getbalance)
	echo -e "Saldo inicial billetera Alice= $saldoalice \n"
	saldominer=$(bitcoin-cli -rpcwallet=Miner getbalance)
	echo -e "Saldo actualizado billetera Miner= $saldominer \n"


echo -e "************************************************************************************************************"
echo -e "4. Crear una transacción en la que Alice pague 10 BTC al Miner, pero con un timelock relativo de 10 bloques."
echo -e "************************************************************************************************************\n"

	utxo0txid=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .txid')
	utxo0vout=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .vout')
	DirMiner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Miner")
	Cambio=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alice")
	rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo0txid'", "vout": '$utxo0vout', "sequence": '10' }  ]''' outputs='''[{ "'$DirMiner'": 9.999998 } , {"'$Cambio'":30}]''')

echo -e "Hemos creado una transaccion en crudo donde enviamos 10BTC a Miner desde Alice con una marca de tiempo de 10 bloques \n"


echo -e "Firmamos la Transaccion. \n"

	firmadotx=$(bitcoin-cli -rpcwallet=Alice signrawtransactionwithwallet $rawtxhex | jq -r '.hex')

echo -e "La transaccion ya está firmada su id es $firmadotx \n"

echo -e "*************************************************************************************************"
echo -e "5. Informar en la salida del terminal qué sucede cuando intentas difundir la segunda transacción."
echo -e "*************************************************************************************************\n"

echo -e "Enviamos la transaccion \n"

	txid=$(bitcoin-cli sendrawtransaction $firmadotx)

echo -e "La transaccion no se ha podido enviar \n"
echo -e "El script devuelve este error porque nuestra cadena de bloques aún no ha llegado al bloque marcado para poder transmitir la transacción \n"


echo -e "*****GASTAR DESDE TIMELOCK RELATIVO*****\n"

echo -e "**********************************"
echo -e "1. Generar 10 bloques adicionales."
echo -e "**********************************\n"

	bitcoin-cli generatetoaddress 10 "$direc_miner"
	saldominer=$(bitcoin-cli -rpcwallet=Miner getbalance)
	echo -e "Saldo actualizado billetera Miner= $saldominer \n"

echo -e "****************************************************************"
echo -e "2. Difundimos de nuevo la transaccion y generamos un bloque más."
echo -e "****************************************************************\n"

	txid=$(bitcoin-cli sendrawtransaction $firmadotx)

echo -e "Ahora si hemos podido enviar la transaccion, su identificacion es $txid \n"

echo -e "Minamos un bloque \n"

bitcoin-cli generatetoaddress 1 "$direc_miner"

echo -e "*******************************"
echo -e "2. Informar del saldo de Alice."
echo -e "*******************************\n"

	saldoalice=$(bitcoin-cli -rpcwallet=Alice getbalance)
	echo -e "Saldo actualizado billetera Alice= $saldoalice \n"
	saldominer=$(bitcoin-cli -rpcwallet=Miner getbalance)
	echo -e "Saldo actualizado billetera Miner= $saldominer \n"


sleep 3


}

limpio
configuracion
inicio
#regtest
semana5

