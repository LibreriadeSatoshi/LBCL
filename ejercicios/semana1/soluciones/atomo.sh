#!/bin/bash

# Configuration
url="https://bitcoincore.org/bin/bitcoin-core-25.1/"
file="bitcoin-25.1-x86_64-linux-gnu.tar.gz"
file_checksums="SHA256SUMS"
file_signatures="SHA256SUMS.asc"

# Colors
color_blue='\033[0;34m'
color_green='\033[0;32m'
color_red='\033[0;31m'
color_yellow='\033[0;33m'
color_none='\033[0m'

# Prints a formatted title with a fixed lenght
# $1 - Text to print out
print_title() {
  title_lenght=$(expr length "$1")
  title_suffix_length=$(expr 100 - ${title_lenght})

  printf "\n\n${color_blue}━━━ ${color_yellow}$1 ${color_blue}"
  for i in $(seq 1 $title_suffix_length); do printf "━"; done
  printf "${color_none}\n\n"
}

# Prints an info message
# $1 - Text to print out
print_info() {
  echo -e "\n${color_none}$1"
}

# Prints success message in green
# $1 - Text to print out
print_success() {
  echo -e "\n${color_green}$1${color_none}"
}

# Prints an error message in red
# $1 - Text to print out
print_error() {
  echo -e "\n${color_red}$1${color_none}"
}

# Prints a warning message in yellow
# $1 - Text to print out
print_warning() {
  echo -e "\n${color_yellow}$1${color_none}"
}

# Download file
# $1 - URL
download_file() {
  print_info "Downloading file $1"
  wget --no-verbose --show-progress $1
}

# Install bitcoin core binary files
# $1 - Archive that contains the binary files
install_bitcoin_core() {
  print_info "Installing bitcoin core from file '$1'"
  tar -xf $1
  mv /bitcoin-25.1/bin/* /usr/local/bin/
}

# Starts bitcoin core creating all necessary resources
start_bitcoin_core () {
  print_info "Creating data directory..."
  mkdir -p /root/.bitcoin

  print_info "Creating bitcoin.conf in regtest mode..."
cat <<EOF >/root/.bitcoin/bitcoin.conf
    regtest=1
    fallbackfee=0.0001
    server=1
    txindex=1
EOF

  # bitcoind 2>&1 &
  bitcoind >/dev/null &

  # Wait 2 seconds so that bitcoin can fully start
  sleep 2
}

# Imports bitcoin core pubic keys
import_bitcoin_core_public_keys() {
  print_info "Importing bitcoin core public keys..."
  git clone --quiet https://github.com/bitcoin-core/guix.sigs
  gpg --import --quiet guix.sigs/builder-keys/*

  print_info "Refreshing PGP keys..."
  gpg --keyserver hkps://keys.openpgp.org --refresh-keys --quiet
}

# Validates a checksum
# $1 - File that contains the checksums
# $2 - File that will be validated
validate_checksum() {
  print_info "Validating checksum of '$2'..."

  # macOS: is_checksum_valid=$(shasum -a 512 -c $1 --ignore-missing | grep OK)
  is_checksum_valid=$(sha256sum -c $1 2>&1 | grep OK)

  if [ ${#is_checksum_valid} -eq 0 ]; then
    print_error "Invalid checksum!"
    exit 1
  else
    print_success "Valid checksum!"
  fi
}

# Validates a signature
# $1 - File that contains the signatures
# $2 - File that will be validated
validate_signature() {
  print_info "Validating signature of '$2'..."

  is_signature_valid=$(gpg --verify $1 $2 2>&1 >/dev/null | grep Good)

  if [ ${#is_signature_valid} -eq 0 ]; then
    print_error "Invalid signature!"
    exit 1
  else
    print_success "Valid signature!"
  fi
}

# Create a wallet
# $1 - Name for the wallet
create_wallet() {
  print_info "Creating wallet '$1'..."
  bitcoin-cli createwallet $1 >/dev/null
}

# Create all wallets ("Miner" and "Trader")
create_wallets() {
  create_wallet "Miner"
  create_wallet "Trader"
}

# Generate an address and saves it in $ADDRESS
# $1 - rpcwallet
# $2 - label
generate_address() {
  ADDRESS=$(bitcoin-cli -rpcwallet="$1" getnewaddress "$2")
  print_info "Generated address '$ADDRESS' for wallet '$1' with label '$2'"
}

# Mine a given number of blocks
# $1 - Number of blocks to mine
# $2 - Address to send the new generated bitcoin
mine_blocks() {
  print_info "Mining $1 block(s) to address '$2'..."
  bitcoin-cli generatetoaddress $1 "$2" >/dev/null
}

# Prints the balance of a wallet and saves the value in $BALANCE
# $1 - rpcwallet
print_wallet_balance() {
  BALANCE=$(bitcoin-cli -rpcwallet="$1" getwalletinfo | jq ".balance")
  print_info "Balance of wallet '$1': $BALANCE BTC"
}

# Sends funds to an address and saves the transaction id in $TRANSACTION_HASH
# $1 - Wallet
# $2 - Adress
# $3 - Amount of bitcoins
# $4 - Label
send_to_address() {
  TRANSACTION_HASH=$(bitcoin-cli -rpcwallet="$1" sendtoaddress "$2" $3 "$4")
  print_info "Sent $3 bitcoins to the address '$2' from the wallet '$1' and label '$4'. Transaction id: '$TRANSACTION_HASH'"
}

# Looks for a transaction in the mempool.
# $1 - Transaction id
print_mempoolentry() {
  entry=$(bitcoin-cli getmempoolentry "$1")
  has_error=$(cat "$entry" 2>&1 >/dev/null | grep "error code")

  if [ ${#has_error} -eq 0 ]; then
    print_success "Found transaction id '$1' in the mempool:"
    print_info "$entry"
  else
    print_error "Failed to find transaction id '$1' in the mempool!"
    print_warning "$entry"
    exit 1
  fi
}

# Prints a detailed transaction data
# $1 - Transaction id
print_detailed_transaction_data() {
  # Transaction
  raw_transaction=$(bitcoin-cli getrawtransaction $1)
  decoded_transaction=$(bitcoin-cli decoderawtransaction $raw_transaction)

  # Transaction input
  miner_transaction_id=$(echo $decoded_transaction | jq -r ".vin[0].txid")
  miner_raw_transaction=$(bitcoin-cli getrawtransaction $miner_transaction_id)
  miner_decoded_transaction=$(bitcoin-cli decoderawtransaction $miner_raw_transaction)
  miner_vout=$(echo $miner_decoded_transaction | jq -r ".vout[0]")
  miner_address=$(echo $miner_vout | jq -r ".scriptPubKey.address")
  miner_value=$(echo $miner_vout | jq -r ".value")

  # Transaction output 0
  transaction_vout_0=$(echo $decoded_transaction | jq -r ".vout[0]")
  transaction_vout_0_address=$(echo $transaction_vout_0 | jq -r ".scriptPubKey.address")
  transaction_vout_0_value=$(echo $transaction_vout_0 | jq -r ".value")

  # Transaction output 1
  transaction_vout_1=$(echo $decoded_transaction | jq -r ".vout[1]")
  transaction_vout_1_address=$(echo $transaction_vout_1 | jq -r ".scriptPubKey.address")
  transaction_vout_1_value=$(echo $transaction_vout_1 | jq -r ".value")

  # Check whether vout 0 belongs to the Miner
  is_transaction_vout_0_miner=$(bitcoin-cli -rpcwallet="Miner" getaddressinfo $transaction_vout_0_address | jq ".ismine")

  if [ $is_transaction_vout_0_miner == 'true' ]; then
    miner_change_address=$transaction_vout_0_address
    miner_change_value=$transaction_vout_0_value
    trader_address=$transaction_vout_1_address
    trader_value=$transaction_vout_1_value
  else
    miner_change_address=$transaction_vout_1_address
    miner_change_value=$transaction_vout_1_value
    trader_address=$transaction_vout_0_address
    trader_value=$transaction_vout_0_value
  fi

  # Get transaction blockheight
  trader_transaction=$(bitcoin-cli -rpcwallet="Trader" gettransaction $1)
  trader_transaction_blockheight=$(echo $trader_transaction | jq -r ".blockheight")

  # Get wallet balances
  miner_balance=$(bitcoin-cli -rpcwallet="Miner" getwalletinfo | jq ".balance")
  trader_balance=$(bitcoin-cli -rpcwallet="Trader" getwalletinfo | jq ".balance")

  # Calculate fees
  fees=$(echo $miner_value - $trader_value - $miner_change_value | bc)

  # Print report
  echo -e "\n${color_blue}txid: ${color_none}$1"
  echo -e "${color_blue}<From, Amount>: ${color_none}${miner_address}, ${miner_value}"
  echo -e "${color_blue}<Send, Amount>: ${color_none}${trader_address}, ${trader_value}"
  echo -e "${color_blue}<Change, Amount>: ${color_none}${miner_change_address}, ${miner_change_value}"
  echo -e "${color_blue}Comisiones: ${color_none}${fees}"
  echo -e "${color_blue}Bloque: ${color_none}${trader_transaction_blockheight}"
  echo -e "${color_blue}Saldo de Miner: ${color_none}$miner_balance"
  echo -e "${color_blue}Saldo de Trader: ${color_none}$trader_balance"
}

################
# START SCRIPT #
################

print_title "Download, validate, install and start bitcoin core"
download_file "$url$file"
download_file "$url$file_checksums"
download_file "$url$file_signatures"
import_bitcoin_core_public_keys
validate_signature $file_signatures $file_checksums
validate_checksum $file_checksums $file
install_bitcoin_core $file
start_bitcoin_core

print_title "Create 'Miner' and 'Trader' wallets and mine blocks"
create_wallets
generate_address "Miner" "Recompensa de Minería"
# Save miner address
MINER_ADDRESS=$ADDRESS
# Mine 101 blocks because the miners can spend the rewards once the block has a hight greater than 100
mine_blocks 101 $MINER_ADDRESS
print_wallet_balance "Miner"

print_title "Send fonds from 'Miner' to 'Trader'"
generate_address "Trader" "Recibido"
# Save trader address
TRADER_ADDRESS=$ADDRESS
send_to_address "Miner" $TRADER_ADDRESS 20 "Send to trader"
print_mempoolentry $TRANSACTION_HASH
mine_blocks 1 $MINER_ADDRESS

print_title "Print detailed transaction data"
print_detailed_transaction_data $TRANSACTION_HASH
