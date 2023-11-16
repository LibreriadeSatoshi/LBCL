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
}	
semana1 () {
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

semana2 () {
	echo "********************************"
	banner semana2
	echo "********************************"

	echo "********************************"
	echo "1. Crear dos billeteras llamadas Miner y Trader."
	echo "********************************"
		bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
		bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true

	echo "********************************"
	echo "2. Fondear la billetera Miner con al menos el equivalente a 3 recompensas en bloque en satoshis (Saldo inicial: 150 BTC)."
	echo "********************************"
		saldoinicial=`bitcoin-cli -rpcwallet=Miner getnewaddress "Saldo inicial"`
		echo -e "Nueva direccion en la cartera Miner: $YELL $saldoinicial $NC"
		bitcoin-cli generatetoaddress 103 "$saldoinicial"
		saldominer=`bitcoin-cli -rpcwallet=Miner getbalance`
		echo -e "Saldo inicial en la cartera Miner: $YELL $saldominer $NC"


	echo "********************************"
	echo "3. Crear una transacción desde Miner a Trader con la siguiente estructura (llamémosla la transacción parent):"
	echo "********************************"
		echo "Entrada[0]: Recompensa en bloque de 50 BTC."
		txidminer=($(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[] | .txid')) # obtenemos todos los txid en un arreglo
		voutminer=($(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[] | .vout')) # obtenemos todos los vouts en un arreglo
		echo -e "$YELL ${txidminer[0]} $NC"
		echo -e "$YELL ${voutminer[0]} $NC"
		echo "Entrada[1]: Recompensa en bloque de 50 BTC."
		echo -e "$YELL ${txidminer[1]} $NC"
		echo -e "$YELL ${voutminer[1]} $NC"
		echo "Salida[0]: 70 BTC para Trader."
		fondeotrader=`bitcoin-cli -rpcwallet=Trader getnewaddress "Fondeo Trader"`
		echo -e "Nueva direccion en la cartera Trader: $YELL $fondeotrader $NC"
		depositotrader=70.00000000
		echo -e "$YELL ${depositotrader[0]} $NC"
		echo "Salida[1]: 29.99999 BTC de cambio para Miner."		
		cambiominer=`bitcoin-cli -rpcwallet=Miner getnewaddress "Cambio Miner"`
		echo -e "Nueva direccion en la cartera Miner: $YELL $cambiominer $NC"
		cambio=29.99999
		echo -e "$YELL ${cambio[0]} $NC"
		echo "Activar RBF (Habilitar RBF para la transacción)."
		# RBF se activa al cambiar "sequence: 1"
        txparent=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'${txidminer[0]}'", "vout": '${voutminer[0]}', "sequence": 1 }, { "txid": "'${txidminer[1]}'", "vout": '${voutminer[1]}', "sequence": 1 } ]''' outputs='''[ { "'$fondeotrader'": '$depositotrader' }, { "'$cambiominer'": '$cambio' } ]''')
        echo -e "Transaccion en crudo: $YELL $txparent $NC"
        bitcoin-cli decoderawtransaction $txparent| jq -r '.vin | .[]'

	echo "********************************"
	echo "4. Firmar y transmitir la transacción parent, pero no la confirmes aún."
	echo "********************************"
		txparentfirmada=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $txparent|jq -r .hex)
		txidparent=$(bitcoin-cli sendrawtransaction $txparentfirmada)
		echo -e "ID de transaccion parent: $YELL $txidparent $NC"
	echo "********************************"
	echo "5. Realizar consultas al "mempool" del nodo para obtener los detalles de la transacción parent. Utiliza los detalles para crear una variable JSON con la siguiente estructura:"
	echo "********************************"
		input0=$(bitcoin-cli decoderawtransaction $txparentfirmada | jq -r '.vin[0] | { txid: .txid, vout: .vout }')
		input1=$(bitcoin-cli decoderawtransaction $txparentfirmada | jq -r '.vin[1] | { txid: .txid, vout: .vout }')
		output0=$(bitcoin-cli decoderawtransaction $txparentfirmada | jq -r '.vout[0] | { script_pubkey: .scriptPubKey , amount: .value }')
		output1=$(bitcoin-cli decoderawtransaction $txparentfirmada | jq -r '.vout[1] | { script_pubkey: .scriptPubKey , amount: .value }')
		txfee=$(bitcoin-cli getmempoolentry $txidparent | jq -r '.fees .base')
		txweight=$(bitcoin-cli getmempoolentry $txidparent | jq -r .weight)
		json='{ "input": [ '$input0', '$input1' ], "output": [ '$output0', '$output1' ], "Fees": '$txfee', "Weight": '$txweight' }'
	echo "********************************"
	echo "6. Imprime el JSON anterior en la terminal."
	echo "********************************"
		echo $json |jq
		
	echo "********************************"
	echo "7. Crea una nueva transaccion que gaste la transacción anterior (parent). Llamémosla transacción child."
	echo "********************************"
	echo "Entrada[0]: Salida de Miner de la transacción parent."
	echo "Salida[0]: Nueva dirección de Miner. 29.99998 BTC."
		childminer=`bitcoin-cli -rpcwallet=Miner getnewaddress "Deposito Child"`
        txchild=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txidparent'", "vout": 1} ]''' outputs='''[ { "'$childminer'": 29.99998 } ]''')
		txchildfirmada=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $txchild|jq -r .hex)
		txidchild=$(bitcoin-cli sendrawtransaction $txchildfirmada)
		echo -e "ID de transaccion child: $YELL $txidchild $NC"
		bitcoin-cli decoderawtransaction $txchildfirmada |jq
	echo "********************************"
	echo "8. Realiza una consulta getmempoolentry para la tranasacción child y muestra la salida."
	echo "********************************"
		echo "bitcoin-cli getrawmempool"
		bitcoin-cli getrawmempool |jq
		echo -e "bitcoin-cli getmempoolentry $YELL $txidchild $NC"
		bitcoin-cli getmempoolentry $txidchild |jq
	echo "********************************"
	echo "9. Ahora, aumenta la tarifa de la transacción parent utilizando RBF. No uses bitcoin-cli bumpfee, en su lugar, "
	echo "crea manualmente una transacción conflictiva que tenga las mismas entradas que la transacción parent pero salidas diferentes, ajustando sus valores para aumentar la tarifa de la transacción parent en 10,000 satoshis."
	echo "********************************"
		rbfcambio=$(echo "29.99999 - 0.00010000"|bc)
		echo -e "Nuevo cambio para Miner (despues de RBF): $YELL $rbfcambio $NC"
        txparentrbf=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'${txidminer[0]}'", "vout": '${voutminer[0]}', "sequence": 1 }, { "txid": "'${txidminer[1]}'", "vout": '${voutminer[1]}', "sequence": 1 } ]''' outputs='''[ { "'$fondeotrader'": '$depositotrader' }, { "'$cambiominer'": '$rbfcambio' } ]''')
        echo -e "Transaccion en crudo: $YELL $txparentrbf $NC"
        bitcoin-cli decoderawtransaction $txparentrbf| jq -r '.vout | .[]'
        
	echo "********************************"
	echo "10. Firma y transmite la nueva transacción principal."
	echo "********************************"
		txparentrbffirmada=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $txparentrbf|jq -r .hex)
		txidparentrbf=$(bitcoin-cli sendrawtransaction $txparentrbffirmada)
		echo -e "ID de transaccion parent: $YELL $txidparentrbf $NC"
	echo "********************************"
	echo "11. Realiza otra consulta getmempoolentry para la transacción child y muestra el resultado."
	echo "********************************"
		echo "bitcoin-cli getrawmempool"
		bitcoin-cli getrawmempool |jq
		echo -e "bitcoin-cli getmempoolentry $YELL $txidchild $NC"
		bitcoin-cli getmempoolentry $txidchild
	echo "********************************"
	echo "12. Imprime una explicación en la terminal de lo que cambió en los dos resultados de getmempoolentry para las transacciones child y por qué."
	echo "********************************"
		echo -e "Inicialmente el ID de la transacción PARENT era $YELL $txidparent $NC. Al crear una nueva transacción PARENT que gasta los mismos UTXO pero con un fee superior esto invalida el PARENT original y se calcula el HASH de la transacción nueva y este cambia completamente su TXID a $YELL $txidparentrbf $NC."
		echo -e "Por lo tanto la transacción CHILD ya no puede apuntar al PARENT con el que fue creada y el TXID de CHILD $YELL $txidchild $NC es ahora rechazado del mempool"
sleep 5
}

autor
limpieza
configuracion
inicio
#semana1
semana2


banner FIN
