#!/bin/bash
# By Cryptonando
# Multisig regtest example 
#
#
#
function ctrl_c(){
# Nice exit with CTRL+C 
  echo -e "\n\n[!] Afuera...\n" 
 tput cnorm;  exit 1 # ---> not succesfull exit 
}
#
#
#
# Colour definition
c01="\e[0;31m\033[1m"
c02="\e[0;33m\033[1m"
c03="\e[0;32m\033[1m"
c04="\e[0;36m\033[1m"
c05="\e[0;34m\033[1m"
c06="\e[0;35m\033[1m"
c07="\e[0;37m\033[1m"
endC="\033[0m\e[0m"
#
#
#
functionClean(){
# # # Stop bitcoin-cli and delete files
   clear
   echo -e "${c05}[!] ${endC}${c02}Stopping Bitcoin Core${endC}"
   bitcoin-cli stop > /dev/null 
   sleep 7
   rm -r -f ~/.bitcoin/regtest/

}
#
#
#
functionStart(){
# # # Starts bitcoin-cli and shows regtest blockchain
   echo -e "${c05}[+] ${endC}${c07}Restarting Bitcoin Core${endC}"
   bitcoind -daemon
   echo -e "${c05}$(bitcoind --version | grep version)${endC}"
   sleep 3
   echo -e "${c05}[+] ${endC}${c07}Blockchain: ${endC}${c03}\t\t\t\t$(bitcoin-cli getblockchaininfo | jq -r .chain ) ${endC}"
}
#
#
#
functionCreateWallet(){
#
# Create wallet - use descriptors=false
#
   echo -e "${c05}[+] ${endC}${c07}Creating wallets Miner, Alice and Bob... ${endC}"
   bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true > /dev/null
   bitcoin-cli -named createwallet wallet_name="Alice" descriptors=false > /dev/null
   bitcoin-cli -named createwallet wallet_name="Bob" descriptors=false > /dev/null
#
# Get Addresses
#
   walletAddressMiner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Miner Reward Wallet")
   walletAddressAlice=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alice Investment Wallet")
   walletAddressBob=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Bob Investment Wallet")
   walletAddressAliceCh=$(bitcoin-cli -rpcwallet=Alice getnewaddress "Alice Change Wallet")
   walletAddressBobCh=$(bitcoin-cli -rpcwallet=Bob getnewaddress "Bob Change Wallet")


#
# Report:
#
   echo -e "\n${c05}[+] ${endC}${c07}Miner Wallet address:     \t\t\t${endC}${c03}$walletAddressMiner ${endC}"
   echo -e "${c05}[+] ${endC}${c07}Alice Wallet Address:       \t\t${endC}${c03}$walletAddressAlice ${endC}"
   echo -e "${c05}[+] ${endC}${c07}Alice Wallet Address Change:\t\t${endC}${c03}$walletAddressAliceCh ${endC}"
   echo -e "${c05}[+] ${endC}${c07}Bob Wallet Address:         \t\t${endC}${c03}$walletAddressBob ${endC}"
   echo -e "${c05}[+] ${endC}${c07}Bob Wallet Address Change:  \t\t${endC}${c03}$walletAddressBobCh ${endC}"


 }
#
#
#
functionMining(){
#
# Mining 103 blocks
#
   echo -e "${c05}[!] ${endC}${c01}Mining some Blocks... ${endC}"
   bitcoin-cli generatetoaddress 103 ${walletAddressMiner} > /dev/null
}
#
#
#
functionBlockHeight(){
#
# Reporting Actual lock Height 
#

   balanceMiner=$(bitcoin-cli -rpcwallet=Miner getbalance )
   BlockHeight=$(bitcoin-cli getblockchaininfo | jq .blocks )
   echo -e "${c05}[+] ${endC}${c07}Miner Balance: ${c03}$balanceMiner${endC}${c07} Block Height:\t${endC}${c03}$BlockHeight${endC}"
}
# Transaccion 1: El Minero paga al Jefe 40 bitcoin
# ---------------------------------------------

functionPay11(){
#
# Miner pays 11 + 11 Bitcoin 
#
   txidMinerPayAlice=$(bitcoin-cli -rpcwallet=Miner sendtoaddress "$walletAddressAlice" 11)
   txidMinerPayBob=$(bitcoin-cli -rpcwallet=Miner sendtoaddress "$walletAddressBob" 11)
   bitcoin-cli generatetoaddress 1 ${walletAddressMiner} > /dev/null

   balanceAlice=$(bitcoin-cli -rpcwallet=Alice getbalance )
   balanceBob=$(bitcoin-cli -rpcwallet=Bob getbalance )

   echo -e "\n${c05}[-] ${endC}${c07}Miner transaction: ${endC}"
   echo -e "${c05}[-] ${endC}${c07}Pay 11 Bitcoin to Alice and 11 Bitcoin to Bob ${endC}"
   functionBlockHeight
   echo -e   "${c05}[+] ${endC}${c07}Balance Alice:  \t\t\t\t${endC}${c03}$balanceAlice${endC}"
   echo -e   "${c05}[+] ${endC}${c07}Balance Bob:    \t\t\t\t${endC}${c03}$balanceBob${endC}"


}

functionMultisigAddress(){
#
# get public key from address 
#
   alicePubkey=$(bitcoin-cli -rpcwallet=Alice getaddressinfo $walletAddressAlice | jq -r '.pubkey')
   bobPubkey=$(bitcoin-cli -rpcwallet=Bob getaddressinfo $walletAddressBob | jq -r '.pubkey')
   #   multisigAliceBob=$(bitcoin-cli -named createmultisig nrequired=2 keys='''["'$alicePubkey'","'$bobPubkey'"]''')
   #   multisigAliceBobAddress=$(echo $multisigAliceBob | jq '.address' )
   multisigAliceBobAddress=$(bitcoin-cli -named createmultisig nrequired=2 keys='''["'$alicePubkey'","'$bobPubkey'"]'''| jq -r '.address')
   #multisigAliceBobAddress=$(echo $multisigAliceBob | jq '.address' )
   echo -e "\n${c05}[-] ${endC}${c07}Create Multisig 2 of 2 ${endC}"
   echo -e "${c05}[+] ${endC}${c07}Alice pubkey:    \t\t\t\t${endC}${c03}$alicePubkey${endC}"
   echo -e "${c05}[+] ${endC}${c07}Bob pubkey:      \t\t\t\t${endC}${c03}$bobPubkey${endC}"
   echo -e "${c05}[+] ${endC}${c07}Multisig Address:\t\t\t\t${endC}${c03}$multisigAliceBobAddress${endC}"

#  echo -e "${c02}$multisigAliceBob${endC}"
}

functionCoinJoinPSBT(){
#
# partially signed transaction send +10BTC from Alice + 10BTC from Bob to multisig address
#
#Getting alice TX information
   unspentAlice=$(bitcoin-cli -rpcwallet=Alice listunspent)
   txidAlice0=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .txid')
   voutAlice0=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r '.[0] | .vout')
#Getting Bob TX information
   unspentBob=$(bitcoin-cli -rpcwallet=Alice listunspent)
   txidBob0=$(bitcoin-cli -rpcwallet=Bob listunspent | jq -r '.[0] | .txid')
   voutBob0=$(bitcoin-cli -rpcwallet=Bob listunspent | jq -r '.[0] | .vout')
   echo -e "${c05}[+] ${endC}${c07}Alice \t\t\tVout: ${endC}${c03}$voutAlice0${endC}${c07} Txid:\t${endC}${c03}$txidAlice0${endC} "
   echo -e "${c05}[+] ${endC}${c07}Bob   \t\t\tVout: ${endC}${c03}$voutBob0${endC}${c07} Txid:\t${endC}${c03}$txidBob0${endC}"
#
# createpsbt 
#
   psbt=$(bitcoin-cli -named createpsbt inputs='''[ {"txid":"'$txidAlice0'", "vout": '$voutAlice0'},{"txid":"'$txidBob0'", "vout": '$voutBob0'} ]'''    outputs='''{"'$multisigAliceBobAddress'": 20, "'$walletAddressAliceCh'": 0.99999, "'$walletAddressBobCh'":0.99999 } ''' )
   aliceSignPsbt=$(bitcoin-cli -rpcwallet=Alice walletprocesspsbt $psbt | jq -r '.psbt')
   bobSignPsbt=$(bitcoin-cli -rpcwallet=Bob walletprocesspsbt $psbt | jq -r '.psbt')
#
# Report
#
#

   echo -e "${c05}[+] ${endC}${c07}Created PSBT:${endC}\n${c02}$psbt${endC}"
   echo -e "${c05}[+] ${endC}${c07}Analize PSBT:${endC} "
   bitcoin-cli -named analyzepsbt psbt=$psbt | jq
   echo "--- --- -- -- --- --- -- -- --- --- -- -- --- --- -- -- --- ---"
   echo -e "${c05}[+] ${endC}${c07}Analize PSBT -> Alice Signature:${endC} "
   bitcoin-cli -named analyzepsbt psbt=$aliceSignPsbt | jq
   echo "--- --- -- -- --- --- -- -- --- --- -- -- --- --- -- -- --- ---"
   echo -e "${c05}[+] ${endC}${c07}Analize PSBT -> Bob Signature:${endC} "
   bitcoin-cli -named analyzepsbt psbt=$bobSignPsbt | jq
   echo "--- --- -- -- --- --- -- -- --- --- -- -- --- --- -- -- --- ---"
   echo -e "${c05}[+] ${endC}${c07}Alice Signature: ${endC}\n${c02}$aliceSignPsbt${endC} "
   echo -e "${c05}[+] ${endC}${c07}Bob Signature:   ${endC}\n${c02}$bobSignPsbt${endC} "
#
# Combined PSBT
#
#
   combinedPsbt=$(bitcoin-cli combinepsbt '''["'$aliceSignPsbt'","'$bobSignPsbt'"]''')
   echo -e "${c05}[+] ${endC}${c07}Combined PSBT:${endC} "
   bitcoin-cli -named analyzepsbt psbt=$combinedPsbt | jq
#
# Finalize PSBT
#
   hexPsbt=$(bitcoin-cli finalizepsbt $combinedPsbt | jq -r '.hex')
   echo -e "${c05}[+] ${endC}${c07}Hex PSBT transaction:   ${endC}\n${c02}$hexPsbt${endC} "
   txidPsbt=$(bitcoin-cli -named sendrawtransaction hexstring=$hexPsbt )
   echo -e "${c05}[+] ${endC}${c07}Transaction id:   ${endC}\n${c02}$txidPsbt${endC} "
 }
functionFinalBalance(){
   echo -e "${c05}[!] ${endC}${c01}Mining some Blocks... ${endC}"
   bitcoin-cli generatetoaddress 3 ${walletAddressMiner} > /dev/null
   functionBlockHeight

   balanceAlice=$(bitcoin-cli -rpcwallet=Alice getbalance )
   balanceBob=$(bitcoin-cli -rpcwallet=Bob getbalance )

   echo -e   "${c05}[+] ${endC}${c07}Balance Alice:  \t\t\t\t${endC}${c03}$balanceAlice${endC}"
   echo -e   "${c05}[+] ${endC}${c07}Balance Bob:    \t\t\t\t${endC}${c03}$balanceBob${endC}"



}
functionClean
functionStart
functionCreateWallet
functionMining
functionPay11
functionMultisigAddress
functionCoinJoinPSBT
functionFinalBalance
#echo "--- --- -- -- --- --- -- -- --- --- -- -- --- --- -- -- --- ---"
