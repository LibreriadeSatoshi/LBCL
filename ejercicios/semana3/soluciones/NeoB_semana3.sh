
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

semana3 () {

# Script curso Librería de satoshi - Aprendiendo Bitcoin desde la Línea de Comandos. Ejercicio semana 3.
# Autor: NeoB


# ENUNCIADO DEL PROBLEMA

# Las transacciones multisig son un aspecto fundamental de la "criptografía Bitcoin compleja" que permite la copropiedad de UTXOs de Bitcoin.
# Juegan un papel crucial en las soluciones de custodia conjunta para los protocolos de la Capa 2 (L2).
# Los protocolos L2 comúnmente comienzan estableciendo una transacción de financiamiento multisig entre las partes involucradas.
# Por ejemplo, en Lightning, ambas partes pueden financiar conjuntamente la transacción antes de llevar a cabo sus transacciones relámpago.
# Al cerrar el canal, pueden liquidar el multisig para reclamar sus respectivas partes.

# En este ejercicio, nuestro objetivo es simular una transferencia básica de acciones multisig entre dos participantes, Alice y Bob.

echo -e "******************************"
echo -e "******EJERCICIO SEMANA 3******"
echo -e "******************************\n"

echo -e "*****CONFIGURAR MULTISIG*****\n"

echo -e "**************************************************************************************************************"
echo -e "1. Crear tres monederos: Miner, Alice y Bob. Es importante usar billeteras sin descriptores."
echo -e "   ya que sino lo hacemos, nos encontraremos con problemas al usar la opción de bitcoin-cli addmultisigaddress."
echo -e "***************************************************************************************************************\n"


	bitcoin-cli -named createwallet wallet_name="Miner" descriptors=false
	bitcoin-cli -named createwallet wallet_name="Alice" descriptors=false
	bitcoin-cli -named createwallet wallet_name="Bob" descriptors=false


echo -e "*******************************************************************************************************"
echo -e "2. Fondear los monederos generando algunos bloques para Miner y enviando algunas monedas a Alice y Bob."
echo -e "*******************************************************************************************************\n"


	direc_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa Minería")
	echo -e "Nueva dirección para billetera Miner: $direc_miner "
	bitcoin-cli generatetoaddress 103 "$direc_miner"
	saldominer=$(bitcoin-cli -rpcwallet=Miner getbalance)
	echo -e "Saldo inicial billetera Miner= $saldominer "


	# Nuevas direcciones para Alice y Bob

	direc_alice=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Envio a Alice")
	echo -e "Nueva dirección para billetera Alice: $direc_alice "
	txalice=$(bitcoin-cli -rpcwallet=Miner sendtoaddress "$direc_alice" 50)
	echo -e "ID de la transacción a Alice: $txalice "
	direc_bob=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Envio a Bob")
	echo -e "Nueva dirección para billetera Bob: $direc_bob "
	txbob=$(bitcoin-cli -rpcwallet=Miner sendtoaddress "$direc_bob" 50)
	echo -e "ID de la transacción a Bob: $txbob "
	echo -e "Confirmando transacción en un nuevo bloque "
	bitcoin-cli generatetoaddress 1 "$direc_miner"
	saldoalice=$(bitcoin-cli -rpcwallet=Alice getbalance)
	echo -e "Saldo inicial billetera Alice= $saldoalice "
	saldobob=$(bitcoin-cli -rpcwallet=Bob getbalance)
	echo -e "Saldo inicial billetera Bob= $saldobob \n"


echo -e "*************************************************************************************"
echo -e "3. Crear una dirección Multisig 2-de-2 combinando las claves públicas de Alice y Bob."
echo -e "*************************************************************************************\n"

	# Nuevas direcciones para Alice y Bob

	direc_alice_multisig=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Dirección multisig de Alice")
	echo -e "Nueva dirección multisig para billetera Alice: $direc_alice_multisig "
	direc_bob_multisig=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Dirección multisig de Bob")
	echo -e "Nueva dirección multisig para billetera bob: $direc_bob_multisig "

	# llaves publicas de las nuevas direcciones

	pubkeyAlice=$(bitcoin-cli -rpcwallet=Alice -named getaddressinfo address=$direc_alice_multisig | jq -r '.pubkey')
	echo -e "Llave publica de Alice: $pubkeyAlice "
	pubkeyBob=$(bitcoin-cli -rpcwallet=Bob -named getaddressinfo address=$direc_bob_multisig | jq -r '.pubkey')
	echo -e "Llave publica de Bob: $pubkeyBob "

	# creando la direccion multifirma

	direc_multisig=$(bitcoin-cli -named -rpcwallet=Alice addmultisigaddress nrequired=2 keys='''["'$pubkeyAlice'","'$pubkeyBob'"]''' | jq -r '.address')
	echo -e "Detalles de dirección multifirma:  $direc_multisig \n"


echo -e "************************************************************************************************************"
echo -e "4. Crear una Transacción Bitcoin Parcialmente Firmada (PSBT) para financiar la dirección multisig con 20 BTC"
echo -e "   tomando 10 BTC de Alice y 10 BTC de Bob, y proporcionando el cambio correcto a cada uno de ellos."
echo -e "************************************************************************************************************\n"


	direc_alice_cambio=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Dirección para cambio  Alice")
	echo -e "Direccion de cambio en la billetera Alice: $direc_alice_cambio "
	direc_bob_cambio=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Dirección para cambio Bob")
	echo -e "Direccion de cambio en la billetera Bob: $direc_bob_cambio "
	vouttxAlice=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .vout')
	vouttxBob=$(bitcoin-cli -rpcwallet=Bob listunspent | jq -r '.[0] | .vout')

	# creando la PSBT:

	psbtraw=$(bitcoin-cli -named createpsbt inputs='''[ { "txid": "'$txalice'", "vout": '$vouttxAlice' }, { "txid": "'$txbob'", "vout": '$vouttxBob' } ]''' outputs='''[ { "'$direc_multisig'": 20 }, { "'$direc_alice_cambio'": 40 }, { "'$direc_bob_cambio'": 39.9999 } ]''')
	echo -e "PSBT creada sin firmas: $psbtraw "
	bitcoin-cli analyzepsbt $psbtraw | jq

	psbtfirmadaAlice=$(bitcoin-cli -rpcwallet=Alice walletprocesspsbt $psbtraw | jq -r '.psbt')
	echo -e "PSBT de Alice $psbtfirmadaAlice "
	bitcoin-cli -named analyzepsbt psbt=$psbtfirmadaAlice | jq

	sleep 3

	psbtfirmadaBob=$(bitcoin-cli -rpcwallet=Bob walletprocesspsbt $psbtraw | jq -r '.psbt')
	echo -e "PSBT de Bob $psbtfirmadaBob "
	bitcoin-cli -named analyzepsbt psbt=$psbtfirmadaBob | jq

	sleep 3

	psbtcombinada=$(bitcoin-cli combinepsbt '''["'$psbtfirmadaAlice'", "'$psbtfirmadaBob'"]''')
	echo -e "Transacción PSBT combinada:  $psbtcombinada "
	echo "Transacción PSBT decodificada:"
	bitcoin-cli -named analyzepsbt psbt=$psbtcombinada | jq
	psbthex=$(bitcoin-cli finalizepsbt $psbtcombinada | jq -r '.hex')
	txpsbt=$(bitcoin-cli -named sendrawtransaction hexstring=$psbthex)
	echo -e "ID de Transacción PSBT enviada:  $txpsbt \n"

echo -e "*************************************************************************"
echo -e "5. Confirmar el saldo mediante la minería de algunos bloques adicionales."
echo -e "*************************************************************************\n"

	echo -e "Confirmando transacciones en nuevo bloque "
		bitcoin-cli generatetoaddress 1 "$direc_miner"
		sleep 3

echo -e "**********************************************"
echo -e "6. Imprimir los saldos finales de Alice y Bob."
echo -e "**********************************************\n"

	saldoalice=$(bitcoin-cli -rpcwallet=Alice getbalance)
	echo -e "Balance Final en la billetera de Alice $saldoalice "
	saldobob=$(bitcoin-cli -rpcwallet=Bob getbalance)
	echo -e "Balance Final en la billetera de  Bob $saldobob "
	saldomulti=$(bitcoin-cli getrawtransaction $txpsbt 1|jq '.vout[0] |.value')
	echo -e "Balance Final en direccion Multifirma $saldomulti \n"

echo -e "*****LIQUIDAR MULTISIG*****\n"

echo -e "********************************************************************************************************************"
echo -e "1. Crear una PSBT para gastar fondos del multisig, asegurando que se distribuyan igualmente 10 BTC entre Alice y Bob"
echo -e "   después de tener en cuenta las tarifas.Imprimir los saldos finales de Alice y Bob."
echo -e "********************************************************************************************************************\n"

	bitcoin-cli -named -rpcwallet=Bob addmultisigaddress nrequired=2 keys='''["'$pubkeyAlice'","'$pubkeyBob'"]''' | jq -r '.address'
	bitcoin-cli -named -rpcwallet=Alice importaddress address="$direc_multisig" rescan=false
	bitcoin-cli -named -rpcwallet=Bob importaddress address="$direc_multisig" rescan=false

	# Variables para crear la TX

	txidMulti=$txpsbt
	vouttxMulti=0
	envio_alice=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Envio a Alice")
	echo -e "Direccion de envio a la billetera Alice: $envio_alice "
	envio_bob=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Envio a Bob")
	echo -e "Direccion de envio a la billetera Bob: $envio_bob "

	# calculando tarifa, que ambos paguen 500 sats

	pagoconfees=$(echo 10 - 0.00000500|bc)
	echo -e "Alice y Bob pagan 500 sats de fee de mineria y recibirán $pagoconfees sats en sus billeteras"

	# creando la PSBT:

	vpsbtraw=$(bitcoin-cli -named createpsbt inputs='''[ { "txid": "'$txidMulti'", "vout": '$vouttxMulti' } ]''' outputs='''[ { "'$envio_alice'": '$pagoconfees' }, { "'$envio_bob'": '$pagoconfees' } ]''')
	echo -e "Transaccion sin firmar: $vpsbtraw "
	bitcoin-cli -named analyzepsbt psbt=$vpsbtraw |jq

	sleep 5

echo -e "****************************"
echo -e "2. Firmar la PSBT por Alice."
echo -e "****************************\n"

	vpsbtfirmadaAlice=$(bitcoin-cli -rpcwallet=Alice walletprocesspsbt $vpsbtraw | jq -r '.psbt')
	echo -e "PSBT de  Alice $vpsbtfirmadaAlice "
	bitcoin-cli -named analyzepsbt psbt=$vpsbtfirmadaAlice |jq

	sleep 5

echo -e "****************************"
echo -e "3. Firmar la PSBT por Bob."
echo -e "****************************\n"

	vpsbtfirmadaBob=$(bitcoin-cli -rpcwallet=Bob walletprocesspsbt $vpsbtraw | jq -r '.psbt')
	echo -e "PSBT de  Bob $vpsbtfirmadaBob "
	bitcoin-cli -named analyzepsbt psbt=$vpsbtfirmadaBob |jq

	sleep 5

echo -e "**********************************************"
echo -e "4. Extraer y transmitir la transacción completamente firmada."
echo -e "**********************************************\n"

	vpsbtcombinada=$(bitcoin-cli combinepsbt '''["'$vpsbtfirmadaAlice'", "'$vpsbtfirmadaBob'"]''')
	echo -e "Transacción PSBT combinada:  $vpsbtcombinada "
	echo "Transacción PSBT decodificada:"
	bitcoin-cli -named analyzepsbt psbt=$vpsbtcombinada |jq
	vpsbthex=$(bitcoin-cli finalizepsbt $vpsbtcombinada | jq -r '.hex')
	txvpsbt=$(bitcoin-cli -named sendrawtransaction hexstring=$vpsbthex)
	echo -e "ID de Transacción PSBT enviada a la mempool:  $txvpsbt "

	sleep 5

echo -e "**********************************************"
echo -e "5. Imprimir los saldos finales de Alice y Bob."
echo -e "**********************************************\n"

echo -e "Confirmando transacciones en nuevo bloque "
        bitcoin-cli generatetoaddress 1 "$direc_miner"

	saldoalice=$(bitcoin-cli -rpcwallet=Alice getbalance)
        echo -e "Balance Final en la billetera de Alice $saldoalice "
        saldobob=$(bitcoin-cli -rpcwallet=Bob getbalance)
        echo -e "Balance Final en la billetera de  Bob $saldobob "

sleep 4

}

limpio
configuracion
inicio
semana3

