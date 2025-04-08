#!/bin/bash

# Library for parsing and validating arguments

source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/error.sh

# @description Validates whether the network variable is set and valid
# @param {string} $1 The network to validate
validate_network() {
    if [ -z "$1" ]; then
        display_error "Provide the network as --network <devnet|mainnet>"
        exit 1
    fi

    if [ "$1" != "devnet" ] && [ "$1" != "mainnet" ]; then
        display_error "Invalid network: $1"
        display_error "Provide the network as --network <devnet|mainnet>"
        exit 1
    fi
}

set_keypair_path() {
    # Run the Solana CLI command to get the keypair path
    keypair_path=$(solana config get keypair)

    # Strip the leading text and return just the path
    keypair_path=$(echo "$keypair_path" | sed 's/^Key Path: //')

    # Verify that the keypair exists
    if [ ! -f $keypair_path ]; then
        display_error "Keypair not found at $keypair_path"
        exit 1
    fi
}
