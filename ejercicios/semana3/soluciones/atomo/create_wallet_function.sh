#!/bin/bash

source ./print_functions.sh

# Creates a new wallet.
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - Name for the wallet
#   $2 - Use descriptors internally to handle address creation
create_wallet() {
  wallet_name=$1
  descriptors=$2

  createwallet_output=$(bitcoin-cli -named createwallet wallet_name="$wallet_name" descriptors=$descriptors)
  createwallet_output_name=$(echo $createwallet_output | jq -r '.name')

  if [ "$wallet_name" != "$createwallet_output_name" ]; then
    (echo >&2 $(print_error "Failed to create wallet '$wallet_name'"))
    exit 1
  fi
}
