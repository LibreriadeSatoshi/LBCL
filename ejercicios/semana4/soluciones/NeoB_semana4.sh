
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

semana4 () {

# Script curso Librería de satoshi - Aprendiendo Bitcoin desde la Línea de Comandos. Ejercicio semana 4.
# Autor: NeoB


# ENUNCIADO DEL PROBLEMA

#Los timelocks son mecanismos para crear transacciones que están bloqueadas hasta que haya pasado X unidades de tiempo.
#Estas transacciones no pueden incluirse en el bloque hasta que haya transcurrido el tiempo especificado.
#Esto puede ser útil para varios tipos de situaciones de flujo de transacciones en las que los fondos están bloqueados de manera segura.
#OP_RETURN es un código de operación que se puede utilizar para grabar datos aleatorios en una transacción.
#Esto tiene diversos usos, desde la marca de tiempo hasta los NFT (Tokens No Fungibles) basados en Bitcoin.
#En el siguiente ejercicio, pasaremos por un flujo de trabajo en el que un empleado recibe su salario de un empleador,
#pero solo después de que haya transcurrido cierto tiempo.
#El empleado también lo celebra y realiza un gasto de OP_RETURN para que todo el mundo sepa que ya no está desempleado

echo
echo -e "******************************"
echo -e "******EJERCICIO SEMANA 4******"
echo -e "******************************\n"

echo -e "*****CONFIGURANDO UN CONTRATO TIMELOCK*****\n"

echo -e "*****************************************************"
echo -e "1. Crear tres monederos: Miner, Empleado y Empleador."
echo -e "*****************************************************\n"


	bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
	bitcoin-cli -named createwallet wallet_name="Empleado" descriptors=true
	bitcoin-cli -named createwallet wallet_name="Empleador" descriptors=true

echo
echo -e "*****************************************************************************************************"
echo -e "2. Fondea los monederos generando algunos bloques para Miner y enviando algunas monedas al Empleador."
echo -e "*****************************************************************************************************\n"


	direc_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa Minería")
	echo -e "Nueva dirección para billetera Miner: $direc_miner "
	bitcoin-cli generatetoaddress 103 "$direc_miner"
	saldominer=$(bitcoin-cli -rpcwallet=Miner getbalance)
	echo -e "Saldo inicial billetera Miner= $saldominer \n"


	# Enviando monedas al Empleador

	direc_empleador=$(bitcoin-cli -rpcwallet=Empleador getnewaddress "Envio a Empleador")
	echo -e "Nueva dirección para billetera Empleador: $direc_empleador "
	txempleador=$(bitcoin-cli -rpcwallet=Miner sendtoaddress "$direc_empleador" 50)
	echo -e "ID de la transacción a Empleador: $txempleador "
	echo -e "Confirmando transacción en un nuevo bloque "
	bitcoin-cli generatetoaddress 1 "$direc_miner"
	saldoempleador=$(bitcoin-cli -rpcwallet=Empleador getbalance)
	echo -e "Saldo inicial billetera Empleador= $saldoempleador \n"

echo -e "**********************************************************************************"
echo -e "3. Crea una transacción de salario de 40 BTC, donde el Empleador paga al Empleado."
echo -e "**********************************************************************************\n"

	# Nueva dirección para el Empleado

	direc_empleado=$(bitcoin-cli -rpcwallet=Empleado getnewaddress "Envio a Empleado")
	echo -e "Nueva dirección para billetera Empleado: $direc_empleado \n"

	# txempleado=$(bitcoin-cli -rpcwallet=Empleador sendtoaddress "$direc_empleado" 40)
	cambio_empleador=$(bitcoin-cli -rpcwallet=Empleador getnewaddress "Cambio a Empleador")


echo -e "*******************************************************************************************"
echo -e "4. Agrega un timelock absoluto de 500 bloques para la transacción, es decir, la transacción"
echo -e "   no puede incluirse en el bloque hasta que se haya minado el bloque 500."
echo -e "*******************************************************************************************\n"

	bloque_actual=$(bitcoin-cli getblockcount|bc)
	echo "Bloque  actual en la cadena de bloques: $bloque_actual "
	bloque_actual_mas500=$(echo "$bloque_actual + 500"|bc)
	echo "Altura dentro de 500 bloques: $bloque_actual_mas500 "
	txempleado=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txempleador'", "vout": '1' } ]''' outputs='''{ "'$direc_empleado'": 40, "'$cambio_empleador'": 9.999998 }''' locktime=$bloque_actual_mas500)
	echo -e "Hex de transaccion hacia Empleado: $txempleado \n"
	bitcoin-cli decoderawtransaction $txempleado |jq

	sleep 3


echo -e "***********************************************************************************"
echo -e "5. Informa en un comentario qué sucede cuando intentas transmitir esta transacción."
echo -e "***********************************************************************************\n"

	txempleado_firmada=$(bitcoin-cli -rpcwallet=Empleador -named signrawtransactionwithwallet hexstring=$txempleado | jq -r '.hex')
	echo -e "HEX de la transaccion firmada: $txempleado_firmada "

#	txidempleado=$(bitcoin-cli -named sendrawtransaction hexstring=$txempleado_firmada)

	bitcoin-cli -named sendrawtransaction hexstring=$txempleado_firmada 
	echo -e "El script devuelve este error porque nuestra cadena de bloques aún no ha llegado al bloque marcado para poder transmitir la transacción \n"

echo -e "*******************************************************"
echo -e "6. Mina hasta el bloque 500 y transmite la transacción."
echo -e "*******************************************************\n"

	bitcoin-cli generatetoaddress 500 "$direc_miner" | jq
	alturaactual=$(bitcoin-cli getblockcount|bc)
	txidempleado=$(bitcoin-cli -named sendrawtransaction hexstring=$txempleado_firmada)
	echo -e "En la altura de bloque $alturaactual, se intenta enviar  la transaccion y tenemos el siguiente mensaje: $txidempleado \n"

echo -e "*******************************************************"
echo -e "7. Imprime los saldos finales del Empleado y Empleador."
echo -e "*******************************************************\n"

	bitcoin-cli generatetoaddress 1 "$direc_miner"
	saldoempleador=$(bitcoin-cli -rpcwallet=Empleador getbalance)
	echo -e "Balance actual en la billetera Empleador $saldoempleador "
	saldoempleado=$(bitcoin-cli -rpcwallet=Empleado getbalance)
	echo -e "Balance actual en la billetera Empleado $saldoempleado \n"

	sleep 3

echo -e "*****GASTAR DESDE EL TIMELOCK*****\n"

echo -e "***********************************************************************************************************************"
echo -e "1. Crea una transacción de gasto en la que el Empleado gaste los fondos a una nueva dirección de monedero del Empleado."
echo -e "***********************************************************************************************************************\n"

	direc_salario_empleado=$(bitcoin-cli -rpcwallet=Empleado getnewaddress "Dirección de gasto salario Empleado")
	echo -e "Nueva direccion de gasto en la billetera Empleado: $direc_salario_empleado \n"

echo -e "***************************************************************************************************************************"
echo -e "2. Agrega una salida OP_RETURN en la transacción de gasto con los datos de cadena "He recibido mi salario, ahora soy rico"."
echo -e "***************************************************************************************************************************\n"

#convertimos el mensaje a HEXADECIMAL y eliminando espacios ya que bitcoin core solo acepta este tipo de codificacion

	mensaje=$(echo -n "He recibido mi salario, ahora soy rico"|xxd -p -u)
	op_return_datos=$(echo $mensaje| sed 's/ //g')
	txsalario_empleado=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txidempleado'", "vout": '0' } ]''' outputs='''{ "data": "'$op_return_datos'", "'$direc_salario_empleado'": 39.99999800 }''')
	echo -e "Hex de transaccion saliario de Empleado: $txsalario_empleado \n"
	bitcoin-cli decoderawtransaction $txsalario_empleado |jq

	sleep 3

echo -e "***********************************************************"
echo -e "3. Extrae y transmite la transacción completamente firmada."
echo -e "***********************************************************\n"

	signedtxsalario_empleado=$(bitcoin-cli -rpcwallet=Empleado -named signrawtransactionwithwallet hexstring=$txsalario_empleado | jq -r '.hex')
	txidsalario_empleado=$(bitcoin-cli -named sendrawtransaction hexstring=$signedtxsalario_empleado)
	echo -e "Id de transaccion salario de Empleado: $txidsalario_empleado \n"

echo -e "*******************************************************"
echo -e "4. Imprime los saldos finales del Empleado y Empleador."
echo -e "*******************************************************\n"

echo -e "Confirmando transacciones en nuevo bloque "
	bitcoin-cli generatetoaddress 1 "$direc_miner"
	echo -e "Mensaje en hexadecimal en el OP_RETURN del script de bloqueo:"
	bitcoin-cli getrawtransaction $txidsalario_empleado 1 |jq '.vout[0]| .scriptPubKey|.asm'
	saldoempleado=$(bitcoin-cli -rpcwallet=Empleado getbalance)
	echo
	echo -e "Balance actual en la billetera Empleado $saldoempleado "
	saldoempleador=$(bitcoin-cli -rpcwallet=Empleador getbalance)
	echo -e "Balance actual en la billetera  Empleador $saldoempleador "

	sleep 3


}

limpio
configuracion
inicio
#regtest
semana4

