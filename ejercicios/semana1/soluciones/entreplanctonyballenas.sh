#!/bin/bash
autor (){
clear
# color
YELL='\e[33m'
NC='\e[0m'
echo "********************************"
echo -e "$YELL Instalando Banner para mejor presentación $NC"
echo "********************************"
	apt install sysvbanner
	##########################
	banner Script de entre plancton yballenas
	##########################
sleep 3
}
limpieza () {
echo "********************************"
banner LIMPIEZA
echo "********************************"
	# Detener bitcoind y limpiar los archivos descargados para empezar de 0.
	bitcoin-cli stop
	rm -r $HOME/.bitcoin
	rm /usr/local/bin/bitcoin*
	rm -r $HOME/bitcoin*
	rm $HOME/SHA256SUMS*
	rm -r $HOME/guix.sigs
sleep 3
}
configuracion () {
echo "********************************"
banner CONFIGURA
echo "********************************"
	echo "*** 0. Instalacion de paquetes"
	echo "********************************"
		apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd
	echo "********************************"
	echo "*** 1. Descargar los binarios principales de Bitcoin desde el sitio web de Bitcoin Core https://bitcoincore.org/."
	echo "********************************"
		wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-x86_64-linux-gnu.tar.gz
	echo "********************************"
	echo "*** 2. Utilizar los hashes y la firma descargados para verificar que los binarios sean correctos. Imprimir un mensaje en la terminal: "Verificación exitosa de la firma binaria"."
	echo "********************************"
		wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS
		wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS.asc
		sha256sum --ignore-missing --check SHA256SUMS
		echo -e "$YELL Verificación exitosa del checksum de los archivos $NC"
		sleep 3
		git clone https://github.com/bitcoin-core/guix.sigs
		gpg --import guix.sigs/builder-keys/*
		gpg --verify SHA256SUMS.asc
		echo -e "$YELL Verificación exitosa de la firma binaria $NC"
		sleep 3
	echo "********************************"
	echo "*** 3. Copiar los binarios descargados a la carpeta /usr/local/bin/."
	echo "********************************"
		tar -xvf bitcoin-25.0-x86_64-linux-gnu.tar.gz
		sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-25.0/bin/*
		#rm -r $HOME/bitcoin*
		#rm $HOME/SHA256SUMS*
		#rm -r $HOME/guix.sigs
sleep 5
}
inicio () {
echo "********************************"
banner INICIO
echo "********************************"
	echo "*** 1. Crear un archivo bitcoin.conf en el directorio de datos /home/<nombre-de-usuario>/.bitcoin/. Crear el directorio si no existe. Y agregar las siguientes líneas al archivo:"
	echo "********************************"
		mkdir $HOME/.bitcoin
		touch $HOME/.bitcoin/bitcoin.conf
		echo "regtest=1" >> $HOME/.bitcoin/bitcoin.conf
		echo "fallbackfee=0.0001" >> $HOME/.bitcoin/bitcoin.conf
		echo "server=1" >> $HOME/.bitcoin/bitcoin.conf
		echo "txindex=1" >> $HOME/.bitcoin/bitcoin.conf
	echo "********************************"
	echo "*** 2. Iniciar bitcoind."
	echo "********************************"
		bitcoind -daemon
		echo -e "$YELL Esperando que levante bitcoind... $NC"
		sleep 5
	echo "********************************"
	echo "*** 3. Crear dos billeteras llamadas Miner y Trader."
	echo "********************************"
		bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
		bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true
	echo "********************************"
	echo "*** 4. Generar una dirección desde la billetera Miner con una etiqueta "Recompensa de Minería"."
	echo "********************************"
		reward=`bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa de Minería"`
		echo -e "$YELL Nueva direccion en la cartera Miner: $reward $NC"
		sleep 3
	echo "********************************"
	echo "*** 5. Extraer nuevos bloques a esta dirección hasta obtener un saldo de billetera positivo. (utilizar generatetoaddress) (cuántos bloques se necesitaron para obtener un saldo positivo)"
	echo "********************************"
		cero=0 #Variable de referencia para comparar saldo
		rwbalance=$(bitcoin-cli -rpcwallet=Miner getbalance | bc) #saldo inicial en la wallet a decimal
		enterobalance=$(echo "($rwbalance + 0.5) / 1" | bc) #convertir el decimal a entero
		count=0 #contador para altura de bloque
		while [ $enterobalance -le $cero ]; do #mientras el balance sea 0, hacer...
			((count++))
			bitcoin-cli generatetoaddress 1 "$reward" #genera un bloque y lo envia a la direccion
			rwbalance=$(bitcoin-cli -rpcwallet=Miner getbalance | bc) 
			enterobalance=$(echo "($rwbalance + 0.5) / 1" | bc) 
			echo "Altura de bloque: $count Balance: $rwbalance"
		done
	echo "********************************"
	echo "*** 6. Escribir un breve comentario que describa por qué el saldo de la billetera para las recompensas en bloque se comporta de esa manera."
	echo "********************************"
		echo -e "$YELL Se necesitaron $count bloques para obtener un saldo positivo de $rwbalance, esto debido a que los bitcoins generados en una transacción Coinbase no se pueden gastar hasta que hayan pasado al menos 100 bloques adicionales en la cadena de bloques, para prevenir cualquier intento de doble gasto. $NC"
	echo "********************************"
	echo "*** 7. Imprimir el saldo de la billetera Miner."
	echo "********************************"
		echo -e "$YELL $rwbalance $NC"
sleep 5
}
uso () {
echo "********************************"
banner Uso
echo "********************************"
	echo "1. Crear una dirección receptora con la etiqueta "Recibido" desde la billetera Trader."
	echo "********************************"
		recibidoTrader=`bitcoin-cli -rpcwallet=Trader getnewaddress "Recibido"`
		echo -e "$YELL Nueva direccion en la cartera Trader: $recibidoTrader $NC"
	echo "********************************"
	echo "2. Enviar una transacción que pague 20 BTC desde la billetera Miner a la billetera del Trader."
	echo "********************************"
		txrecibidoTrader=`bitcoin-cli -rpcwallet=Miner sendtoaddress "$recibidoTrader" 20`
		echo -e "$YELL Id de transaccion: $txrecibidoTrader $NC"
	echo "********************************"
	echo "3. Obtener la transacción no confirmada desde el "mempool" del nodo y mostrar el resultado. (pista: bitcoin-cli help para encontrar la lista de todos los comandos, busca getmempoolentry)."
	echo "********************************"
		echo -e "$YELL Visualizando transaccion en el mempool $NC"
		bitcoin-cli getmempoolentry $txrecibidoTrader
	echo "********************************"
	echo "4. Confirmar la transacción creando 1 bloque adicional."
	echo "********************************"
		echo -e "$YELL Confirmando transaccion en nuevo bloque $NC" 
		bitcoin-cli generatetoaddress 1 "$reward"
		echo "Balance actual en wallet Trader"
	echo "********************************"
	echo "5. Obtener los siguientes detalles de la transacción y mostrarlos en la terminal:"
	echo "********************************"
		echo -e "txid: $YELL $txrecibidoTrader $NC"
		txgastada=`bitcoin-cli -rpcwallet=Trader getrawtransaction $txrecibidoTrader 1|jq -r '.vin[0].txid'`
		cantidadentrada=`bitcoin-cli -rpcwallet=Trader getrawtransaction $txgastada 1|jq -r '.vout[0].value'`
		direccionminer=`bitcoin-cli -rpcwallet=Trader getrawtransaction $txgastada 1|jq -r '.vout[0].scriptPubKey.address'`
		echo -e "<De, Cantidad>: $YELL $direccionminer, $cantidadentrada. $NC"
		cantidadenviada=`bitcoin-cli -rpcwallet=Trader getrawtransaction $txrecibidoTrader 1|jq -r '.vout[1].value'`
		echo -e "<Enviar, Cantidad>: $YELL $recibidoTrader, $cantidadenviada. $NC"
		cambiominer=`bitcoin-cli -rpcwallet=Trader getrawtransaction $txrecibidoTrader 1|jq -r '.vout[0].scriptPubKey.address'`
		cantidadcambio=`bitcoin-cli -rpcwallet=Trader getrawtransaction $txrecibidoTrader 1|jq -r '.vout[0].value'`
		echo -e "<Cambio, Cantidad>: $YELL $cambiominer, $cantidadcambio. $NC"
		comisiones=`echo $cantidadentrada - $cantidadenviada - $cantidadcambio | bc`
		echo -e "Comisiones: $YELL $comisiones. $NC"
		altura=`bitcoin-cli -rpcwallet=Trader gettransaction $txrecibidoTrader |jq .blockheight`
		echo -e "Bloque: $YELL $altura. $NC"
		saldominer=`bitcoin-cli -rpcwallet=Miner getbalance`
		echo -e "Saldo de Miner: $YELL $saldominer. $NC"
		saldotrader=`bitcoin-cli -rpcwallet=Trader getbalance`
		echo -e "Saldo de Trader: $YELL $saldotrader. $NC"
sleep 5
}
autor
limpieza
configuracion
inicio
uso
banner FIN
