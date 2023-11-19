#!/bin/bash

source ./print_functions.sh

# Mines a certaing number of blocks.
# Arguments:
#   - $1: how many blocks are generated immediately
#   - $2: the address to send the newly generated bitcoin to
mine_to_address() {
  nblocks=$1
  address=$2

  generatetoaddress_output=$(bitcoin-cli generatetoaddress $nblocks "$address")

  if [ ! -z "$generatetoaddress_output" ]; then
    print_success "Mined $nblocks block(s) to address $address"
  else
    (echo >&2 $(print_error "Failed to mine $nblocks block(s) to address $address"))
    exit 1
  fi
}
