#!/bin/bash

apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd
	bitcoin-cli stop
sudo rm -rf $HOME/.bitcoin
sudo rm -rf /usr/local/bin/bitcoin* 
sudo rm -rf $HOME/bitcoin*
sudo rm -rf $HOME/SHA256SUMS*
sudo rm -rf $HOME/guix.sigs
wget https://bitcoincore.org/bin/bitcoin-core-25.1/bitcoin-25.1-x86_64-linux-gnu.tar.gz
wget https://bitcoincore.org/bin/bitcoin-core-25.1/SHA256SUMS
wget https://bitcoincore.org/bin/bitcoin-core-25.1/SHA256SUMS.asc
checkSum=$(sha256sum --ignore-missing --check SHA256SUMS)
echo $checkSum
if [ "$checkSum" = "bitcoin-25.1-x86_64-linux-gnu.tar.gz: OK" ]; then
    echo "¡La suma hash es válida! Confirmación exitosa."
else
    echo "La suma hash no coincide. No se pudo confirmar la integridad del archivo."
    exit
fi
#Se descargan las firmas
git clone https://github.com/bitcoin-core/guix.sigs.git
#Se importan las firmas
gpg --import guix.sigs/builder-keys/*
#Se verifican las firmas
gpg --verify SHA256SUMS.asc
#Se descomprimen los binario
ls
sudo tar -xvf bitcoin-25.1-x86_64-linux-gnu.tar.gz -C /usr/local/bin/
#Se arma el directorio del config
bitcoin_data_dir="/home/$USER/.bitcoin"
# Verificar si el directorio de datos de Bitcoin existe, si no, crearlo
if [ ! -d "$bitcoin_data_dir" ]; then
    mkdir -p "$bitcoin_data_dir"
fi
# Crear el archivo bitcoin.conf y agregar las líneas requeridas
conf_file="$bitcoin_data_dir/bitcoin.conf"
# Contenido del archivo bitcoin.conf
conf_content="regtest=1
fallbackfee=0.0001
server=1
txindex=1"
# Escribir el contenido en el archivo
echo "$conf_content" > "$conf_file"
# Se agrega bitcoin al path
export PATH="$PATH:/usr/local/bin/bitcoin-25.1/bin"
#Se inicia el deamon de Bitcoin
bitcoind -daemon
#Se crean las carteras
bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true
#Se odtiene una nueva direccion
Recompensa=`bitcoin-cli -rpcwallet=Miner getnewaddress "Recompensa de Minería"`
echo "Cartera de minero: " $Recompensa
echo "Las recompensas creadas no son disponibles para gasto ya que de si se liberan al momento de la creacion se podrian usar para gastar, pero como existe una posibilidad que la rama se bifurque genera un riesgo para el doble gasto"
#Se minan bloques hasta quedar el balance disponible
while [ $(echo "$(bitcoin-cli -rpcwallet=Miner getbalance) == 0" | bc -l) -eq 1 ]; do
	bitcoin-cli generatetoaddress 1 "$Recompensa"
done
echo "saldo del minero: " $(bitcoin-cli -rpcwallet=Miner getbalance)
CarteraRecepcion=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Recibido")
echo "Cartera del trader: " $CarteraRecepcion
#Se genera el envio al trader
tx=`bitcoin-cli -rpcwallet=Miner sendtoaddress "$CarteraRecepcion" 20`
#echo "Tx: "$tx
#Se busca la tx en la memmpool
echo "memmpool tx:"
bitcoin-cli getmempoolentry $tx
bitcoin-cli generatetoaddress 1 "$Recompensa"
echo "txid: "$tx
#Se mina el bloque para ejecutar la tx
rawtx=$(bitcoin-cli -rpcwallet=Trader getrawtransaction "$tx" 1)
#Se busca e imprime la informacion del ejercicio
txidUtxo=$(echo "$rawtx" | jq -r '.vin[0].txid')
rawtxUtxo=$(bitcoin-cli -rpcwallet=Trader getrawtransaction "$txidUtxo" 1)
cantidadUtxo=$(echo "$rawtxUtxo" | jq -r '.vout[0].value')
cantidadEnvio=$(echo "$rawtx" | jq -r '.vout[0].value')
cantidadCambio=$(echo "$rawtx" | jq -r '.vout[1].value')
fee=$(echo "$cantidadUtxo - $cantidadEnvio - $cantidadCambio" | bc)
echo "txid: " $tx
echo "<De,Cantidad>: <" $Recompensa "," $cantidadUtxo ">"
echo "<Enviar,Cantidad>: <" $CarteraRecepcion "," $cantidadEnvio ">"
echo "<Cambio,Cantidad>: <" $Recompensa "," $cantidadCambio ">"
echo "Comisiones: " $fee
echo "Bloque: " $(bitcoin-cli -rpcwallet=Trader gettransaction "$tx" | jq -r '.blockheight')
echo "Saldo del minero: " $(bitcoin-cli -rpcwallet=Miner getbalance)
echo "Saldo del trader: " $(bitcoin-cli -rpcwallet=Trader getbalance)
