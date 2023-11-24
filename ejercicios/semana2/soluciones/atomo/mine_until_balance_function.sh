#!/bin/bash

source ./print_functions.sh

# Mines the necessary blocks until reaching a certain balance.
# Arguments:
#   $1 - Name for the wallet
#   $2 - Address to send the new generated bitcoin
#   $3 - Balance that the wallet must reach
mine_until_balance() {
  wallet_name=$1
  mining_address=$2
  expected_wallet_balance=$(echo $3 | bc)

  blocks_mined=0
  wallet_balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance)

  while (( $(echo "$wallet_balance" "$expected_wallet_balance" | awk '{if ($1 < $2) print 1; else print 0;}') )); do
    bitcoin-cli generatetoaddress 1 "$mining_address" > /dev/null
    blocks_mined=$(($blocks_mined + 1))
    wallet_balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance)
  done

  echo "$wallet_balance"
}
