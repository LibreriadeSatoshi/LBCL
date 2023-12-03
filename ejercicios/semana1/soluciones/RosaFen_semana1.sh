#!/bin/bash

# Bajar Bitcoin, hashes y firmas
echo
echo "Punto 1.1. Descargar los binarios"
wget https://bitcoincore.org/bin/bitcoin-core-25.1/bitcoin-25.1-x86_64-linux-gnu.tar.gz
wget https://bitcoincore.org/bin/bitcoin-core-25.1/SHA256SUMS.asc
wget https://bitcoincore.org/bin/bitcoin-core-25.1/SHA256SUMS

# Verificacion sumas y llaves
echo
echo "Punto 1.2. Verificar los binarios y mostrar mensaje por la terminal"
verificacion1=$(sha256sum --ignore-missing --check SHA256SUMS) #resultado dice bitcoin-25....OK
verificacion21=$(sha256sum bitcoin-25.1-x86_64-linux-gnu.tar.gz) #resultado es el shasum y bitcoin....gnu.tar.gz
verificacion22=$(cat SHA256SUMS | grep bitcoin-25.1-x86_64-linux-gnu.tar.gz) # 21 y 22 tienen que ser iguales
if [[ $verificacion1 == *"OK"* ]] ; then
    echo "----------------------------------------"
    echo "Verificacion exitosa de la firma binaria"
    echo "----------------------------------------"
else
    echo "Error en firma binaria"
fi
if [[ $verificacion21 == $verificacion22 ]] ; then
    echo "------------------------------"
    echo "Verificacion exitosa SHA256SUM"
    echo "------------------------------"
else
    echo "Error en SHA256SUM"
fi
git clone https://github.com/bitcoin-core/guix.sigs
gpg --import guix.sigs/builder-keys/*
# gpg --verify SHA256SUMS.asc | grep Good # gpg --verify SHA256SUMS.asc bitcoin-25.1-x86_64-linux-gnu.tar.gz
# if sha256sum --ignore-missing --check SHA256SUMS; then
verificacion3=$(gpg --verify SHA256SUMS.asc 2>&1 | grep "Good")
if [[ $verificacion3 == *"Good"* ]] ; then # if [[ -n $verificacion3 ]]; then
    echo "------------------------------------------"
    echo "Verificacion exitosa de las firmas con gpg"
    echo "------------------------------------------"
else
    echo "Error en firmas usando gpg"
fi

#Instalar Bitcoin Core
echo
echo "Punto 1.3. Copiar los binarios en la carpeta /usr/local/bin"
tar xzf bitcoin-25.1-x86_64-linux-gnu.tar.gz
echo "Instalando Bitcoin Core 25.1 puede tomar unos minutos"
install -m 0755 -o root -g root -t /usr/local/bin bitcoin-25.1/bin/*

#Crear archivo bitcoin.conf y definir parametros para que se ejecute en regtest
echo
echo "Punto 2.1. Crear archivo bitcoin.conf y agregar lo necesario para ejecutar en modo regtest"
mkdir ~/.bitcoin
cat >> ~/.bitcoin/bitcoin.conf << EOF
regtest=1
fallbackfee=0.0001
server=1
txindex=1
EOF

#Arrancar bitcoind
echo
echo "Punto 2.2. Iniciar bitcoind"
bitcoind -daemon
echo "Bitcoind se está ejecutando en modo demonio"
sleep 1

#Crear billeteras
echo
echo "Punto 2.3. Crear billeteras Miner y Trader"
bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true

#Generar direccion
echo
echo "Punto 2.4. Crear direccion desde Miner con etiqueta Recompensa de Mineria"
Mineria=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Mineria")
echo "Direccion mineria $Mineria"

#Cuantos bloques se necesitan para obtener un saldo positivo
echo
echo "Punto 2.5. Extraer bloques hasta que Miner tenga saldo positivo"
balance=0
until [ $balance -ge 1 ] ; do
    bitcoin-cli generatetoaddress 1 "$Mineria"
    p=$(bitcoin-cli -rpcwallet=Miner getbalance | bc)
    balance=${p%.*}
done
altura=$(bitcoin-cli getblockchaininfo | jq -r '.blocks')
echo
echo "Punto 2.6. Cuanto ha tardado en tener saldo y por que"
echo "Ha tardado $altura bloques en obtener saldo positivo"
echo "La billetera obtiene un saldo positivo porque hay que esperar 100 bloques para poder gastar lo minado"

#Saldo de la billetera Miner
echo
echo "Punto 2.7 Saldo de billetera Miner"
echo "La billetera Miner tiene un balance de $(bitcoin-cli -rpcwallet=Miner getbalance) BTC"

#Crear una direccion "Recibido" desde la billetera Trader
echo
echo "Punto 3.1. Crear direccion en Trader con la etiqueta Recibido"
Recibido=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Recibido")
echo "Direccion de Trader $Recibido"

#Enviar 20BTC desde Miner a Trader
echo
echo "Punto 3.2. Enviar 20BTC de Miner a Trader"
Monto=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .amount') #Suponiendo que en la primera transaccion minada hay una recompensa de mas de 20BTC
Dedireccion=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .address')
MontoCambio=$(echo "($Monto - 20.001)" | bc) #Le quito los 20 y el pago del minero

#Supongamos que es un solo utxo de mas de 20BTC
Cambio=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Cambio")
utxo0itxd=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .txid')
utxo0vout=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | .vout')
rawtxhex=$(bitcoin-cli -rpcwallet=Miner createrawtransaction '''[ { "txid": "'$utxo0itxd'", "vout": '$utxo0vout' } ]''' '''[{ "'$Recibido'": 20 },{ "'$Cambio'": '$MontoCambio' }]''') #La diferencia es del minero
firmadotx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $rawtxhex | jq -r '.hex')
identtx=$(bitcoin-cli sendrawtransaction $firmadotx)

#Ver en la mempool
echo
echo "Punto 3.3. Obtener la transaccion no confirmada desde el mempool con getmempoolentry"
echo "Se ha transferido 20 BTC de la billetera Miner a la billetera Trader. A continuacion se muestran los datos de la transaccion en la mempool"
bitcoin-cli getmempoolentry $identtx

#Minar un bloques
echo
echo "Punto 3.4. Confirmar la transaccion creando un bloque adicional"
hashbloque=$(bitcoin-cli generatetoaddress 1 "$Mineria")

#Datos de la transaccion
echo
echo "Punto 3.5 Obtener los detalles de la transaccion"
echo "La transaccion se ha minado, a continuacion se muestran los datos de la transaccion en la blockchain"
echo "Usaremos el comando gettransaction y leeremos los datos con Json"
fee=$(bitcoin-cli -rpcwallet=Miner gettransaction $identtx | jq -r '.fee')
Adireccion=$(bitcoin-cli -rpcwallet=Miner gettransaction $identtx | jq -r '.details[0].address')
Amonto=$(bitcoin-cli -rpcwallet=Miner gettransaction $identtx | jq -r '.details[0].amount')
Cambiodireccion=$(bitcoin-cli -rpcwallet=Miner gettransaction $identtx | jq -r '.details[1].address')
Cambiomonto=$(bitcoin-cli -rpcwallet=Miner gettransaction $identtx | jq -r '.details[1].amount')
Nconf=$(bitcoin-cli -rpcwallet=Miner gettransaction $identtx | jq -r '.confirmations')
Altura=$(bitcoin-cli -rpcwallet=Miner gettransaction $identtx | jq -r '.blockheight')
echo "La identificacion de la transaccion es: $identtx"
echo "Se envio desde la direccion de Miner: $Dedireccion"
echo "La comision de la transaccion es: $fee"
echo -n "A la direccion: $Adireccion"
echo "por un monto de $Amonto"
echo -n "La direccion de cambio es $Cambiodireccion"
echo "por un monto de $Cambiomonto"
echo "El numero de confirmaciones es $Nconf"
echo "El numero de bloque de la transaccion es $Altura"
echo "La billetera Miner tiene un balance de $(bitcoin-cli -rpcwallet=Miner getbalance) BTC"
echo "La billetera Trader tiene un balance de $(bitcoin-cli -rpcwallet=Trader getbalance) BTC"
echo
echo "Muchas gracias"
