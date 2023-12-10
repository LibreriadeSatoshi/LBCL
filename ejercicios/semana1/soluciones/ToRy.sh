#!/bin/bash 
#Shell Instalacion de Bitcoin Core 25.0 -Regtest + Minado.
#By: ToRy "☯The Purpple⚡ 🥷🏻ＮＩＮＪΛ🥷"

#Colores
endColour="\033[0m\e[0m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
redColour="\e[0;31m\033[1m"


echo            ACTUALIZAR MAQUINA:
      

echo            INSTALACION DE PAQUETES:
	
 		apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd
	
	
                wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-x86_64-linux-gnu.tar.gz
		

echo          FIRMAS Y VERIFICACION
	
		wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS
		wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS.asc
		sha256sum --ignore-missing --check SHA256SUMS
		echo -e "$YELL Verificación exitosa del checksum de los archivos $NC"
	
		git clone https://github.com/bitcoin-core/guix.sigs
		gpg --import guix.sigs/builder-keys/*
		gpg --verify SHA256SUMS.asc
		echo -e "$YELL Verificación exitosa de la firma binaria $NC"
		

echo           COPIA DE BINARIOS /usr/local/bin/."
 
		tar -xvf bitcoin-25.0-x86_64-linux-gnu.tar.gz
		sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-25.0/bin/*
		#rm -r $HOME/bitcoin*
		#rm $HOME/SHA256SUMS*
		#rm -r $HOME/guix.sigs


echo           CREAR ARCHIVO bitcoin.conf  /home/<nombre-de-usuario>/.bitcoin/. 
 
		mkdir $HOME/.bitcoin
		touch $HOME/.bitcoin/bitcoin.conf
                
		echo "regtest=1" 
		echo "fallbackfee=0.0001" 
		echo "server=1" 
		echo "txindex=1" 
	       
echo         GUARDAR ARCHIVO 


echo         INICIAR BITCOIND.... ;)   
	        
              bitcoind -regtest -daemon 
	      #bitcoind -regtest -daemon -fallbackfee=1.0 -maxtxfee=1.1
              #bitcoind >/dev/null &
        

echo          COMPROBAR ACTIVIDAD RED:
              :~/bitcoin-25.0$ bitcoin-cli -regtest getnetworkinfo
echo          #aqui veremos si estamos conectados correctamente

echo          VERIFICAR SI HAY WALLETS CREADAS:
              :~/bitcoin-25.0$ bitcoin-cli -regtest listwallets

	       
echo          #si no hemos manipulado antes, estara vacio!

echo          CREANDO NUEVA WALLET "Miners":   
              :~/bitcoin-25.0$ bitcoin-cli -regtest -named createwallet wallet_name="Miners"

	
echo         #aqui creamos nuestra primera wallet
    

echo         CREANDO NUEVA WALLET "Traders":   
              :~/bitcoin-25.0$ bitcoin-cli -regtest -named createwallet wallet_name="Traders"

	   
echo         #aqui creamos nuestra segunda wallet
    
echo         CREANDO DIRECCION PARA RECEPCION: 
             :~/bitcoin-25.0$ bitcoin-cli -regtest -rpcwallet=Miners getnewaddress "Recompensa de Minería"
echo         #nuestra primera direccion de recepcion!

echo         COMPROBANDO WALLETS CREADAS:
echo         :~/bitcoin-25.0$ bitcoin-cli -regtest listwallets
             
echo         #efectivamente vemos nuestras wallets


echo         MINANDO NUESTRO PRIMER BLOQUE:
             :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Miners" -generate 101
echo         #¡aqui veremos nuestros primeros bloques,ademas anexamo la wallet de recepcion "Miners"!!! ;)


echo         VERIFICANDO RECEPCION COINBASE:
             :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Miners" getbalance  
echo         #veremos la recompensa minera depositada en la wallet!


echo         CRENADO DIRECCION DE RECEPCION WALLET Traders
             :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet=Traders getnewaddress "Recibido"
             #veremos nuestra nueva direccion!


echo         ENVIO ENTRE WALLETS Miners to --- Traders:
             :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet=Miners sendtoaddress  "agregar  direcion (Recibido)" "!agregar valor"
echo         #aqui se genera No. identifica la transaccion TXID


echo         VERIFICANDO NUEVO SALDO EN LA WALLET Miners:
             :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Miners" getbalance
echo         #de ir por buen camino, nuestro saldo en la wallet Miners se reduce...



echo         VERIFICANDO NUEVO SALDO EN LA WALLET Traders:
             :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Traders" getbalance
echo         #0.00000000  oh oh! sin saldo! normal ;) ahora la transaccion esta en la mempool... 

echo         COMPROBANDO LA MEMPOOL:
             :~/.bitcoin/regtest$ bitcoin-cli -regtest  getmempoolentry "#TXID de envio "
echo         #veremos toda la informacion relacionada a TXID y su estado por confirmar...


echo         GENERENDO UN NUEVO BLOQUE:
             :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Miners" -generate 1
echo         #veremos un bloque mas minado, esto nos ayudara a confirmar la transaccion anterior.


             :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Miners" getbalance
echo        #nuevo balance depositado en la wallet "Miners"


echo        CONFIRMADO TXID CON NUEVO BALANCE:
            :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Traders" getbalance
echo        #al minarse un nuevo bloque, la direcion nos muestra nuevo Balance...
            finamenlte recibimos el valor, y la blockchain funciona ¡Eureka!


echo        INFORMACION DE TRANSACCIONES:
            :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Miners" gettransaction "TXID"
echo        #obtendremos detalle, de la transaccion como: "amount" "fee" "confirmations"
            "blockhash" "blockheight"


echo        GENERANDO 6 BLOQUE +
            :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Miners" -generate 6
echo        #de esta manera la primera transaccion ya sera irreversible!


echo       REVISANDO BALANCES:
           :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Miners" getbalance
echo       #nuevo valor a + bloques minados mayor recompensa minera depositada.

echo     
           :~/.bitcoin/regtest$ bitcoin-cli -regtest -rpcwallet="Traders" getbalancel 
echo       #el valor continua OK!


echo       VERIFICANDO WALLETS:
           :~/.bitcoin/regtest$ bitcoin-cli -regtest listwallets
           [
           "Miners",
           "Traders",
echo       #finalmente, logramos minar bloques y transferir valor!!!


           :~/bitcoin-25.0$ bitcoin-cli -regtest stop
echo       Bitcoin Core stopping

 

Fin...
