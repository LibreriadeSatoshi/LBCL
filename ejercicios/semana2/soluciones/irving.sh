#!/bin/bash

#####5672I5976R3645V6548I5647N3297G
#######Basado en el script https://github.com/BlockchainCommons/Bitcoin-Standup-Scripts/blob/master/Scripts/StandUp.sh
#######Basado en el script de Iván https://github.com/LibreriadeSatoshi/LBCL/blob/main/ejercicios/semana1/soluciones/entreplanctonyballenas.sh
\e[33m
##########################################################################################################

############# AGRADECIMIENTO ESPECIAL A KASKAZ QUE ME AYUDÓ MUCHO!!! #####################################

##########################################################################################################

####Cerrar bitcoin por si acaso...

bitcoin-cli stop

echo -e "\e[31mCerrando Bitcoin Core para iniciar instalacion nueva, por favor espere... \e[0m"

sleep 7

sudo rm -r ~/.bitcoin

####CONFIGURACION

echo -e "\e[36m¿Que versión de bitcoin quieres instalar?[22.0, 22.1, 23.0, 23.1, 23.2, 24.0.1, 24.1, 24.2, 25.0, 25.1]\e[0m"

read version

#####Instalar paquetes recomendados

sudo apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd

#####1.Descargar los binarios principales de Bitcoin desde el sitio web de Bitcoin Core https://bitcoincore.org/.
#####Descargar Bitcoin-core

echo -e "\e[34m$0 - Descargando Bitcoin\e[0m"

mkdir btctemp

cd btctemp

BITCOIN="bitcoin-core-$version"
BITCOINVER=`echo $BITCOIN | sed 's/bitcoin-core/bitcoin/'`

wget https://bitcoincore.org/bin/$BITCOIN/$BITCOINVER-x86_64-linux-gnu.tar.gz
wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS.asc
wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS

#####2. Utilizar los hashes y la firma descargados para verificar que los binarios sean correctos. Imprimir un mensaje en la terminal: "Verificación exitosa de la firma binaria".
#####Verificacion de archivos

gpg --keyserver hkps://keys.openpgp.org --refresh-keys 

git clone https://github.com/bitcoin-core/guix.sigs
gpg --import guix.sigs/builder-keys/*

echo -e "\e[34m$0 - Verificando Bitcoin.\e[0m"

export SHASIG=`gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep "Firma correcta"`
export SHACOUNT=`gpg --verify SHA256SUMS.asc SHA256SUMS	2>&1 | grep "Firma correcta" | wc -l`

if [[ "$SHASIG" ]]
then

    echo -e "\e[32m$0 - VERIFICACION DE FIRMA EXITOSA: $SHACOUNT FIRMA CORRECTA ENCONTRADA\e[0m"
    echo "$SHASIG"

else

	(>&2 echo -e "\e[31m$0 - ERROR EN VERIFICACION DE FIRMAS: No hay firmas verificadas para Bitcoin!\e[0m")

fi

#####Verificacion Bitcoin: SHA

SHACHECK=`sha256sum --ignore-missing --check SHA256SUMS 2>&1 | grep "La suma coincide"`

if [ "$SHACHECK" ]
then

   echo -e "\e[32m$0 - VERIFIACION SHA EXITOSA / SHA: $SHACHECK\e[0m"

else

    (>&2 echo -e "\e[31m$0 - ERROR EN VERIFICACION SHA: SHA para Bitcoin no coincidió!\e[0m")

fi

while true; do

  echo -e "\e[34mConfirma que ambas verificaciones fueron correctas, ¿Deseas continuar?\e[0m"

  read -p "[si/no]" opcion

  case "$opcion" in

    no)

 echo -e "\e[31m$0 Cancelado, verifique las firmas, ¡algo anda mal!\e[0m"

cd .. 

sudo rm -rf btctemp


exit 1

break
      ;;

    si)

break

      ;;

    *)

      echo -e "\e[34mOpción no válida. Por favor, selecciona una opción válida [si/no].\e[0m"

      ;;

  esac
  
done

#####3. Copiar los binarios descargados a la carpeta /usr/local/bin/.
#####Eliminando y copiando archivos

echo -e "\e[34m$0 - Instalando Bitcoin.\e[0m"

tar xzf ./$BITCOINVER-x86_64-linux-gnu.tar.gz

sudo cp -r ./$BITCOINVER/bin/* /usr/local/bin/

cd .. 

sudo rm -rf btctemp

cd /home/$USER

#####INICIO
#####1.Crear un archivo bitcoin.conf en el directorio de datos /home/<nombre-de-usuario>/.bitcoin/. Crear el directorio si no existe. Y agregar las siguientes líneas al archivo:

carpeta=.bitcoin

if [ ! -d "$carpeta" ] 
then

mkdir "$carpeta"

echo ""

else

echo ""
fi

cd /home/$USER/$carpeta

touch bitcoin.conf

while true; do
  echo -e "\e[36mElija el tipo de nodo:\e[0m"
  echo "1 - Mainnet"
  echo "2 - Testnet"
  echo "3 - Regtest (unico disponible por lo pronto...)"
  echo "4 - Salir"
  
  read -p "Selecciona una opción (1-4): " nodo

  case "$nodo" in
    1)
     echo -e "\e[36mCreando bitcoin.conf para Mainnet...\e[0m"

cat > bitcoin.conf <<EOF

#server=1
#txindex=1
#daemon=1
#pruned=0
#rpcport=8332
#rpcbind=0.0.0.0
#rpcallowip=127.0.0.1
#rpcallowip=10.0.0.0/8
#rpcallowip=172.0.0.0/8
#rpcallowip=192.0.0.0/8
#zmqpubrawblock=tcp://0.0.0.0:28332
#zmqpubrawtx=tcp://0.0.0.0:28333
#zmqpubhashblock=tcp://0.0.0.0:28334
#whitelist=127.0.0.1
#peerbloomfilters=1 

EOF

break
      ;;
    2)
      echo -e "\e[36mCreando bitcoin.conf para Testnet...\e[0m"

cat > bitcoin.conf << EOF

Testnet

EOF

break
      ;;
    3)
      echo -e "\e[36mCreando bitcoin.conf para Regtest...\e[0m"

cat > bitcoin.conf << EOF

regtest=1
fallbackfee=0.0001
server=1
txindex=1

EOF

break
      ;;
    4)
      echo "Saliendo... Vuelva a empezar."
      exit 1
      ;;
    *)
      echo "Opción no válida. Por favor, selecciona una opción válida (1-4)."
      ;;
  esac

done

echo -e "\e[33m********** CONFIGURACION **********\e[0m"
echo -e "\e[33mInicio, ejercicio 1 - Se descargaron los archivos desde el sitio de Bitcoin Core.\e[0m"
echo -e "\e[33mInicio, ejercicio 2 - Se verificaron exitosamente los binarios descargados\e[0m"
echo -e "\e[33mInicio, ejercicio 3 - Se copiaron los binarios en /usr/local/bin/.\e[0m"
echo -e "\e[35mContinua ejercicios de Inicio, espere unos segundos...\e[0m"


sleep 15

#####2. Iniciar bitcoind.

bitcoind -daemon
sleep 5

####3.Crear dos billeteras llamadas Miner y Trader.

bitcoin-cli createwallet "Miner"
bitcoin-cli createwallet "Trader"

sleep 5

####4.Generar una dirección desde la billetera Miner con una etiqueta "Recompensa de Minería".

ADDRESS=`bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa de Minería666"`

####5.Extraer nuevos bloques a esta dirección hasta obtener un saldo de billetera positivo. (utilizar generatetoaddress) (cuántos bloques se necesitaron para obtener un saldo positivo)

cero=0 

BALANCE=$(bitcoin-cli -rpcwallet=Miner getbalance | bc)

BALANCE_ENTERO=$(echo "($BALANCE + 0.5) / 1" | bc)

count=0

while [ $BALANCE_ENTERO -le $cero ]; do

((count++))

bitcoin-cli generatetoaddress 1 "$ADDRESS"

BALANCE=$(bitcoin-cli -rpcwallet=Miner getbalance | bc)
 
BALANCE_ENTERO=$(echo "($BALANCE + 0.5) / 1" | bc)
 

echo -e "\e[34m"Altura de bloque: $count Balance: $BALANCE"\e[0m"

done

echo -e "\e[33m********** INICIO **********\e[0m"
echo -e "\e[33mInicio, ejercicio 1 - Se creó bitcoin.conf con la configuración de Regtest.\e[0m"
echo -e "\e[33mInicio, ejercicio 2 - Se inició bitcoind\e[0m"
echo -e "\e[33mInicio, ejercicio 3 - Se creo wallet Miner y Trader.\e[0m"
echo -e "\e[33mInicio, ejercicio 4 - Direccion de "Recompensa de Mineria": $ADDRESS\e[0m"
echo -e "\e[33mInicio, ejercicio 5 - Se necesitaron $count bloques hasta obtener un saldo de billetera positivo.\e[0m"
echo -e "\e[33mInicio, ejercicio 6 - La razon es por que para evitar el doble gasto se requieren al menos 100 bloques minados.\e[0m"
echo -e "\e[33mInicio, ejercicio 7 - Saldo en la billetera Miner: $BALANCE\e[0m"
echo -e "\e[35mContinua ejercicios de Uso, espere unos segundos...\e[0m"

sleep 15

#####1.Crear una dirección receptora con la etiqueta "Recibido" desde la billetera Trader.

RECIBIDOADDRESS=`bitcoin-cli -rpcwallet=Trader getnewaddress "Recibido"`

#####2.Enviar una transacción que pague 20 BTC desde la billetera Miner a la billetera del Trader.

TXRECIBIDO=`bitcoin-cli -rpcwallet=Miner sendtoaddress $RECIBIDOADDRESS 20`

#####3.Obtener la transacción no confirmada desde el "mempool" del nodo y mostrar el resultado. (pista: bitcoin-cli help para encontrar la lista de todos los comandos, busca getmempoolentry).

MEMPOOL=`bitcoin-cli getmempoolentry $TXRECIBIDO`

#####4.Confirmar la transacción creando 1 bloque adicional.

NEWBLOQUE=`bitcoin-cli generatetoaddress 1 "$ADDRESS"`

#####5.Obtener los siguientes detalles de la transacción y mostrarlos en la terminal:

echo -e "\e[33m********** USO **********\e[0m"
echo -e "\e[33mInicio, ejercicio 1 - Direccion de "Recibido": $RECIBIDOADDRESS\e[0m"
echo -e "\e[33mInicio, ejercicio 2 - Se enviaron 20 BTC a $RECIBIDOADDRESS, id de transaccion: $TXRECIBIDO\e[0m"
echo -e "\e[33mInicio, ejercicio 3 - \e[0m"
echo -e "$MEMPOOL"
echo -e "\e[33mInicio, ejercicio 4 - Creado 1 bloque adicional para confirmación.\e[0m"
echo -e "\e[33mInicio, ejercicio 5 - \e[0m"
echo -e ""

echo -e "txid: $TXRECIBIDO"
txgastada=`bitcoin-cli -rpcwallet=Trader getrawtransaction $TXRECIBIDO 1|jq -r '.vin[0].txid'`
cantidadentrada=`bitcoin-cli -rpcwallet=Trader getrawtransaction $txgastada 1|jq -r '.vout[0].value'`
direccionminer=`bitcoin-cli -rpcwallet=Trader getrawtransaction $txgastada 1|jq -r '.vout[0].scriptPubKey.address'`
echo -e "<De, Cantidad>: $direccionminer, $cantidadentrada."
cantidadenviada=`bitcoin-cli -rpcwallet=Trader getrawtransaction $TXRECIBIDO 1|jq -r '.vout[1].value'`
echo -e "<Enviar, Cantidad>: $RECIBIDOADDRESS, $cantidadenviada."
cambiominer=`bitcoin-cli -rpcwallet=Trader getrawtransaction $TXRECIBIDO 1|jq -r '.vout[0].scriptPubKey.address'`
cantidadcambio=`bitcoin-cli -rpcwallet=Trader getrawtransaction $TXRECIBIDO 1|jq -r '.vout[0].value'`
echo -e "<Cambio, Cantidad>: $cambiominer, $cantidadcambio."
comisiones=`echo $cantidadentrada - $cantidadenviada - $cantidadcambio | bc`
echo -e "Comisiones: $comisiones."
altura=`bitcoin-cli -rpcwallet=Trader gettransaction $TXRECIBIDO |jq .blockheight`
echo -e "Bloque: $altura."
saldominer=`bitcoin-cli -rpcwallet=Miner getbalance`
echo -e "Saldo de Miner: $saldominer."
saldotrader=`bitcoin-cli -rpcwallet=Trader getbalance`
echo -e "Saldo de Trader: $saldotrader."

#########################################################################################################################
#########################################################################################################################
#########################################################################################################################
#########################################################################################################################


####SEMANA 2

echo -e "\e[35m**************************************************************************************************\e[0m"
echo -e "\e[35m**************************************************************************************************\e[0m"
echo -e "\e[35m**************************************************************************************************\e[0m"
echo -e "\e[35m*************************************** INICIO SEMANA 2 ******************************************\e[0m"

#sleep 7

####1.Crear dos billeteras llamadas Miner y Trader.

echo -e "\e[36m1.Crear dos billeteras llamadas Miner y Trader.\e[0m"
echo -e "\e[36mSe crearon en la semana 1 con:\e[0m"
echo -e "bitcoin-cli createwallet "Miner""
echo -e "bitcoin-cli createwallet "Trader""
echo ""

sleep 6

####2.Fondear la billetera Miner con al menos el equivalente a 3 recompensas en bloque en satoshis (Saldo inicial: 150 BTC).

echo -e "\e[36m2.Fondeando billetera Miner con al menos 150 BTC...\e[0m"

FONDEADO=`bitcoin-cli generatetoaddress 2 $ADDRESS`

SALDO2=`bitcoin-cli -rpcwallet=Miner getbalance`

echo -e "\e[33mSaldo en billetera Miner despues de fondeado:\e[0m $SALDO2 BTC"
echo ""

sleep 6

####3.Crear una transacción desde Miner a Trader con la siguiente estructura (llamémosla la transacción parent):

#####Entrada[0]: Recompensa en bloque de 50 BTC.

utxo_txid0=`bitcoin-cli -rpcwallet=Miner listunspent | jq -r '. [1] | .txid'`
utxo_vout0=`bitcoin-cli -rpcwallet=Miner listunspent | jq -r '. [1] | .vout'`
utxo_amount0=`bitcoin-cli -rpcwallet=Miner listunspent | jq -r '. [1] | .amount'`

echo -e "\e[36m3.Creando transaccion de Miner a Trader...\e[0m"

sleep 4

echo -e "\e[33mEntrada[0]:\e[0m Recompensa en bloque de 50 BTC."
echo -e "\e[33mtxid [0]:\e[0m $utxo_txid0"
#echo -e "\e[33mvout [0]:\e[0m $utxo_vout0"
echo -e "\e[33mamount [0]:\e[0m $utxo_amount0"


#####Entrada[1]: Recompensa en bloque de 50 BTC.

utxo_txid1=`bitcoin-cli -rpcwallet=Miner listunspent | jq -r '. [2] | .txid'`
utxo_vout1=`bitcoin-cli -rpcwallet=Miner listunspent | jq -r '. [2] | .vout'`
utxo_amount1=`bitcoin-cli -rpcwallet=Miner listunspent | jq -r '. [2] | .amount'`


echo -e "\e[33mEntrada[1]:\e[0m Recompensa en bloque de 50 BTC."
echo -e "\e[33mtxid [1]:\e[0m $utxo_txid1"
#echo -e "\e[33mvout [1]:\e[0m $utxo_vout1"
echo -e "\e[33mamount [1]:\e[0m $utxo_amount1"

####Salida[0]: 70 BTC para Trader.

recipient=`bitcoin-cli -rpcwallet=Trader getnewaddress`
echo -e "\e[33mSalida[0]:\e[0m 70 BTC Trader."
echo -e "\e[33mDireccion para envio a Trader:\e[0m $recipient"

####Salida[1]: 29.99999 BTC de cambio para Miner.

changeaddress=`bitcoin-cli -rpcwallet=Miner getnewaddress`
echo -e "\e[33mSalida[1]:\e[0m 29.99999 BTC de cambio para Miner."
echo -e "\e[33mDireccion de salida a cambio:\e[0m $changeaddress"

sleep 5

####Activar RBF (Habilitar RBF para la transacción).

rawtxhex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$utxo_txid0'", "vout": '${utxo_vout0}', "sequence": 1 }, { "txid": "'$utxo_txid1'", "vout": '${utxo_vout1}', "sequence": 1 }  ]''' outputs='''[ { "'$recipient'": 70 }, { "'$changeaddress'": 29.99999 }] ''')

echo -e "\e[35mActivando RBF con Sequence: 1\e[0m"

####4.Firmar y transmitir la transacción parent, pero no la confirmes aún.

signedtx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
txparent=`bitcoin-cli -rpcwallet=Miner sendrawtransaction $signedtx`

#bitcoin-cli -rpcwallet=Miner gettransaction "$txparent"

echo -e "\e[36m4.Firmando y transmitiendo transaccion:\e[0m $txparent"

sleep 5

####5.Realizar consultas al "mempool" del nodo para obtener los detalles de la transacción parent. Utiliza los detalles para crear una variable JSON con la siguiente estructura:

echo -e "\e[36m5.Realizando consulta en mempool para transaccion parent y mostrando:...\e[0m"

sleep 5

input0=$(bitcoin-cli decoderawtransaction $signedtx | jq -r '.vin[0] | { txid: .txid, vout: .vout }')
input1=$(bitcoin-cli decoderawtransaction $signedtx | jq -r '.vin[1] | { txid: .txid, vout: .vout }')
output0=$(bitcoin-cli decoderawtransaction $signedtx | jq -r '.vout[0] | { script_pubkey: .scriptPubKey , amount: .value }')
output1=$(bitcoin-cli decoderawtransaction $signedtx | jq -r '.vout[1] | { script_pubkey: .scriptPubKey , amount: .value }')
txfee=$(bitcoin-cli getmempoolentry $txparent | jq -r '.fees .base')
txweight=$(bitcoin-cli getmempoolentry $txparent | jq -r .weight)
json='{ "input": [ '$input0', '$input1' ], "output": [ '$output0', '$output1' ], "Fees": '$txfee', "Weight": '$txweight' }'

####6.Imprime el JSON anterior en la terminal.>

echo -e "\e[36m6.Mostrando JSON:...\e[0m"

sleep 3

echo $json |jq

sleep 5

####7.Crea una nueva transmisión que gaste la transacción anterior (parent). Llamémosla transacción child. 

echo -e "\e[36m7.Creando transmision de parent a child\e[0m"


echo -e "\e[33mEntrada[0]: Salida de Miner de la transacción parent.\e[0m"
echo -e "\e[33mSalida[0]: Nueva dirección de Miner. 29.99998 BTC.\e[0m"


adchild=`bitcoin-cli -rpcwallet=Miner getnewaddress`

echo -e "\e[33mDireccion child:\e[0m $adchild"


txchild=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txparent'", "vout": 1} ]''' outputs='''[ { "'$adchild'": 29.99998 } ]''')

firmachild=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $txchild|jq -r .hex)

txidchild=$(bitcoin-cli sendrawtransaction $firmachild)

decodechild=`bitcoin-cli decoderawtransaction $firmachild |jq`

echo -e "\e[33mTransaccion child:\e[0m $txidchild"

sleep 5

####8.Realiza una consulta getmempoolentry para la tranasacción child y muestra la salida.

echo -e "\e[36m8.Consulta en mempool la transaccion child\e[0m"

sleep 3

bitcoin-cli getrawmempool |jq

bitcoin-cli getmempoolentry $txidchild |jq

sleep 5

#####9.Ahora, aumenta la tarifa de la transacción parent utilizando RBF. No uses bitcoin-cli bumpfee, en su lugar, crea manualmente una transacción conflictiva que tenga las mismas entradas que la transacción parent pero salidas diferentes, ajustando sus valores para aumentar la tarifa de la transacción parent en 10,000 satoshis.

echo -e "\e[36m9.Aumentando tarifa...\e[0m"

sleep 5

rbftxparent=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'${utxo_txid0}'", "vout": '${utxo_vout0}', "sequence": 1 }, { "txid": "'${utxo_txid1}'", "vout": '$utxo_vout1', "sequence": 1 } ]''' outputs='''[ { "'$recipient'": 70 }, { "'$changeaddress'": 29.99989000 } ]''')

bitcoin-cli decoderawtransaction $rbftxparent| jq -r '.vout | .[]'


####10.Firma y transmite la nueva transacción principal.

echo -e "\e[36m10.Firmando y transmitiendo la nueva transaccion.\e[0m"

sleep 3

firmaparent=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rbftxparent|jq -r .hex)

txidparent=$(bitcoin-cli sendrawtransaction $firmaparent)

####11.Realiza otra consulta getmempoolentry para la transacción child y muestra el resultado.

echo -e "\e[36m11.Consulta en mempool la transaccion child\e[0m"

sleep 3

bitcoin-cli getrawmempool |jq

bitcoin-cli getmempoolentry $txidchid |jq

sleep 5

####12.Imprime una explicación en la terminal de lo que cambió en los dos resultados de getmempoolentry para las transacciones child y por qué.

echo -e "\e[36m12.Imprime una explicación en la terminal de lo que cambió en los dos resultados de getmempoolentry para las transacciones child y por qué.\e[0m"
echo ""
echo -e "\e[33mOriginalmente se creo una transaccion child relacionada a una transaccion parent pero despues se le hizo un RBF a la transaccion parent haciedon que se creara una nueva parent a la que el child inicial no estaba relacionada por lo tanto esa operacion child quedo fuera de la ecuacion y por eso marca error por que ya no "existe".\e[0m"

sleep 5

echo -e ""
echo -e "\e[35mFinalizando... :)\e[0m"
echo -e ""
