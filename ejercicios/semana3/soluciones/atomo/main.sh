#!/bin/bash

source ./create_wallet_function.sh
source ./generate_address_function.sh
source ./generate_change_address_function.sh
source ./mine_to_address_function.sh
source ./mine_until_balance_function.sh
source ./print_functions.sh
source ./print_transaction_details_function.sh
source ./send_transaction_function.sh

MULTISIG_ADDRESS=""
PSBT_TRANSACTION_ID=""

# Creates the wallets 'Miner', 'Alice' and 'Bob' without descriptors.
create_wallets() {
  print_info "Creating wallets 'Miner', 'Alice' and 'Bob' without descriptors..."

  create_wallet "Miner" false
  create_wallet "Alice" false
  create_wallet "Bob" false
}

# Sends from to a wallet and mines 1 block
# Arguments:
#   - $1: origin wallet
#   - $2: target wallet
#   - $3: amount
send_fonds_to_wallet() {
  wallet_origin=$1
  wallet_target=$2
  amount=$3

  print_info "Sending $amount BTC from wallet '$wallet_origin' to wallet '$wallet_target'..."

  print_info "Generating address for wallet '$wallet_target'..."
  target_address=$(generate_address "$wallet_target")
  print_info "Address for wallet '$wallet_target' generated: $target_address"

  sendtoaddress_output=$(bitcoin-cli -rpcwallet="$wallet_origin" -named sendtoaddress address="$target_address" amount=$amount)

  if [ ! -z "$sendtoaddress_output" ]; then
    print_success "$amount BTC successfully sent to address $target_address with txid $sendtoaddress_output"
  else
    (echo >&2 $(print_error "Failed to send $amount BTC from wallet '$wallet_origin' to wallet '$wallet_target' (address $target_address)"))
    exit 1
  fi
}

# Creates a 2-of-2 multisig address.
# Arguments:
#   - $1: pubkey 1
#   - $2: pubkey 2
create_multisig_2_of_2() {
  pubkey_1=$1
  pubkey_2=$2

  createmultisig_output=$(bitcoin-cli -named createmultisig nrequired=2 keys="[\"$pubkey_1\",\"$pubkey_2\"]")

  if [ ! -z "$createmultisig_output" ]; then
    echo $createmultisig_output
  else
    (echo >&2 $(print_error "Failed to create multisig 2-of-2 address"))
    exit 1
  fi
}

# Generates an address and returns the pubkey
# Arguments:
#   - $1: wallet name
generate_address_and_get_pubkey() {
  wallet_name=$1

  address=$(generate_address "$wallet_name")
  bitcoin-cli -rpcwallet="$wallet_name" -named getaddressinfo address="$address" | jq -r '.pubkey'
}

# Creates the multisig transaction via a PSBT
# Arguments:
#   - $1: multisig address
setup_multisig() {
  address=$1

  print_title "Create and send multisig"

  alice_change_address=$(generate_change_address "Alice")
  print_info "Alice change address generated: $alice_change_address"

  bob_change_address=$(generate_change_address "Bob")
  print_info "Bob change address generated: $bob_change_address"

  print_info "Creating PSBT..."

  # Get all spendable alice's utxos and check whether there is 1 unspent utxo
  alice_unspent_utxos=$(bitcoin-cli -rpcwallet="Alice" listunspent | jq -r '[.[] | select(.spendable | true)]')
  alice_unspent_utxos_length=$(echo $alice_unspent_utxos | jq -r '. | length' | bc)
  if [[ $alice_unspent_utxos_length -lt 1 ]]; then
    print_error "Insufficient amount ($alice_unspent_utxos_length) of spendable utxos in the wallet 'Alice'"
    exit 1
  fi

  # Get all spendable bob's utxos and check whether there is 1 unspent utxo
  bob_unspent_utxos=$(bitcoin-cli -rpcwallet="Bob" listunspent | jq -r '[.[] | select(.spendable | true)]')
  bob_unspent_utxos_length=$(echo $bob_unspent_utxos | jq -r '. | length' | bc)
  if [[ $bob_unspent_utxos_length -lt 1 ]]; then
    print_error "Insufficient amount ($bob_unspent_utxos_length) of spendable utxos in the wallet 'Bob'"
    exit 1
  fi

  # Set input 0
  psbt_vin_0=$(echo $alice_unspent_utxos | jq -r '.[0] | { "txid": .txid, "vout": .vout }')
  # Set input 1
  psbt_vin_1=$(echo $bob_unspent_utxos | jq -r '.[0] | { "txid": .txid, "vout": .vout }')
  # Set output 0 (payment)
  psbt_vout_0="{ \"$address\": 20 }"

  # NOTE The PSBT will pay a fee of 1,000 sats. Both Alice and Bob will pay half of them.
  # Set output 1 (alice change)
  psbt_vout_1="{ \"$alice_change_address\": 9.999995 }"
  # Set output 2 (bob change)
  psbt_vout_2="{ \"$bob_change_address\": 9.999995 }"

  # Set PSBT inputs
  psbt_inputs="[$psbt_vin_0, $psbt_vin_1]"
  # Set PSBT outputs
  psbt_outputs="[$psbt_vout_0, $psbt_vout_1, $psbt_vout_2]"

  psbt_transaction=$(bitcoin-cli -named createpsbt inputs="$psbt_inputs" outputs="$psbt_outputs")
  print_success "PSBT created: $psbt_transaction"
  print_info "Analyze PSBT:"
  bitcoin-cli -named analyzepsbt psbt="$psbt_transaction" | jq -r

  print_info "Processing PSBT by Alice..."
  psbt_transaction=$(bitcoin-cli -named -rpcwallet="Alice" walletprocesspsbt psbt="$psbt_transaction" | jq -r '.psbt')
  print_success "PSBT processed by Alice: $psbt_transaction"
  print_info "Analyze PSBT:"
  bitcoin-cli -named analyzepsbt psbt="$psbt_transaction" | jq -r

  print_info "Processing PSBT by Bob..."
  psbt_transaction=$(bitcoin-cli -named -rpcwallet="Bob" walletprocesspsbt psbt="$psbt_transaction" | jq -r '.psbt')
  print_success "PSBT processed by Bob: $psbt_transaction"
  print_info "Analyze PSBT:"
  bitcoin-cli -named analyzepsbt psbt="$psbt_transaction" | jq -r

  print_info "Finalizing PSBT..."
  psbt_transaction_finalized=$(bitcoin-cli finalizepsbt "$psbt_transaction")
  print_success "PSBT finalized:"
  echo $psbt_transaction_finalized | jq -r

  print_info "Sending PSBT..."
  PSBT_TRANSACTION_ID=$(send_transaction "$(echo $psbt_transaction_finalized | jq -r '.hex')")
  print_success "PSBT sent with txid '$PSBT_TRANSACTION_ID'"

  print_info "PSBT details:\n"
  print_transaction_details "$PSBT_TRANSACTION_ID"

  print_info "PSBT mempool details:\n"
  bitcoin-cli getmempoolentry "$PSBT_TRANSACTION_ID" | jq -r
}

# Settles the multisig transaction via a PSBT
# Arguments:
#   - $1: multisig address
settle_multisig() {
  print_title "Settle multisig"

  print_info "Import multisig address to Alice and Bob wallets..."

  print_info "Alice:"
  bitcoin-cli -rpcwallet="Alice" -named addmultisigaddress nrequired=2 keys='''["'$ALICE_PUBKEY'","'$BOB_PUBKEY'"]''' | jq -r

  print_info "Bob:"
  bitcoin-cli -rpcwallet="Bob" -named addmultisigaddress nrequired=2 keys='''["'$ALICE_PUBKEY'","'$BOB_PUBKEY'"]''' | jq -r

  print_info "Creating spend PSBT..."

  alice_address=$(generate_address "Alice")
  bob_address=$(generate_address "Bob")

  # Set input
  psbt_spend_vin_0="{ \"txid\": \"$PSBT_TRANSACTION_ID\", \"vout\": 0 }"

  # NOTE The spend PSBT will pay a fee of 1,000 sats. Both Alice and Bob will pay half of them.
  # Set output 1 (alice change)
  psbt_spend_vout_0="{ \"$alice_address\": 9.999995 }"
  # Set output 2 (bob change)
  psbt_spend_vout_1="{ \"$bob_address\": 9.999995 }"

  # Set PSBT inputs
  psbt_spend_inputs="[$psbt_spend_vin_0]"
  # Set PSBT outputs
  psbt_spend_outputs="[$psbt_spend_vout_0, $psbt_spend_vout_1]"

  psbt_transaction_spend=$(bitcoin-cli -named createpsbt inputs="$psbt_spend_inputs" outputs="$psbt_spend_outputs")
  print_success "Spend PSBT created: $psbt_transaction_spend"
  print_info "Analyze spend PSBT:"
  bitcoin-cli -named analyzepsbt psbt="$psbt_transaction_spend" | jq -r

  print_info "Processing spend PSBT by Alice..."
  psbt_transaction_spend=$(bitcoin-cli -named -rpcwallet="Alice" walletprocesspsbt psbt="$psbt_transaction_spend" | jq -r '.psbt')
  print_success "Spend PSBT processed by Alice: $psbt_transaction_spend"
  print_info "Analyze spend PSBT:"
  bitcoin-cli -named analyzepsbt psbt="$psbt_transaction_spend" | jq -r

  print_info "Processing spend PSBT by Bob..."
  psbt_transaction_spend=$(bitcoin-cli -named -rpcwallet="Bob" walletprocesspsbt psbt="$psbt_transaction_spend" | jq -r '.psbt')
  print_success "Spend PSBT processed by Bob: $psbt_transaction_spend"
  print_info "Analyze spend PSBT:"
  bitcoin-cli -named analyzepsbt psbt="$psbt_transaction_spend" | jq -r

  print_info "Finalizing spend PSBT..."
  psbt_transaction_spend_finalized=$(bitcoin-cli finalizepsbt "$psbt_transaction_spend")
  print_success "Spend PSBT finalized:"
  echo $psbt_transaction_spend_finalized | jq -r

  print_info "Sending spend PSBT..."
  PSBT_TRANSACTION_SPEND_ID=$(send_transaction "$(echo $psbt_transaction_spend_finalized | jq -r '.hex')")
  print_success "Spend PSBT sent with txid '$PSBT_TRANSACTION_SPEND_ID'"

  print_info "Spend PSBT details:\n"
  print_transaction_details "$PSBT_TRANSACTION_SPEND_ID"

  print_info "Spend PSBT mempool details:\n"
  bitcoin-cli getmempoolentry "$PSBT_TRANSACTION_SPEND_ID" | jq -r
}

#########
# START #
#########

print_title "Preparing environment"

create_wallets

print_info "Generating Miner address with label 'Mining reward'..."
miner_address=$(generate_address "Miner" "Mining reward")
print_info "Miner address generated: $miner_address"

print_info "Mining until Miner balance of 200 BTC..."
miner_balance=$(mine_until_balance "Miner" "$miner_address" 200)
print_info "Miner balance: $miner_balance"

send_fonds_to_wallet "Miner" "Alice" 20
send_fonds_to_wallet "Miner" "Bob" 20

# Mine 1 block so that all pending transactions get confirmed
mine_to_address 1 "$miner_address"

alice_balance=$(bitcoin-cli -rpcwallet="Alice" getbalance)
print_info "Alice balance: $alice_balance"

bob_balance=$(bitcoin-cli -rpcwallet="Bob" getbalance)
print_info "Bob balance: $bob_balance"

# NOTE Create multisig 2-of-2 address (Alice and Bob)

print_title "Create multisig 2-of-2 address (Alice and Bob)"

ALICE_PUBKEY=$(generate_address_and_get_pubkey "Alice")
print_success "Alice pubkey: $ALICE_PUBKEY"

BOB_PUBKEY=$(generate_address_and_get_pubkey "Bob")
print_success "Bob pubkey: $BOB_PUBKEY"

multisig=$(create_multisig_2_of_2 "$ALICE_PUBKEY" "$BOB_PUBKEY")

print_info "Multisig 2-of-2 (Alice/Bob):\n"

echo "$multisig" | jq -r

MULTISIG_ADDRESS=$(echo $multisig | jq -r '.address')

# NOTE Setup multisig => create, fund and send PSBT:
# - the PSBT is founded by both Alice and Bob with 10 BTC each one
# - the PSBT pays a fee of 1,000 sats, where each party pays half of them
# - each party gets its change

setup_multisig "$MULTISIG_ADDRESS"

# Mine 1 block so that the PSBT gets mined
mine_to_address 1 "$miner_address"

alice_balance=$(bitcoin-cli -rpcwallet="Alice" getbalance)
print_info "Alice balance: $alice_balance"

bob_balance=$(bitcoin-cli -rpcwallet="Bob" getbalance)
print_info "Bob balance: $bob_balance"

# NOTE Settle multisig => create, fund and send spend PSBT:
# - the PSBT is founded by the multisig address (20 BTC)
# - the PSBT pays a fee of 1,000 sats, where each party pays half of them
# - there is no change

settle_multisig

# Mine 1 block so that the spend PSBT gets mined
mine_to_address 1 "$miner_address"

alice_balance=$(bitcoin-cli -rpcwallet="Alice" getbalance)
print_info "Alice balance: $alice_balance"

bob_balance=$(bitcoin-cli -rpcwallet="Bob" getbalance)
print_info "Bob balance: $bob_balance"
