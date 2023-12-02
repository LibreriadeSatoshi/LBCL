#!/bin/bash
# Expand aliases for alias to work in script
shopt -s expand_aliases
# Setting alias to make script easier to read
alias btc-cli='bitcoin-cli -regtest -datadir=/tmp/josei '


start_node() {
  echo -e "${COLOR}Starting bitcoin node...${NO_COLOR}"

  mkdir -p /tmp/josei

  cat <<EOF >/tmp/josei/bitcoin.conf
    regtest=1
    fallbackfee=0.00001
    server=1
    txindex=1

EOF

  bitcoind -regtest -datadir=/tmp/josei -daemon
  sleep 2
}


create_wallet() {
    btc-cli -named createwallet wallet_name=$1 descriptors=false
}


# Get new address for chosen wallet an label it with wallet's name
get_new_address() {
    btc-cli -rpcwallet="$1" getnewaddress "$1 address"
}

# First parameter: number of blocks to generate
# Second parameter: address to generate to
generate_to_address() {
    btc-cli generatetoaddress $1 $2 > /dev/null
}


fund_wallets() {
    miner_address=$(get_new_address "Miner")
    alice_address=$(get_new_address "Alice")
    
    generate_to_address 101 $miner_address > /dev/null

    # Keeping this TX ID to spend it later on
    alice_TX_ID=$(btc-cli -rpcwallet=Miner sendtoaddress $alice_address 45)

    generate_to_address 1 $miner_address > /dev/null
}


confirm_transaction() {
    btc-cli -rpcwallet=Alice gettransaction $alice_TX_ID
}


pay_back() {
    new_miner_address=$(get_new_address "Miner")
    change_address=$(get_new_address "Alice")
    alice_Vout=$(btc-cli -rpcwallet=Alice listunspent |jq -r '.[0]|.vout')
    pay_back_TX_HEX=$(btc-cli -named createrawtransaction inputs='''[ { "txid": "'$alice_TX_ID'", "vout": '$alice_Vout', "sequence": '10' } ]''' outputs='''{ "'$new_miner_address'": 10, "'$change_address'": 34.99999 }''')
    echo "Pay back transaction created"
    
}


sign_and_send() {
    signed_pay_back_TX=$(btc-cli -rpcwallet=Alice signrawtransactionwithwallet $pay_back_TX_HEX | jq -r '.hex')
    echo "Will try to broadcast the transaction with a 10 blocks timelock now, and this is the result: "
    btc-cli -rpcwallet=Alice sendrawtransaction $signed_pay_back_TX

}


re_send_and_confirm() {
    pay_back_TX_ID=$(btc-cli -rpcwallet=Alice sendrawtransaction $signed_pay_back_TX)
    echo "Pay back TX ID: "
    echo $pay_back_TX_ID
    generate_to_address 1 $miner_address > /dev/null
}


print_balance(){
    echo "Alice's balance:"
    btc-cli -rpcwallet=Alice getbalance
}


clean_up() {
  echo -e "${COLOR}Clean Up${NO_COLOR}"
  btc-cli stop
  rm -rf /tmp/josei
}

# Main program
start_node

echo " "
echo "---------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------Setup a Relative TimeLock----------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------------"
echo " "

echo "----- Create two wallets: Miner, Alice. -----------------------------------------------------------------------------------------"
create_wallet "Miner"
create_wallet "Alice"
echo "---------------------------------------------------------------------------------------------------------------------------------"


echo " "
echo "----- Fund the wallets by generating some blocks for Miner and sending some coins to Alice. -------------------------------------"
fund_wallets
echo "---------------------------------------------------------------------------------------------------------------------------------"


echo " "
echo "----- Confirm the transaction and assert that Alice has a positive balance. -----------------------------------------------------"
confirm_transaction
print_balance
echo "---------------------------------------------------------------------------------------------------------------------------------"

echo " "
echo "----- Create a transaction where Alice pays 10 BTC back to Miner, but with a relative timelock of 10 blocks. --------------------"
pay_back
echo "---------------------------------------------------------------------------------------------------------------------------------"

echo " "
echo "----- Report in the terminal output what happens when you try to broadcast the 2nd transaction. ---------------------------------"
sign_and_send
echo "---------------------------------------------------------------------------------------------------------------------------------"

echo " "
echo "---------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------- Spend from relative TimeLock ----------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------------"

echo " "
echo "---------- Generate 10 more blocks. ---------------------------------------------------------------------------------------------"
echo "Generating 10 more blocks..."
generate_to_address 10 $miner_address > /dev/null
echo "---------------------------------------------------------------------------------------------------------------------------------"

echo " "
echo "---------- Broadcast the 2nd transaction. Confirm it by generating one more block. ----------------------------------------------"
re_send_and_confirm
echo "---------------------------------------------------------------------------------------------------------------------------------"

echo " "
echo "---------- Report Balance of Alice. ---------------------------------------------------------------------------------------------"
print_balance
echo "---------------------------------------------------------------------------------------------------------------------------------"

clean_up
exit
