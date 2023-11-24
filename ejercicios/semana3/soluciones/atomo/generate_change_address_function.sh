#!/bin/bash

source ./print_functions.sh

# Generates a new change address for the given wallet and returns it.
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - rpcwallet
generate_change_address() {
  wallet_name=$1

  generate_change_address_output=$(bitcoin-cli -rpcwallet="$wallet_name" getrawchangeaddress)

  if [ ! -z "$generate_change_address_output" ]; then
    echo "$generate_change_address_output"
  else
    (>&2 echo $(print_error "Failed to generate change address with label for wallet '$wallet_name'"))
    exit 1
  fi
}
