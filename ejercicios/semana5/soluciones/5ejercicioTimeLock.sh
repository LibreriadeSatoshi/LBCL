#!/bin/bash

# Ejercicio semana 5
# Timelock + sequence 10 blocks
# cryptonando
#
function ctrl_c(){
  echo -e "\n\n[!] Saliendo...\n" 
 tput cnorm;  exit 1 #codigo de estado no exitoso
}

#Ctrl+C

#Colours
c01="\e[0;31m\033[1m"
c02="\e[0;33m\033[1m"
c03="\e[0;32m\033[1m"
c04="\e[0;36m\033[1m"
c05="\e[0;34m\033[1m"
c06="\e[0;35m\033[1m"
c07="\e[0;37m\033[1m"
endC="\033[0m\e[0m"
#Colours
#
functionClean(){
   clear
   echo "--- --- -- -- --- --- -- -- --- --- -- -- --- --- -- -- --- ---"
   echo -e "${c05}[!] ${endC}${c01}Stopping Bitcoin Core${endC}"
   bitcoin-cli stop > /dev/null 
   sleep 7
   rm -r -f ~/.bitcoin/regtest/
}

functionStart(){
   echo -e "${c05}[+] ${endC}${c07}Restarting Bitcoin Core${endC}"
   bitcoind -daemon
   echo -e "${c05}$(bitcoind --version | grep version)${endC}"
   sleep 3
   clear
   echo -e "${c06}--- --- -- -- --- --- -- -- --- --- -- -- --- --- -- -- --- ---${endC}"
   echo -e "${c05}[+] ${endC}${c07}Blockchain: ${endC}${c03}\t\t\t\t$(bitcoin-cli getblockchaininfo | jq -r .chain ) ${endC}"
}
# ---------------------------------------------
# Crear tres wallets para Miner, Alice y Bob  
# ---------------------------------------------
functionCreaWallet(){
   echo -e "${c05}[+] ${endC}${c07}Creando wallets Miner, Alice y Bob... ${endC}"
   bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true > /dev/null
   bitcoin-cli -named createwallet wallet_name="Alice" descriptors=true > /dev/null
   bitcoin-cli -named createwallet wallet_name="Bob" descriptors=true > /dev/null
# Crear direcciones para las 3 wallets 
   walletAddressMiner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Wallet recompensa de mineria")
   walletAddressAlice=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Wallet de Alice")
   walletAddressBob=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Wallet de Bob") 

   echo -e "\n${c05}[+] ${endC}${c07}Direccion Wallet Miner:       \t\t${endC}${c03}$walletAddressMiner${endC}"
   echo -e "${c05}[+] ${endC}${c07}Direccion Wallet Alice:         \t\t${endC}${c06}$walletAddressAlice${endC}"
   echo -e "${c05}[+] ${endC}${c07}Direccion Wallet Bob:           \t\t${endC}${c05}$walletAddressBob${endC}"
}

functionMining(){
   echo -e "${c05}[!] ${endC}${c01}Minando... ${endC}"
   bitcoin-cli generatetoaddress 103 ${walletAddressMiner} > /dev/null
}

functionBlockHeight(){
   balanceMiner=$(bitcoin-cli -rpcwallet=Miner getbalance )
   BlockHeight=$(bitcoin-cli getblockchaininfo | jq .blocks )
   echo -e "${c05}[+] ${endC}${c07}Miner Balance: ${c03}$balanceMiner${endC}${c07} Block Height:\t${endC}${c03}$BlockHeight${endC}"
}

# ---------------------------------------------
# Transaccion 1: El Minero paga al Alice 11 bitcoin
# ---------------------------------------------

functionMinerAlice(){
   balanceMiner=$(bitcoin-cli -rpcwallet=Miner getbalance | bc)
   balanceAlice=$(bitcoin-cli -rpcwallet=Alice getbalance | bc)
   echo -e "\n${c05}[-] ${endC}${c07}Preparando transaccion:${endC}"
   echo -e   "${c05}[+] ${endC}${c07}Saldo actual en la wallet del Miner: \t${endC}${c03}$balanceMiner${endC}"
   echo -e   "${c05}[+] ${endC}${c07}Saldo actual en la wallet de Alice: \t${endC}${c06}$balanceAlice${endC}"

   # Transaccion: El Miner envia 11 bitcoin al Alice
   txidMinerAlice=$(bitcoin-cli -rpcwallet=Miner sendtoaddress "$walletAddressAlice" 11)
   # 11 bitcoin enviados
   balanceMiner=$(bitcoin-cli -rpcwallet=Miner getbalance | bc)
   balanceAlice=$(bitcoin-cli -rpcwallet=Alice getbalance | bc)
   txMinerAlice=$(bitcoin-cli -rpcwallet=Miner gettransaction $txidMinerAlice)


   echo -e "\n${c05}[-] ${endC}${c07}Miner envia a Alice 11 Bitcoin. Comprobando envio...${endC}"
   sleep 1
   echo -e "${c05}[+] ${endC}${c07}Hash de transaccion           \t\t${endC}${c03}$txidMinerAlice${endC}"
   echo -e "${c05}[+] ${endC}${c07}Saldo en la wallet del Miner: \t\t${endC}${c03}$balanceMiner${endC}"
   echo -e "${c05}[+] ${endC}${c07}Esperando que se mine 1 bloque...${endC}"
   echo -e "${c05}[!] ${endC}${c01}Minando... ${endC}"
   #
   bitcoin-cli generatetoaddress 1 ${walletAddressMiner} > /dev/null
   #

   txMinerAlice=$(bitcoin-cli -rpcwallet=Miner gettransaction $txidMinerAlice)
   balanceAlice=$(bitcoin-cli -rpcwallet=Alice getbalance | bc)
   confirmationsTxMinerAlice=$(echo $txMinerAlice | jq .confirmations )
   echo -e "${c05}[+] ${endC}${c07}Confirmaciones:               \t\t${endC}${c03}$confirmationsTxMinerAlice${endC}"
   echo -e "${c05}[+] ${endC}${c07}Saldo en la wallet del Alice:  \t\t${endC}${c06}$balanceAlice${endC}"
   echo -e "${c05}[-] ${endC}${c07}TransaccionFinalizada...${endC}"
}
# ---------------------------------------------
# Alice paga a bob 10 bitcoin utilizando un bloqueo de tiempo Lock Time de 10 bloques
# ---------------------------------------------

functionAliceBob(){
   echo -e "\n${c05}[-] ${endC}${c07}Preparando transaccion:  ${endC}"

# Obteniendo datos del jefe para crear TX RAW
# Creando TX Raw
# verificando con decode 
# firmando
# transmitiendo

#
# Getting utxo data
#
  unspentAlice=$(bitcoin-cli -rpcwallet=Alice listunspent)
#  echo "$unspentAlice"
  txidAlice0=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .txid')
  voutAlice0=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .vout')
  amountAlice0=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .amount')
#
# Presenting Data 
#
   echo -e "${c05}[+] ${endC}${c07}Alice Balance: ${endC}${c03}$amountAlice0${endC}${c07} Utxo Vout: ${endC}${c03}$voutAlice0${endC} ${c07} Txid:\t${endC}${c03}$txidAlice0${endC}"
   echo -e "${c05}[-] ${endC}${c07}Alice enviara un pago de 10 Bitcoin a Bob con timelock de 10 bloques  ${endC}"
# creating raw transaction
# sequence = 10 blocks
#
   AlicePagaRawTxHex=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txidAlice0'", "vout": '$voutAlice0', "sequence": '10' } ]''' outputs='''{ "'$walletAddressBob'": 10, "'$walletAddressAlice'": 0.9999}''')
#  AlicePagaRawtxDec=$(bitcoin-cli decoderawtransaction $AlicePagaRawTxHex)
   AlicePagaTxFirma=$(bitcoin-cli -rpcwallet=Alice signrawtransactionwithwallet $AlicePagaRawTxHex | jq -r '.hex')
   txidAlice=$(bitcoin-cli sendrawtransaction $AlicePagaTxFirma)
   echo $txidAlice
   echo -e "${c05}[!] ${endC}${c01}Error: ${endC}${c02}El nodo rechaza la transaccion porque esta bloqueada por el locktime. Espera.${endC}"
   balanceMiner=$(bitcoin-cli -rpcwallet=Miner getbalance )
   BlockHeight=$(bitcoin-cli getblockchaininfo | jq .blocks )
   echo -e "${c05}[+] ${endC}${c07}Miner Balance: ${c03}$balanceMiner${endC}${c07} Block Height:\t${endC}${c03}$BlockHeight${endC}"
 }
# ---------------------------------------------
# ---------------------------------------------

 functionReenvio(){
   echo -e "${c05}[!] ${endC}${c01}Minando... ${endC}"
   bitcoin-cli generatetoaddress 10 ${walletAddressMiner} > /dev/null
   balanceMiner=$(bitcoin-cli -rpcwallet=Miner getbalance )
   BlockHeight=$(bitcoin-cli getblockchaininfo | jq .blocks )
   echo -e "${c05}[+] ${endC}${c07}Miner Balance: ${c03}$balanceMiner${endC}${c07} Block Height:\t${endC}${c03}$BlockHeight${endC}"
   echo -e "${c05}[+] ${endC}${c07}Alice reenvia la transaccion luego del locktime ${endC}"
   txidAlice=$(bitcoin-cli sendrawtransaction $AlicePagaTxFirma)

#mina 1 bloque 
   echo -e "${c05}[!] ${endC}${c01}Minando... ${endC}"
   bitcoin-cli generatetoaddress 1 ${walletAddressMiner} > /dev/null
   balanceMiner=$(bitcoin-cli -rpcwallet=Miner getbalance )
   BlockHeight=$(bitcoin-cli getblockchaininfo | jq .blocks )
   echo -e "${c05}[+] ${endC}${c07}Miner Balance: ${c03}$balanceMiner${endC}${c07} Block Height:\t${endC}${c03}$BlockHeight${endC}"

   balanceAlice=$(bitcoin-cli -rpcwallet=Alice getbalance | bc)
   balanceBob=$(bitcoin-cli -rpcwallet=Bob getbalance | bc)
   
   echo -e "${c05}[+] ${endC}${c07}Transaccion realizada con exito ${endC}"
   echo -e "${c05}[+] ${endC}${c07}Saldo de Alice despues del locktime: ${endC}\t${c06}$balanceAlice${endC}"
   echo -e "${c05}[+] ${endC}${c07}Saldo de Bob: ${endC}                       \t${c05}$balanceBob${endC}"
 }


functionClean
functionStart
functionCreaWallet
functionMining
functionBlockHeight
functionMinerAlice
functionAliceBob
functionReenvio
echo "--- --- -- -- --- --- -- -- --- --- -- -- --- --- -- -- --- ---"
