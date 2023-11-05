#!/bin/bash
echo "Ejercicio 1 de Elgusx1"
sudo apt-get install -y bc jq 
echo "Descargamos los binarios ya compilados"
wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-x86_64-linux-gnu.tar.gz
echo "Se verifican que los vinarios sean correctos por medio de los hashes y firmas publicas"
wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS
wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS.asc
#sha256sum --ignore-missing --check SHA256SUMS
# Verificar los hashes SHA256 de los archivos descargados
if sha256sum --ignore-missing --check SHA256SUMS; then
  echo "Todos los hashes coinciden. Los archivos son auténticos."
else
  echo "Advertencia: Al menos un archivo tiene un hash que no coincide. No se pueden verificar todos los archivos."
fi
sleep 3
#Se comprueban las llaves publicas
git clone https://github.com/bitcoin-core/guix.sigs
gpg --import guix.sigs/builder-keys/*
gpg --verify SHA256SUMS.asc
sleep 3
echo "Extraemos los binarios"
tar -xvf bitcoin-25.0-x86_64-linux-gnu.tar.gz
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-25.0/bin/*
echo "Creamos el directorio bitcoin y el archivo bitcoin.cof con su configuracion"
mkdir $HOME/.bitcoin
cat <<EOF >/root/.bitcoin/bitcoin.conf
    regtest=1
    fallbackfee=0.0001
    server=1
    txindex=1
EOF
sleep 3
echo "Comenzamos bitcoin"
bitcoind -daemon
sleep 3
echo "Se crean las wallet Miner y Trader"
bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true
sleep 3
echo 'Se genera la dirección de la wallet Miner'
address_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa de Minería")
sleep 3

# Verificar si la dirección de la billetera Miner se generó correctamente
if [ -z "$address_miner" ]; then
  echo "La dirección de la billetera Miner no se pudo generar. Deteniendo el proceso."
  exit 1
fi
sleep 3
echo 'Generamos los bloques necesarios para tener un saldo positivo en Miner'
block_count=0
while true; do
  # Generar un bloque a la dirección de la billetera Miner
  bitcoin-cli generatetoaddress 1 "$address_miner"
  
  # Obtener el saldo de la billetera Miner
  balance=$(bitcoin-cli -rpcwallet=Miner getbalance)
  
  # Verificar si el saldo es positivo
  if (( $(echo "$balance > 0" | bc -l) )); then
    break
  fi
  
  ((block_count++))
done

echo "Se necesitaron $block_count bloques para obtener un saldo positivo en la billetera Miner."
sleep 2
final_balance=$(bitcoin-cli -rpcwallet=Miner getbalance)
echo "Saldo final de la billetera Miner: $final_balance"
sleep 2
echo "Generando una dirección con la etiqueta 'Recibido' desde la billetera Trader..."
address_trader=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Recibido")
sleep 2
echo "Enviando una transacción de 20 BTC de la billetera Miner a la billetera del Trader..."
 tx_Recive=$(bitcoin-cli -rpcwallet=Miner sendtoaddress "$address_trader" 20)
sleep 4
echo 'Transaccion en la mempool no confirmada'
bitcoin-cli getmempoolentry $tx_Recive
echo 'Se confirma la transaccion añadiendo un bloque'
bitcoin-cli generatetoaddress 1 "$address_miner"
sleep 2
txid=$tx_Recive

txgastada=$(bitcoin-cli -rpcwallet=Trader getrawtransaction $txid 1 | jq -r '.vin[0].txid')
cantidadentrada=$(bitcoin-cli -rpcwallet=Trader getrawtransaction $txgastada 1 | jq -r '.vout[0].value')
direccionminer=$(bitcoin-cli -rpcwallet=Trader getrawtransaction $txgastada 1 | jq -r '.vout[0].scriptPubKey.address')
cantidadenviada=$(bitcoin-cli -rpcwallet=Trader getrawtransaction $txid 1 | jq -r '.vout[1].value')
cambiominer=$(bitcoin-cli -rpcwallet=Trader getrawtransaction $txid 1 | jq -r '.vout[0].scriptPubKey.address')
cantidadcambio=$(bitcoin-cli -rpcwallet=Trader getrawtransaction $txid 1 | jq -r '.vout[0].value')
comisiones=$(echo "$cantidadentrada - $cantidadenviada - $cantidadcambio" | bc)
altura=$(bitcoin-cli -rpcwallet=Trader gettransaction $txid | jq -r '.blockheight')
saldominer=$(bitcoin-cli -rpcwallet=Miner getbalance)
saldotrader=$(bitcoin-cli -rpcwallet=Trader getbalance)


echo -e "<De, Cantidad>: $direccionminer, $cantidadentrada."
echo -e "<Enviar, Cantidad>: $address_trader, $cantidadenviada."
echo -e "<Cambio, Cantidad>: $cambiominer, $cantidadcambio."
echo -e "Comisiones: $comisiones."
echo -e "Saldo de Miner: $saldominer."
echo -e "Bloque: $altura."
echo -e "Saldo de Trader: $saldotrader."

