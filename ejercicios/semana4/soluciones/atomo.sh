#!/bin/bash

# Colors
color_blue='\033[0;34m'
color_green='\033[0;32m'
color_red='\033[0;31m'
color_yellow='\033[0;33m'
color_none='\033[0m'

# Creates a transaction with the given wallet
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - Transaction inputs
#   $2 - Transaction outputs
#   $3 - Transaction locktime
create_transaction() {
  local transaction_inputs=$1
  local transaction_outputs=$2
  local transaction_locktime=$3

  local create_transaction_output=$(bitcoin-cli -named createrawtransaction inputs="$transaction_inputs" outputs="$transaction_outputs" locktime="$transaction_locktime")

  if [ ! -z "$create_transaction_output" ]; then
    echo "$create_transaction_output"
  else
    (echo >&2 $(print_error "Failed to create transaction"))
    exit 1
  fi
}

# Creates a new wallet.
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - Name for the wallet
#   $2 - Use descriptors internally to handle address creation
create_wallet() {
  local wallet_name=$1
  local descriptors=$2

  local createwallet_output=$(bitcoin-cli -named createwallet wallet_name="$wallet_name" descriptors=$descriptors)
  local createwallet_output_name=$(echo $createwallet_output | jq -r '.name')

  if [ "$wallet_name" != "$createwallet_output_name" ]; then
    (echo >&2 $(print_error "Failed to create wallet '$wallet_name'"))
    exit 1
  fi
}

# Generate a new address for the given wallet and with the given label.
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - rpcwallet
#   $2 - label
generate_address() {
  local wallet_name=$1
  local address_label=$2

  local generate_address_output=$(bitcoin-cli -rpcwallet="$wallet_name" getnewaddress "$address_label")

  if [ ! -z "$generate_address_output" ]; then
    echo "$generate_address_output"
  else
    (echo >&2 $(print_error "Failed to generate address with label '$address_label' for wallet '$wallet_name'"))
    exit 1
  fi
}

# Generates a new change address for the given wallet and returns it.
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - rpcwallet
generate_change_address() {
  local wallet_name=$1

  local generate_change_address_output=$(bitcoin-cli -rpcwallet="$wallet_name" getrawchangeaddress)

  if [ ! -z "$generate_change_address_output" ]; then
    echo "$generate_change_address_output"
  else
    (echo >&2 $(print_error "Failed to generate change address with label for wallet '$wallet_name'"))
    exit 1
  fi
}

# Mines a certaing number of blocks.
# Arguments:
#   - $1: how many blocks are generated immediately
#   - $2: the address to send the newly generated bitcoin to
mine_to_address() {
  local nblocks=$1
  local address=$2

  local generatetoaddress_output=$(bitcoin-cli generatetoaddress $nblocks "$address")

  if [ ! -z "$generatetoaddress_output" ]; then
    print_success "Mined $nblocks block(s) to address $address"
  else
    (echo >&2 $(print_error "Failed to mine $nblocks block(s) to address $address"))
    exit 1
  fi
}

# Mines the necessary blocks until reaching a certain balance.
# Arguments:
#   $1 - Name for the wallet
#   $2 - Address to send the new generated bitcoin
#   $3 - Balance that the wallet must reach
mine_until_balance() {
  local wallet_name=$1
  local mining_address=$2
  local expected_wallet_balance=$(echo $3 | bc)

  local blocks_mined=0
  local wallet_balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance)

  while (($(echo "$wallet_balance" "$expected_wallet_balance" | awk '{if ($1 < $2) print 1; else print 0;}'))); do
    bitcoin-cli generatetoaddress 1 "$mining_address" >/dev/null
    blocks_mined=$(($blocks_mined + 1))
    wallet_balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance)
  done

  echo "$wallet_balance"
}

# Prints a formatted title with fixed lenght.
# Arguments:
#   $1 - Text to print out
print_title() {
  local text=$1

  local title_lenght=${#text}
  local title_suffix_length=$(expr 100 - ${title_lenght})

  printf "\n\n${color_blue}━━━ ${color_yellow}$1 ${color_blue}"
  for i in $(seq 1 $title_suffix_length); do printf "━"; done
  printf "${color_none}\n"
}

# Prints an info message.
# Arguments:
#   $1 - Text to print out
print_info() {
  echo "\n${color_none}$1"
}

# Prints success message in green.
# Arguments:
#   $1 - Text to print out
print_success() {
  echo "\n${color_green}$1${color_none}"
}

# Prints an error message in red.
# Arguments:
#   $1 - Text to print out
print_error() {
  echo "\n${color_red}$1${color_none}"
}

# Prints a warning message in yellow.
# Arguments:
#   $1 - Text to print out
print_warning() {
  echo "\n${color_yellow}$1${color_none}"
}

# Sends from to a wallet and mines 1 block
# Arguments:
#   - $1: origin wallet
#   - $2: target wallet
#   - $3: amount
send_fonds_to_wallet() {
  local wallet_origin=$1
  local wallet_target=$2
  local amount=$3

  print_info "Sending $amount BTC from wallet '$wallet_origin' to wallet '$wallet_target'..."

  print_info "Generating address for wallet '$wallet_target'..."
  local target_address=$(generate_address "$wallet_target")
  print_info "Address for wallet '$wallet_target' generated: $target_address"

  local sendtoaddress_output=$(bitcoin-cli -rpcwallet="$wallet_origin" -named sendtoaddress address="$target_address" amount=$amount)

  if [ ! -z "$sendtoaddress_output" ]; then
    print_success "$amount BTC successfully sent to address $target_address with txid $sendtoaddress_output"
  else
    (echo >&2 $(print_error "Failed to send $amount BTC from wallet '$wallet_origin' to wallet '$wallet_target' (address $target_address)"))
    exit 1
  fi
}

# Submits a raw transaction and returns the transaction hash in hex.
# If it fails, an error message will be printed out and the execution will exit.
# Arguments:
#   $1 - serialized and hex-encoded transaction
send_transaction() {
  local transaction_hex=$1

  local send_transaction_output=$(bitcoin-cli sendrawtransaction "$transaction_hex")

  if [ ! -z "$send_transaction_output" ]; then
    echo "$send_transaction_output"
  else
    (echo >&2 $(print_error "Failed to send transaction '$hexstring'"))
    exit 1
  fi
}

###############
# Ejercicio 1 #
###############

print_title "Create three wallets: Miner, Employee, and Employer."

print_info "Creating wallets..."
create_wallet "Miner" false
create_wallet "Employee" false
create_wallet "Employer" false

###############
# Ejercicio 2 #
###############

print_title "Fund the wallets by generating some blocks for Miner and sending some coins to Employer."

print_info "Generating Miner address with label 'Mining reward'..."
miner_address=$(generate_address "Miner" "Mining reward")
print_info "Miner address generated: $miner_address"

print_info "Mining until Miner balance of 200 BTC..."
miner_balance=$(mine_until_balance "Miner" "$miner_address" 200)
print_info "Miner balance: $miner_balance BTC"

send_fonds_to_wallet "Miner" "Employer" 50

# Mine 1 block so that all pending transactions in the mempool get confirmed
mine_to_address 1 "$miner_address"

print_info "Employer balance: $(bitcoin-cli -rpcwallet="Employer" getbalance) BTC"

###################
# Ejercicio 3 y 4 #
###################
print_title "Create a salary transaction of 40 BTC with absoulte timelock of 500 Blocks, where the Employer pays the Employee."

print_info "Generating Employee address with label 'Salary'..."
employee_address=$(generate_address "Employee" "Salary")
print_info "Employee address generated: $employee_address"

print_info "Generating Employee change address"
employer_change_address=$(generate_change_address "Employer")
print_success "Employer change address generated: $employer_change_address"

# Get all spendable Employer's utxos and check whether there is 1 unspent utxo
employer_unspent_utxos=$(bitcoin-cli -rpcwallet="Employer" listunspent | jq -r '[.[] | select(.spendable | true)]')
employer_unspent_utxos_length=$(echo $employer_unspent_utxos | jq -r '. | length' | bc)
if [[ $employer_unspent_utxos_length -lt 1 ]]; then
  print_error "Insufficient amount ($employer_unspent_utxos_length) of spendable utxos in the wallet 'Employer'"
  exit 1
fi

# Set transaction inputs
transaction_vin_0=$(echo $employer_unspent_utxos | jq -r '.[0] | { "txid": .txid, "vout": .vout }')
transaction_inputs="[$(echo $transaction_vin_0)]"

# Set transaction outputs
# UTXO 0: payment of 40 BTC from Employer to Employee
# UTXO 1: change to Employer. A fee of 1.000 sats is paid, so the Employer will get back 9.99999 BTC
transaction_vout_0_payment="{ \"$employee_address\": 40 }"
transaction_vout_1_change="{ \"$employer_change_address\": 9.99999 }"
transaction_outputs="[$transaction_vout_0_payment, $transaction_vout_1_change]"

print_info "Generating and signing transaction from Employer to Employee of 40 BTC..."
transaction=$(create_transaction "$transaction_inputs" "$transaction_outputs" "500")
transaction=$(bitcoin-cli -rpcwallet="Employer" signrawtransactionwithwallet "$transaction" | jq -r '.hex')
print_success "Employer transaction created: $transaction"

# NOTE The transaction has the input 500 in the field "locktime",
# which means that it can not be included in the mempool until this blockhight is reached.
print_info "Transaction details:\n"
bitcoin-cli decoderawtransaction "$transaction" | jq -r

###############
# Ejercicio 5 #
###############
print_title "Report in a comment what happens when you try to broadcast this transaction."

print_warning "When a transaction with a locktime is sent, the node will reject it because of the locktime."
print_warning "It is expected to get the error '-26: non-final' returned."
print_info "Response from the node:\n"
bitcoin-cli sendrawtransaction "$transaction"

###############
# Ejercicio 6 #
###############
print_title "Mine up to 500th block and broadcast the transaction."

block_count=$(bitcoin-cli getblockcount)
nblocks=$(echo "500 - $block_count" | bc)
mine_to_address "$nblocks" "$miner_address"

print_warning "Once we've reached the blockheight 500, the transaction can be sent."
print_info "Response from the node:\n"
bitcoin-cli sendrawtransaction "$transaction"

# Mine 1 block so that all pending transactions in the mempool get confirmed
mine_to_address 1 "$miner_address"

###############
# Ejercicio 7 #
###############
print_title "Print the final balances of Employee and Employer."

print_info "Employee balance: $(bitcoin-cli -rpcwallet="Employee" getbalance) BTC"
print_info "Employer balance: $(bitcoin-cli -rpcwallet="Employer" getbalance) BTC"

###################
# Ejercicio 8 y 9 #
###################
print_title "Create a spending transaction with data where the Employee spends the fund to a new Employee wallet address."

create_wallet "Employee Cold Wallet" false

print_info "Generating Employee address with label 'Move salary funds to cold wallet'..."
employee_address=$(generate_address "Employee Cold Wallet" "Move salary funds to cold wallet")
print_info "Employee Cold Wallet address generated: $employee_address"

# Get all spendable Employee's utxos and check whether there is 1 unspent utxo
employee_unspent_utxos=$(bitcoin-cli -rpcwallet="Employee" listunspent | jq -r '[.[] | select(.spendable | true)]')
employee_unspent_utxos_length=$(echo $employee_unspent_utxos | jq -r '. | length' | bc)
if [[ $employee_unspent_utxos_length -lt 1 ]]; then
  print_error "Insufficient amount ($employee_unspent_utxos_length) of spendable utxos in the wallet 'Employee'"
  exit 1
fi

# Set transaction inputs
transaction_vin_0=$(echo $employee_unspent_utxos | jq -r '.[0] | { "txid": .txid, "vout": .vout }')
transaction_inputs="[$(echo $transaction_vin_0)]"

# Set transaction outputs
# UTXO 0: move all funds but the fee of 1,000 sats
# UTXO 1: data "I got my salary, I am rich"
transaction_vout_0="{ \"$employee_address\": 39.99999 }"
# NOTE # Add an OP_RETURN output in the spending transaction with the string data "I got my salary, I am rich".
transaction_vout_1_data="{ \"data\": \"$(echo "I got my salary, I am rich" | xxd -p -c 1000000)\" }"
transaction_outputs="[$transaction_vout_0, $transaction_vout_1_data]"

print_info "Generating and signing transaction with data..."
transaction=$(create_transaction "$transaction_inputs" "$transaction_outputs" 0)
print_success "Employee transaction with data created: $transaction"

################
# Ejercicio 10 #
################
print_title "Extract and broadcast the fully signed transaction."

transaction=$(bitcoin-cli -rpcwallet="Employee" signrawtransactionwithwallet "$transaction" | jq -r '.hex')

# NOTE The hexadecimal value '4920676f74206d792073616c6172792c204920616d20726963680a'
# corresponds to the text 'I got my salary, I am rich'
print_info "Transaction details:\n"
bitcoin-cli decoderawtransaction "$transaction" | jq -r

send_transaction "$transaction" >/dev/null

# Mine 1 block so that all pending transactions in the mempool get confirmed
mine_to_address 1 "$miner_address"

################
# Ejercicio 11 #
################
print_title "Print the final balances of the Employee and Employer."

print_info "Employer balance: $(bitcoin-cli -rpcwallet="Employer" getbalance) BTC"
print_info "Employee balance: $(bitcoin-cli -rpcwallet="Employee" getbalance) BTC"
print_info "Employee Cold Wallet balance: $(bitcoin-cli -rpcwallet="Employee Cold Wallet" getbalance) BTC"
