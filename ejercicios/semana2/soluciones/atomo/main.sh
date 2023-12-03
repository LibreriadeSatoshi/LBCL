#!/bin/bash

source ./create_transaction_function.sh
source ./create_wallet_function.sh
source ./generate_address_function.sh
source ./generate_change_address_function.sh
source ./mine_until_balance_function.sh
source ./print_functions.sh
source ./print_transaction_details_function.sh
source ./send_transaction_function.sh
source ./sign_transaction_function.sh

# Prepares the environment:
#   1. Create wallets 'Miner' and 'Trader'
#   2. Generate miner address and mine until Miner balance >= 150 BTC
create_wallets_and_mine() {
  print_info "Creating wallets 'Miner' and 'Trader'"
  create_wallet "Miner"
  create_wallet "Trader"

  print_info "Generating Miner address with label 'Mining reward'"
  miner_address=$(generate_address "Miner" "Mining reward")
  print_success "Miner address generated: $miner_address"

  print_info "Mining until Miner balance of 150 BTC"
  miner_balance=$(mine_until_balance "Miner" "$miner_address" 150)
  print_success "Miner balance: $miner_balance"
}

# Creates, signs and sends the parent transaction, which has:
# - 2 inputs:
#   - input 0: first block mining reward of 50 BTC
#   - input 1: secod block mining reward of 50 BTC
# - 2 outputs:
#   - output 0: payment of 70 BTC to the Trader
#   - output 1: change of 29.99999000 BTC to the Miner
# That leaves a reward of 0.00001 BTC (1,000 sats)
create_sign_and_send_parent_transaction() {
  print_info "Generating Trader address with label 'Payment to trader'"
  trader_address=$(generate_address "Trader" "Payment to trader")
  print_success "Trader address generated: $trader_address"

  print_info "Generating Miner change address"
  miner_change_address=$(generate_change_address "Miner")
  print_success "Miner change address generated: $miner_change_address"

  # Get all spendable miner's utxos and check whether there are 2 unspent utxos
  miner_unspent_utxos=$(bitcoin-cli -rpcwallet="Miner" listunspent | jq -r '[.[] | select(.spendable | true)]')
  miner_unspent_utxos_length=$(echo $miner_unspent_utxos | jq -r '. | length' | bc)
  if [[ $miner_unspent_utxos_length -lt 2 ]]; then
    print_error "Insufficient amount ($miner_unspent_utxos_length) of spendable utxos in the wallet 'Miner'"
    exit 1
  fi

  # Set input 0
  transaction_parent_vin_0=$(echo $miner_unspent_utxos | jq -r '.[0] | { "txid": .txid, "vout": .vout }')
  # Set input 1
  transaction_parent_vin_1=$(echo $miner_unspent_utxos | jq -r '.[1] | { "txid": .txid, "vout": .vout }')
  # Set output 0 (payment)
  transaction_parent_vout_0="{ \"$trader_address\": 70 }"
  # Set output 1 (change)
  transaction_parent_vout_1="{ \"$miner_change_address\": 29.99999 }"

  # Set parent transaction inputs and make them RBF with sequence=1
  transaction_parent_inputs="[$(echo $transaction_parent_vin_0 | jq -r ". += { sequence: 1 }"), $(echo $transaction_parent_vin_1 | jq -r ". += { sequence: 1 }")]"
  # Set parent transaction outputs
  transaction_parent_outputs="[$transaction_parent_vout_0, $transaction_parent_vout_1]"

  print_info "Creating parent transaction"
  transaction_parent=$(create_transaction "$transaction_parent_inputs" "$transaction_parent_outputs")
  print_success "Parent transaction created: $transaction_parent"

  print_info "Signing parent transaction"
  transaction_parent_signed=$(sign_transaction "Miner" "$transaction_parent" | jq -r '.hex')
  print_success "Parent transaction signed: $transaction_parent_signed"

  print_info "Sending parent transaction"
  transaction_parent_txid=$(send_transaction "$transaction_parent_signed")
  print_success "Parent transaction sent with txid '$transaction_parent_txid'"

  print_info "Parent transaction details:\n"
  print_transaction_details "$transaction_parent_txid"

  print_info "Parent transaction mempool details:\n"
  bitcoin-cli getmempoolentry "$transaction_parent_txid" | jq -r
}

# Creates, signs and sends the child transaction, which has:
# - 1 input:
#   - input 0: parent transaction vout 0 (29.99999 BTC)
# - 1 output:
#   - output 0: change of 29.99998 BTC to the Miner
# That leaves a reward of 0.00001 BTC (1,000 sats)
create_sign_and_send_child_transaction() {
  # Decode parent transaction so that we can get the txid and vout
  transaction_parent_decoded=$(bitcoin-cli decoderawtransaction "$transaction_parent")
  transaction_parent_txid=$(echo $transaction_parent_decoded | jq -r ".txid")

  print_info "Generating new Miner address with label 'Mining reward child'"
  miner_address_child=$(generate_address "Miner" "Mining reward child")
  print_success "New Miner address generated: $miner_address_child"

  # Set child transaction input 0
  transaction_child_vin_0="{ \"txid\": \"$transaction_parent_txid\", \"vout\": 1 }"
  # Set child transaction output 0 (payment)
  transaction_child_vout_0="{ \"$miner_address_child\": 29.99998 }"

  # Set child transaction inputs
  transaction_child_inputs="[$transaction_child_vin_0]"
  # Set child transaction outputs
  transaction_child_outputs="[$transaction_child_vout_0]"

  print_info "Creating child transaction"
  transaction_child=$(create_transaction "$transaction_child_inputs" "$transaction_child_outputs")
  print_success "Child transaction created: $transaction_child"

  print_info "Signing child transaction"
  transaction_child_signed=$(sign_transaction "Miner" "$transaction_child" | jq -r '.hex')
  print_success "Child transaction signed: $transaction_child_signed"

  print_info "Sending child transaction"
  transaction_child_txid=$(send_transaction "$transaction_child_signed")
  print_success "Child transaction sent with txid '$transaction_child_txid'"

  print_info "Child transaction details:\n"
  print_transaction_details "$transaction_child_txid"

  print_info "Child transaction mempool details:\n"
  # NOTE We can see that this transaction depends on the parent one (transaction_parent_txid)
  bitcoin-cli getmempoolentry "$transaction_child_txid" | jq -r
}

# Creates, signs and sends the new parent transaction, which has:
# - 2 inputs (the same inputs as the parent transaction):
#   - input 0: first block mining reward of 50 BTC
#   - input 1: secod block mining reward of 50 BTC
# - 2 outputs:
#   - output 0: payment of 70 BTC to the Trader
#   - output 1: change of 29.99990000 BTC to the Miner
# That leaves a reward of 0.0001 BTC (10,000 sats)
create_sign_and_send_new_parent_transaction() {
  # The new transaction has the very same inputs as the parent transaction
  transaction_parent_replace_inputs=$transaction_parent_inputs

  # Set output 0 (payment)
  transaction_parent_replace_vout_0="{ \"$trader_address\": 70 }"
  # Set output 1 (change)
  transaction_parent_replace_vout_1="{ \"$miner_change_address\": 29.9999 }"
  # Set new transaction outputs
  transaction_parent_replace_outputs="[$transaction_parent_replace_vout_0, $transaction_parent_replace_vout_1]"

  print_info "Creating new parent transaction"
  transaction_parent_replace=$(create_transaction "$transaction_parent_replace_inputs" "$transaction_parent_replace_outputs")
  print_success "New parent transaction created: $transaction_parent_replace"

  print_info "Signing new parent transaction"
  transaction_parent_replace_signed=$(sign_transaction "Miner" "$transaction_parent_replace" | jq -r '.hex')
  print_success "New parent transaction signed: $transaction_parent_replace_signed"

  print_info "Sending new parent transaction"
  transaction_parent_replace_txid=$(send_transaction "$transaction_parent_replace_signed")
  print_success "New parent transaction sent with txid '$transaction_parent_replace_txid'"

  print_info "New parent transaction details:\n"
  print_transaction_details "$transaction_parent_replace_txid"

  print_info "New parent transaction mempool details:\n"
  bitcoin-cli getmempoolentry "$transaction_parent_replace_txid" | jq -r
}

create_wallets_and_mine
create_sign_and_send_parent_transaction
create_sign_and_send_child_transaction
create_sign_and_send_new_parent_transaction

print_info "Child transaction mempool details:"
print_warning "We expect the error 'Transaction not in mempool' because the first parent transaction does not exist anymore."
print_warning "The first parent transaction should have been replaced by the new one.\n"
bitcoin-cli getmempoolentry "$transaction_child_txid" | jq -r
