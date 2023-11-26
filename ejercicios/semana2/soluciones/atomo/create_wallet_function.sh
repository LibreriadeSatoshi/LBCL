#!/bin/bash

source ./print_functions.sh

# Creates a new wallet.
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - Name for the wallet
create_wallet() {
  wallet_name=$1

  createwallet_output=$(bitcoin-cli createwallet $wallet_name)
  createwallet_output_name=$(echo $createwallet_output | jq -r '.name')

  if [ "$wallet_name" != "$createwallet_output_name" ]; then
    (>&2 echo $(print_error "Failed to create wallet '$wallet_name'"))
    exit 1
  fi
}
