#!/bin/bash

source ./print_functions.sh

# Submits a raw transaction and returns the transaction hash in hex.
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - serialized and hex-encoded transaction
send_transaction() {
  hexstring=$1

  send_transaction_output=$(bitcoin-cli sendrawtransaction "$hexstring")

  if [ ! -z "$send_transaction_output" ]; then
    echo "$send_transaction_output"
  else
    (>&2 echo $(print_error "Failed to send transaction '$hexstring'"))
    exit 1
  fi
}
