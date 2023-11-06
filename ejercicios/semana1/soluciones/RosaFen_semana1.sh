#!/bin/bash
#
directorio=$(pwd)
#
# Bajar Bitcoin, hashes y firmas
sudo wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-x86_64-linux-gnu.tar.gz
sudo wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS.asc
sudo wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS
#
# Verificacion sumas y llaves
sha256sum --ignore-missing --check SHA256SUMS
sha256sum bitcoin-25.0-x86_64-linux-gnu.tar.gz
echo "Verificación exitosa de la firma binaria"
git clone https://github.com/bitcoin-core/guix.sigs
gpg --import guix.sigs/builder-keys/*
gpg --verify SHA256SUMS.asc # gpg --verify SHA256SUMS.asc bitcoin-25.0-x86_64-linux-gnu.tar.gz
echo -n "¿Firma correcta? ¿Continuar?(s/n)"
read -N 1 continuar
if [ $continuar = "n" ] ; then
    echo
    exit 1
fi
echo "continuamos"
#
#Mover binario
mv bitcoin-25.0-x86_64-linux-gnu.tar.gz /usr/local/bin
cd /usr/local/bin
#
#Instalar Bitcoin Core
tar xzf bitcoin-25.0-x86_64-linux-gnu.tar.gz
echo "Instalando Bitcoin Core 25.0 puede tomar unos minutos"
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-25.0/bin/*
#
#Crear archivo bitcoin.conf y definir parametros para que se ejecute en regtest
cd /home
cd ~/.bitcoin
cat >> bitcoin.conf << EOF
regtest=1
fallbackfee=0.0001
server=1
txindex=1
EOF
#
#Arrancar bitcoind
/usr/local/bin/bitcoind -daemon
echo "Bitcoind se está ejecutando en modo demonio"
echo -n "Puse una tecla para continuar"
read
#
#Crear billeteras
bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true #Revisar aqui que warinng está vacio
bitcoin-cli unloadwallet "Trader"
bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true #Revisar aqui que warning está vacio
#
#Generar direccion
Mineria=$(bitcoin-cli getnewaddress "Recompensa de Mineria" "bech32")
#
#Cuantos bloques se necesitan para obtener un saldo positivo
alturaini=$(bitcoin-cli getblockchaininfo | jq -r '.blocks')
bitcoin-cli generatetoaddress 105 $(Mineria) #Extraer nuevo bloques generatetoaddress "Recompensa de Mineria"
until { bitcoin-cli getbalance != 0} ; do
    sleep 5 #esperamos
done
alturafin=$(bitcoin-cli getblockchaininfo | jq -r '.blocks')
altura= $(alturafin) - $(alturaini)
echo "Ha tardado $altura bloques en obtener saldo positivo"
echo "La billetera obtiene un saldo positivo porque hay que esperar 100 bloques para poder gastar lo minado"
echo "Puse una techa para continuar"
read
#
#Saldo de la billetera Miner
echo "La billetera Miner tiene un balance de $(bitcoin-cli getbalance) BTC"
#
#Crear una direccion "Recibido" desde la billetera Trader
bitcoin-cli unloadwallet "Miner"
bitcoin-cli loadwallet "Trader"
Recibido=$(bitcoin-cli getnewaddress "Recibido" "bech32")
bitcoin-cli unloadwallet "Trader"
bitcoin-cli loadwallet "Miner"
#
#Enviar 20BTC desde Miner a Trader
Monto=$(bitcoin-cli listunspent | jq -r '.[0] | .amount') #Suponiendo que en la primera transaccion minada hay una recompensa de mas de 20BTC
Dedireccion=$(bitcoin-cli listunspent | jq -r '.[0] | .address')
MontoCambio=$(echo "($Monto - 20.001)" | bc) #Le quito los 20 y el pago del minero
#
#Supongamos que es un solo utxo de mas de 20BTC
Cambio=$(bitcoin-cli getnewaddress "Cambio" "bech32")
utxo0itxd=$(bitcoin-cli listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli listunspent | jq -r '.[0] | .vout')
rawtxhex=$(bitcoin-cli createrawtransaction '''[ { "txid": "'$utxo0itxd'", "vout": '$utxo0vout' } ]''' '''[{ "'$Recibido'": 20 },{ "'$Cambio'": '$MontoCambio' }]''') #La diferencia es del minero
firmadotx=$(bitcoin-cli signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
identtx=$(bitcoin-cli sendrawtransaction $firmadotx)
#
#Ver en la mempool
echo "Se ha transferido 20 BTC de la billetera Miner a la billetera Trader. A continuacion se muestran los datos de la transaccion en la mempool"
bitcoin-cli getmempoolentry $identtx
echo "Puse una techa para continuar"
read
#
#Minar un bloques
hashbloque=$(bitcoin-cli generatetoaddress 1 $(Mineria))
#
#Datos de la transaccion
fee=$(bitcoin-cli gettransaction $identtx | jq -r '.fee')
Adireccion=$(bitcoin-cli gettransaction $identtx | jq -r '.details[0].address')
Amonto=$(bitcoin-cli gettransaction $identtx | jq -r '.details[0].amount')
Cambiodireccion=$(bitcoin-cli gettransaction $identtx | jq -r '.details[1].address')
Cambiomonto=$(bitcoin-cli gettransaction $identtx | jq -r '.details[1].amount')
Nconf=$(bitcoin-cli gettransaction $identtx | jq -r '.confirmations')
Altura=$(bitcoin-cli gettransaction $identtx | jq -r '.blockheight')
echo "La transaccion se ha minado, a continuacion se muestran los datos de la transaccion en la blockchain"
echo "La identificacion de la transaccion es: $identtx"
echo "Se envio desde la direccion de Miner: $Dedireccion"
echo "La comision de la transaccion es: $fee"
echo -n "A la direccion: $Adireccion"
echo "por un monto de $Amonto"
echo -n "La direccion de cambio es $Cambiodireccion"
echo "por un monto de $Cambiomonto"
echo "El numero de confirmaciones es $Nconf"
echo "El numero de bloque de la transaccion es $Altura"
echo "La billetera Miner tiene un balance de $(bitcoin-cli getbalance) BTC"
bitcoin-cli unloadwallet "Miner"
bitcoin-cli loadwallet "Trader"
echo "La billetera Trader tiene un balance de $(bitcoin-cli getbalance) BTC"
echo -n "El programa ha finalizado, ¿Desea borrar los archivos de instalacion? (s/n)"
read -N 1 continuar
if [ $continuar = "s" ] ; then
    rm /usr/local/bin/bitcoin-25.0-x86_64-linux-gnu.tar.gz
    cd $directorio
    rm SHA256SUMS.asc
    rm SHA256SUMS
else
    cd $directorio #vuelvo al directorio donde empezó el script
fi
echo "Puse una techa para finalizar"
read
echo "Muchas gracias"
