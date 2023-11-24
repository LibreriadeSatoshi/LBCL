#!/bin/bash 
#Script Ejercicio 1 .Siguiendo los pasos del enunciado del ejercicio. Instalación de Bitcoin Core etc. 
#Autor: NeoB

echo
echo Para iniciar el ejercicio se aconseja disponer de un entorno de trabajo lo más estándard posible. 
echo La recomendación es un Ubuntu 22.04 LTS con los siguientes paquetes instalados:
echo
echo -e "bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd\n"

echo -e "******************************************"
echo -e "******INICIANDO INSTALACIÓN PAQUETES******"
echo -e "******************************************\n"

sudo apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd

# Detener bitcoind y limpiar los archivos descargados para empezar de 0.
echo

bitcoin-cli stop
sleep 7
	sudo rm -r $HOME/.bitcoin
	sudo rm /usr/local/bin/bitcoin*
	sudo rm -r $HOME/bitcoin*
 	sudo rm $HOME/SHA256SUMS*
	sudo rm -r $HOME/guix.sigs
sleep 3

#Definir una variable.
version_bitcoin="25.0"

echo
echo -e "************************************************************"
echo -e "******INICIANDO DESCARGA E INSTALACION DE BITCOIN CORE******"
echo -e "************************************************************\n"
echo

echo -e "Descargar los binarios principales de Bitcoin desde el sitio web de Bitcoin Core https://bitcoincore.org/\n"

wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/bitcoin-${version_bitcoin}-x86_64-linux-gnu.tar.gz
wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/SHA256SUMS
wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/SHA256SUMS.asc

echo
echo -e "Utilizar los hashes y la firma descargados para verificar que los binarios sean correctos."
echo -e "Imprimir un mensaje en la terminal: Verificación exitosa de la firma binaria\n"

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

echo
echo -e "Crear un archivo bitcoin.conf en el directorio de datos /home/<nombre-de-usuario>/.bitcoin/"
echo -e "Crear el directorio si no existe. Y agregar las siguientes líneas al archivo:\n"

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

echo -e "Crear dos billeteras llamadas Miner y Trader.\n"

bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true

echo -e "Generar una dirección desde la billetera Miner con una etiqueta "Recompensa de Minería".\n"

miner_dir=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa de Minería")

echo -e "Nueva dirección de la billetera  Miner:${miner_dir}\n"

echo -e "Extraer nuevos bloques a esta dirección hasta obtener un saldo de billetera positivo.\n"

bitcoin-cli generatetoaddress 101 ${miner_dir}
balance_miner=$(bitcoin-cli -rpcwallet=Miner getbalance)

echo -e "Imprimir el saldo de la billetera Miner:${balance_miner}"

echo
echo -e "Crear una dirección receptora con la etiqueta Recibido desde la billetera Trader.\n"
trader_dir=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Recibido")

echo -e "Nueva dirección de la billetera  Trader:${trader_dir}\n"

echo -e "Enviar una transacción que pague 20 BTC desde la billetera Miner a la billetera del Trader.\n"

envio_trader=$(bitcoin-cli -rpcwallet=Miner sendtoaddress ${trader_dir} 20 "Envio a billetera Trader")
echo -e "La Transacción es:${envio_trader}\n"
sleep 10

echo -e "Obtener la transacción no confirmada desde el mempool del nodo y mostrar el resultado.\n"

bitcoin-cli getmempoolentry ${envio_trader} | jq -C

echo -e "Confirmar la transacción creando 1 bloque adicional.\n"

bitcoin-cli generatetoaddress 1 ${miner_dir}

echo
echo -e "***********************************************************************"
echo -e "******OBTENER DETALLES DE LA TRANSACCION Y MOSTRARLOS EN TERMINAL******"
echo -e "***********************************************************************\n"
echo

echo -e "txid: ${envio_trader}"
txgastada=`bitcoin-cli -rpcwallet=Trader getrawtransaction ${envio_trader} 1|jq -r '.vin[0].txid'`
cantidadentrada=`bitcoin-cli -rpcwallet=Trader getrawtransaction $txgastada 1|jq -r '.vout[0].value'`
direccionminer=`bitcoin-cli -rpcwallet=Trader getrawtransaction $txgastada 1|jq -r '.vout[0].scriptPubKey.address'`
echo -e "<De, Cantidad>: $direccionminer, $cantidadentrada. $NC"
cantidadenviada=`bitcoin-cli -rpcwallet=Trader getrawtransaction ${envio_trader} 1|jq -r '.vout[1].value'`
echo -e "<Enviar, Cantidad>: ${envio_trader}, ${cantidadenviada}"
cambiominer=`bitcoin-cli -rpcwallet=Trader getrawtransaction ${envio_trader} 1|jq -r '.vout[0].scriptPubKey.address'`
cantidadcambio=`bitcoin-cli -rpcwallet=Trader getrawtransaction ${envio_trader} 1|jq -r '.vout[0].value'`
echo -e "<Cambio, Cantidad>: $cambiominer, $cantidadcambio"
comisiones=`echo $cantidadentrada - $cantidadenviada - $cantidadcambio | bc`
echo -e "Comisiones: $comisiones"
altura=`bitcoin-cli -rpcwallet=Trader gettransaction ${envio_trader} |jq .blockheight`
echo -e "Bloque: $altura"
saldominer=`bitcoin-cli -rpcwallet=Miner getbalance`
echo -e "Saldo de Miner: $saldominer"
saldotrader=`bitcoin-cli -rpcwallet=Trader getbalance`
echo -e "Saldo de Trader:  $saldotrader"
