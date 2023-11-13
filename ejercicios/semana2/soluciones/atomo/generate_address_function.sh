#!/bin/bash

source ./print_functions.sh

# Generate a new address for the given wallet and with the given label.
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - rpcwallet
#   $2 - label
generate_address() {
  wallet_name=$1
  address_label=$2

  generate_address_output=$(bitcoin-cli -rpcwallet="$wallet_name" getnewaddress "$address_label")

  if [ ! -z "$generate_address_output" ]; then
    echo "$generate_address_output"
  else
    (>&2 echo $(print_error "Failed to generate address with label '$address_label' for wallet '$wallet_name'"))
    exit 1
  fi
}
