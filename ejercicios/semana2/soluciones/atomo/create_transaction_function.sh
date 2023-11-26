#!/bin/bash

source ./print_functions.sh

# Sign a transaction with the given wallet
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - Transaction inputs
#   $2 - Transaction outputs
create_transaction() {
  transaction_inputs=$1
  transaction_outputs=$2

  create_transaction_output=$(bitcoin-cli -named createrawtransaction inputs="$transaction_inputs" outputs="$transaction_outputs")

  if [ ! -z "$create_transaction_output" ]; then
    echo "$create_transaction_output"
  else
    (>&2 echo $(print_error "Failed to create transaction"))
    exit 1
  fi
}
