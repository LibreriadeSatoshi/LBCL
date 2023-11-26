#!/bin/bash

source ./print_functions.sh

# Returns the following transaction data: inputs, outputs, fees and vsize.
# Arguments:
#   $1 - transaction hash
print_transaction_details() {
  transaction_hash=$1

  # Get mempool entry so that we can get the fees and vsize
  mempoolentry=$(bitcoin-cli getmempoolentry "$transaction_hash")

  # Get and decode transaction so that we can get the inputs and outputs
  transaction_parent=$(bitcoin-cli getrawtransaction "$transaction_hash")
  transaction_parent_decoded=$(bitcoin-cli decoderawtransaction "$transaction_parent")

  # Get transaction fees
  mempoolentry_fees=$(echo $mempoolentry | jq -r ".fees.base")
  # Get transaction vsize
  mempoolentry_vsize=$(echo $mempoolentry | jq -r ".vsize")
  # Get transaction inputs
  mempoolentry_inputs=$(echo $transaction_parent_decoded | jq -r ".vin | [.[] | { txid, vout }]")
  # Get transaction outputs
  mempoolentry_outputs=$(echo $transaction_parent_decoded | jq -r ".vout | [.[] | { \"script_pubkey\": .scriptPubKey.address, \"amount\": .value }]")

  # Build output details
  mempoolentry_details="{ \"input\": $mempoolentry_inputs, \"output\": $mempoolentry_outputs, \"fees\": $mempoolentry_fees, \"weight\": $mempoolentry_vsize }"

  echo $mempoolentry_details | jq -r
}
