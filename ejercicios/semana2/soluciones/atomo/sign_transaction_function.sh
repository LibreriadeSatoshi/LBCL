#!/bin/bash

source ./print_functions.sh

# Signs a transaction with the given wallet and returns the signed transaction.
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - rpcwallet
#   $2 - serialized and hex-encoded transaction
sign_transaction() {
  wallet_name=$1
  transaction=$2

  transaction_sign_output=$(bitcoin-cli -rpcwallet="$wallet_name" signrawtransactionwithwallet "$transaction")

  if [ ! -z "$transaction_sign_output" ]; then
    echo "$transaction_sign_output"
  else
    (>&2 echo $(print_error "Failed to sign transaction with wallet '$wallet_name'"))
    exit 1
  fi
}
