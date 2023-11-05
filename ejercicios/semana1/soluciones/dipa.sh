#!/bin/bash

### Variable Global ###
btr="bitcoin-cli -regtest"

### Configuración ###

#1)Descargar los binarios principales de Bitcoin desde el sitio web de Bitcoin Core https://bitcoincore.org/.

wget https://bitcoincore.org/bin/bitcoin-core-25.1/bitcoin-25.1-x86_64-linux-gnu.tar.gz . 
wget https://bitcoincore.org/bin/bitcoin-core-25.1/SHA256SUMS .


#2)Utilizar los hashes y la firma descargados para verificar que los binarios sean correctos. Imprimir un mensaje en la terminal: "Verificación exitosa de la firma binaria".

result=$(sha256sum --ignore-missing --check SHA256SUMS 2>&1)

# Comprueba si el resultado contiene la cadena "OK"

if [[ $result == *"OK"* ]]; then
    echo "Verificación exitosa de la firma binaria"
else
    echo "La verificación de la firma binaria ha fallado"
fi

#3)Copiar los binarios descargados a la carpeta /usr/local/bin/ 

## descomprimo el archivo
tar -xzf bitcoin-25.1-x86_64-linux-gnu.tar.gz
cp /home/dipa/test/bitcoin-25.1/bin/* /usr/local/bin/

### Inicio ###

##Crear un archivo bitcoin.conf en el directorio de datos /home/<nombre-de-usuario>/.bitcoin/. Crear el directorio si no existe. Y agregar las siguientes líneas al archivo:

mkdir -p "$HOME/.bitcoin"
cat >>  "$HOME/.bitcoin/bitcoin.conf" << EOF
regtest=1
fallbackfee=0.0001
server=1
txindex=1
EOF

sleep 3

##Iniciar bitcoind
bitcoind -daemon 2>&1

sleep 3

##Crear dos billeteras llamadas Miner y Trader.Generar una dirección desde la billetera Miner con una etiqueta "Recompensa de Minería".

$btr createwallet "Miner"
$btr createwallet "Trader" 

#Generar una dirección desde la billetera Miner con una etiqueta "Recompensa de Minería".
ADDRESS_MINERIA=$($btr -rpcwallet=Miner getnewaddress "Recompensa de Mineria") 


#Extraer nuevos bloques a esta dirección hasta obtener un saldo de billetera positivo. (utilizar generatetoaddress) (cuántos bloques se necesitaron para obtener un saldo positivo)

cero=0
saldo_actual=$($btr -rpcwallet=Miner getbalance | bc)
saldo_actual_round=$(echo "($saldo_actual + 0.5) / 1" | bc)
count=0

while [ $saldo_actual_round -le $cero ]; do 
	((count++))
	$btr -rpcwallet=Miner generatetoaddress 1 "$ADDRESS_MINERIA"
	saldo_actual=$($btr -rpcwallet=Miner getbalance) 
	saldo_actual_round=$(echo "($saldo_actual + 0.5) / 1" | bc) # me aseguro que haga el redondeo de manera adecuada
	echo "Altura de bloque: $count Balance: $saldo_actual_round"

done

sleep 5

#Escribir un breve comentario que describa por qué el saldo de la billetera para las recompensas en bloque se comporta de esa manera.
echo "Se requirieron 101 bloques para lograr un saldo positivo en la billetera "Miner". Esto se debe a que los bitcoins generados en una transacción Coinbase no pueden utilizarse hasta que hayan transcurrido al menos 100 bloques adicionales en la cadena de bloques. Esta medida se implementa con el fin de prevenir cualquier intento de doble gasto."

sleep 5

##Imprimir el saldo de la billetera Miner
echo $saldo_actual

## Crear una dirección receptora con la etiqueta "Recibido" desde la billetera Trader
ADDRESS_TRADER=$($btr -rpcwallet=Trader  getnewaddress "Recibido")

#Enviar una transacción que pague 20 BTC desde la billetera Miner a la billetera del Trader.
TXID_RECIBIDO=$($btr -rpcwallet=Miner sendtoaddress "$ADDRESS_TRADER" 20)


#Confirmar la transacción creando 1 bloque adicional
$btr generatetoaddress 1 "$ADDRESS_MINERIA" # aca sumo otros 50 btc

#5. Obtener los siguientes detalles de la transacción y mostrarlos en la terminal:

echo -e "txid: $TXID_RECIBIDO"
txgastada=$($btr -rpcwallet=Trader getrawtransaction $TXID_RECIBIDO 1|jq -r '.vin[0].txid')
cantidadentrada=$($btr -rpcwallet=Trader getrawtransaction $txgastada 1|jq -r '.vout[0].value')
direccionminer=$($btr -rpcwallet=Trader getrawtransaction $txgastada 1|jq -r '.vout[0].scriptPubKey.address')
echo -e "<De, Cantidad>: $direccionminer, $cantidadentrada"
cantidadenviada=$($btr -rpcwallet=Trader getrawtransaction $TXID_RECIBIDO 1|jq -r '.vout[1].value')
echo -e "<Enviar, Cantidad>: $ADDRESS_TRADER, $cantidadenviada"
cambiominer=$($btr -rpcwallet=Trader getrawtransaction $TXID_RECIBIDO 1|jq -r '.vout[0].scriptPubKey.address')
cantidadcambio=$($btr -rpcwallet=Trader getrawtransaction $TXID_RECIBIDO 1|jq -r '.vout[0].value')
echo -e "<Cambio, Cantidad>: $cambiominer, $cantidadcambio"
comisiones=$(echo $cantidadentrada - $cantidadenviada - $cantidadcambio | bc)
echo -e "Comisiones: $comisiones"
altura=$($btr -rpcwallet=Trader gettransaction $TXID_RECIBIDO |jq .blockheight)
echo -e "Bloque: $altura"
saldominer=$($btr -rpcwallet=Miner getbalance)
echo -e "Saldo de Miner: $saldominer"
saldotrader=$($btr -rpcwallet=Trader getbalance)
echo -e "Saldo de Trader: $saldotrader"
