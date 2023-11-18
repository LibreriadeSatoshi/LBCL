#!/bin/bash
#Instalacion de bitcoin-core-24.1
#Colours
greenC="\e[0;32m\033[1m"
endC="\033[0m\e[0m"
redC="\e[0;31m\033[1m"
blueC="\e[0;34m\033[1m"
yellowC="\e[0;33m\033[1m"
purpleC="\e[0;35m\033[1m"
turquoiseC="\e[0;36m\033[1m"
grayC="\e[0;37m\033[1m"

function_limpieza(){
   sudo bitcoin-cli stop > /dev/null
   echo -e "${blueC}[+] ${endC}${grayC}Stopping Bitcoin core...${endC}"
   sleep 3
   echo -e "${blueC}[+] ${endC}${grayC}Borrando Bitcoin core...${endC}"
   sudo rm -r -f /usr/local/bin/*
   sudo rm -r -f $HOME/.bitcoin/
}

function_herramientas(){
   #instalando herramientas
   echo -e "${blueC}[+] ${endC}${grayC}Instalando herramientas ${endC}"
   sudo apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd
   sleep 1
}

function_dowload_btc(){
   #descargando bitcoin files
   echo -e "${blueC}[+] ${endC}${grayC}Descargando Bitcoin core 24.1${endC}"
   wget https://bitcoincore.org/bin/bitcoin-core-24.1/bitcoin-24.1-x86_64-linux-gnu.tar.gz > /dev/null
   echo -e "${blueC}[+] ${endC}${grayC}Descargando checksum criptografico SHA256SUMS ${endC}"
   wget https://bitcoincore.org/bin/bitcoin-core-24.1/SHA256SUMS > /dev/null
   echo -e "${blueC}[+] ${endC}${grayC}Descargando firmas checksum ${endC}"
   wget https://bitcoincore.org/bin/bitcoin-core-24.1/SHA256SUMS.asc > /dev/null 
   echo -e "${blueC}[+] ${endC}${grayC}Descargando la lista de firmas ${endC}"
   git clone https://github.com/bitcoin-core/guix.sigs > /dev/null 
   sleep 1
}

function_verificar_firmas(){
   # Verificando firmas
   echo -e "${blueC}[+] ${endC}${grayC}Verificando lista de checksum ${endC}"
   shasum --ignore-missing --check SHA256SUMS
   echo -e "${blueC}[+] ${endC}${grayC}Importando todas las firmas ${endC}"
   gpg --import guix.sigs/builder-keys/*
   echo -e "${blueC}[+] ${endC}${grayC}Verificando el file checksum con varias firmas ${endC}"
   gpg --verify SHA256SUMS.asc
   echo -e "${blueC}[!] ${endC}${redC}Verificar con los respectivos desarrolladores la validez de las firmas ! ${endC}"
sleep 4
}

function_unzip_clean(){
# Descomprimiendo paquete bitcoin core
   echo -e "\n${blueC}[+] ${endC}${grayC}Descomprimiendo Bitcoin Core 24.1${endC}"
   tar xzf bitcoin-24.1-x86_64-linux-gnu.tar.gz
   sleep 1
# Limpiando
   echo -e "${blueC}[+] ${endC}${grayC}Eliminando files temporaneos ${endC}"
   rm -r -f SHA256SUMS  SHA256SUMS.asc  bitcoin-24.1-x86_64-linux-gnu.tar.gz  guix.sigs
   sleep 1 
}

function_instala(){
# Instalando binarios
  echo -e "${blueC}[+] ${endC}${yellowC}Instalando Bitcoin Core 24.1 ${endC}"
  sudo install -m 0755 -o root -g root -t /usr/local/bin/ bitcoin-24.1/bin/*
  rm -r -f bitcoin*
  sleep 2
}

function_conf(){
# Creando file bitcoin.nconf
  mkdir $HOME/.bitcoin
  echo -e "regtest=1\nfallbackfee=0.0001\nserver=1\ntxindex=1" > $HOME/.bitcoin/bitcoin.conf
  echo $(cat $HOME/.bitcoin/bitcoin.conf)
  sleep 1
  echo -e "${blueC}[!] ${endC}${redC}$(bitcoind --version | grep version ) ${endC}"
}

functionClean(){
   clear
   sleep 1 
   echo -e "${blueC}[!] ${endC}${yellowC}Stopping Bitcoin Core${endC}"
   bitcoin-cli stop > /dev/null 
   rm -r -f ~/.bitcoin/regtest/
   sleep 5
}

functionStart(){
   echo -e "${blueC}[+] ${endC}${grayC}Restarting Bitcoin Core${endC}"
   bitcoind -daemon
   echo -e "\t\t\t\t\t\t${blueC}$(bitcoind --version | grep version)${endC}"
   sleep 3
   echo -e "${blueC}[+] ${endC}${grayC}Blockchain: ${endC}${greenC}\t\t\t\t$(bitcoin-cli getblockchaininfo | jq -r .chain ) ${endC}"

 }

functionCreaWallet(){
   
   echo -e "${blueC}[+] ${endC}${grayC}Creando wallets Miner y Trader... ${endC}"
   bitcoin-cli -named createwallet wallet_name="Miner" > /dev/null
   bitcoin-cli -named createwallet wallet_name="Trader" > /dev/null
   sleep 1 
}

fuctionNewAddress(){
   walletAddressMiner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Wallet recompensa de mineria")
   echo -e "${blueC}[+] ${endC}${grayC}Nueva Wallet Miner: \t\t\t${endC}${greenC}$walletAddressMiner ${endC}"
   walletAddressTrader=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Wallet del trader")
   echo -e "${blueC}[+] ${endC}${grayC}Nueva Wallet Trader: \t\t\t${endC}${greenC}$walletAddressTrader ${endC}"
   sleep 1
}


functionMining(){
   # Minado de bloques para tener saldo positivo
   echo -e "\n${blueC}[+] ${endC}${grayC}Altura de bloque: \t\t\t\t${endC}${greenC}$(bitcoin-cli getblockchaininfo | grep "blocks" | awk '{print $2}' | tr ',' ' ')${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Balance: \t\t\t\t\t${endC}${greenC}$(bitcoin-cli -rpcwallet=Miner getbalance | bc)${endC}"
   echo -e "${blueC}[+] ${endC}${yellowC}Minando bloques...${endC}"
   bitcoin-cli generatetoaddress 110 ${walletAddressMiner} > /dev/null
   #echo "Mina 2 bloques:"
   #bitcoin-cli generatetoaddress 2 $walletAddressMiner
   echo -e "${blueC}[+] ${endC}${grayC}Altura de bloque: \t\t\t\t${endC}${greenC}$(bitcoin-cli getblockchaininfo | grep blocks | awk '{print $2}' | tr ',' ' ')${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Balance: \t\t\t\t\t${endC}${greenC}$(bitcoin-cli -rpcwallet=Miner getbalance | bc)${endC}"
   sleep 1
 }

transaccion20(){
   echo -e "\n${blueC}[+] ${endC}${grayC}Informacion preliminar a la transaccion: ${endC}"
   echo -e   "${blueC}[+] ${endC}${grayC}Saldo en la wallet del Miner: \t\t${endC}${greenC}$(bitcoin-cli -rpcwallet=Miner getbalance | bc)${endC}"
   echo -e   "${blueC}[+] ${endC}${grayC}Saldo en la wallet del Trader: \t\t${endC}${greenC}$(bitcoin-cli -rpcwallet=Trader getbalance | bc)${endC}"
   # Transaccion: El Miner envia 20 bitcoin al Trader
   txMinerTrader=$(bitcoin-cli -rpcwallet=Miner sendtoaddress "$walletAddressTrader" 20)

   echo -e "\n${blueC}[+] ${endC}${grayC}Envio de 20 BTC al trader...${endC}"
   echo -e   "${blueC}[+] ${endC}${grayC}Hash de transaccion Miner -> trader \t${endC}${greenC}$txMinerTrader${endC}"
}

busquedaMempool(){
   mempoolTx=$(bitcoin-cli getmempoolentry $txMinerTrader | jq -r .unbroadcast )
   echo -e "${blueC}[+] ${endC}${grayC}Estado de la transaccion en la mempool: \t${endC}${greenC}$mempoolTx${endC} "
   sleep 1
}

mining5blocks(){
   #mina otros bloques
   echo -e "\n${blueC}[+] ${endC}${grayC}Minando 5 bloques... ${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Altura de bloque: \t\t\t\t${endC}${greenC}$(bitcoin-cli getblockchaininfo | grep "blocks" | awk '{print $2}' | tr ',' ' ')${endC}"
   echo -e   "${blueC}[+] ${endC}${grayC}Balance: \t\t\t\t\t${endC}${greenC}$(bitcoin-cli -rpcwallet=Miner getbalance | bc)${endC}"
   echo -e   "${blueC}[+] ${endC}${yellowC}Mining...${endC}"
sleep 1
   bitcoin-cli generatetoaddress 5 $walletAddressMiner > /dev/null
   echo -e "${blueC}[+] ${endC}${grayC}Altura de bloque: \t\t\t\t${endC}${greenC}$(bitcoin-cli getblockchaininfo | grep "blocks" | awk '{print $2}' | tr ',' ' ')${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Balance: \t\t\t\t\t${endC}${greenC}$(bitcoin-cli -rpcwallet=Miner getbalance | bc)${endC}"

}

detalleTransaccion(){
   #Transaccion minero - Trader
   echo -e "\n${blueC}[+] ${endC}${grayC}Detalle de la transaccion: ${endC}"
   txMiner=$(bitcoin-cli -rpcwallet=Miner gettransaction $txMinerTrader)
   txMinerRaw=$(bitcoin-cli -rpcwallet=Miner getrawtransaction $txMinerTrader)
   txMinerDecoded=$(bitcoin-cli decoderawtransaction $txMinerRaw)
   txidMinerFrom=$(echo $txMinerDecoded | jq -r .vin[0].txid )
   txParent=$(bitcoin-cli -rpcwallet=Miner gettransaction $txidMinerFrom)
   txMinerFromAddress0=$(echo $txMinerDecoded | jq -r  .vout[0].scriptPubKey.address )
   MinerFromAddressAmount0=$(echo $txMinerDecoded | jq  .vout[0].value )
   txMinerFromAddress1=$(echo $txMinerDecoded | jq -r  .vout[1].scriptPubKey.address )
   MinerFromAddressAmount1=$(echo $txMinerDecoded | jq  .vout[1].value )
   walletMinerAddressFrom=$(echo $txParent | jq -r .details[0].address )
   walletMinerFromAmount=$(echo $txParent | jq .details[0].amount )
   txFee=$(echo "$walletMinerFromAmount - $MinerFromAddressAmount1 - $MinerFromAddressAmount0" | bc )
#  echo -e "${blueC}[+] ${endC}${grayC}Transaction ID: \t\t${endC}${greenC}$txidMinerFrom ${endC}"           #############

   echo -e "\n${blueC}[+] ${endC}${grayC}Detalle TX wallet Miner: ${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Address UTXO Origin \t\t\t${endC}${greenC}$walletMinerAddressFrom ${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Original balance\t\t\t\t${endC}${greenC}$walletMinerFromAmount ${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Send to Wallet Address \t\t\t${endC}${greenC}$txMinerFromAddress0 ${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Importe \t\t\t\t\t${endC}${greenC}$MinerFromAddressAmount0 ${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Send to Wallet Address \t\t\t${endC}${greenC}$txMinerFromAddress1 ${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Importe \t\t\t\t\t${endC}${greenC}$MinerFromAddressAmount1 ${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Fee \t\t\t\t\t${endC}${greenC}$txFee ${endC}"

   sleep 1
   
   txTrader=$(bitcoin-cli -rpcwallet=Trader gettransaction $txMinerTrader)
   txTraderId=$(echo $txTrader | jq -r .txid )
   txTraderAmount=$(echo $txTrader | jq .amount )
   txTraderAddress=$(echo $txTrader | jq -r .details[0].address )
   txConfirmations=$(echo $txTrader | jq -r .confirmations )

   echo -e "\n${blueC}[+] ${endC}${grayC}Detalle TX wallet Trader: ${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Transaction ID: \t\t\t\t${endC}${greenC}$txTraderId${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Wallet Address: \t\t\t\t${endC}${greenC}$txTraderAddress${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Importe recibido: \t\t\t\t${endC}${greenC}$txTraderAmount${endC}"
   echo -e "${blueC}[+] ${endC}${grayC}Confirmations: \t\t\t\t${endC}${greenC}$txConfirmations${endC}"
   sleep 1
 }

function_limpieza
function_herramientas
function_dowload_btc
function_verificar_firmas
function_unzip_clean
function_instala
function_conf

functionClean
functionStart
functionCreaWallet
fuctionNewAddress
functionMining
transaccion20
busquedaMempool
mining5blocks
detalleTransaccion

