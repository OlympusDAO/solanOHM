#!/bin/bash

# Usage: ./shell/endpoint_evm.sh
#   --network <devnet|mainnet>
#   --account <cast account>
#   [--broadcast <true|false>]

# Exit if any error occurs
set -e

# Load named arguments
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $SCRIPT_DIR/lib/arguments.sh
source $SCRIPT_DIR/lib/solana.sh
load_named_args "$@"

# Set sane defaults
BROADCAST=${broadcast:-false}

# Validate named arguments
echo ""
echo "Validating arguments"
validate_network "$network"
validate_text "$account" "Cast account must be specified using the --account flag"

# Get the eid from the environment
DEST_EID=$(jq -r ".${network}.solana.eid" env.json)
if [ -z "$DEST_EID" ]; then
    display_error "Error: eid is not set for network $network"
    exit 1
fi

# Get the OFT store from the environment
OFT_STORE=$(jq -r ".${network}.oft.oftStore" env.json)
if [ -z "$OFT_STORE" ]; then
    display_error "Error: OFT store is not set for network $network"
    exit 1
fi

# Determine the EVM bridge address
if [ "$network" == "mainnet" ]; then
    BRIDGE_ADDRESS="0x45e563c39cDdbA8699A90078F42353A57509543a"
    RPC_URL="https://eth.llamarpc.com"
    SOURCE_EID=101
elif [ "$network" == "devnet" ]; then
    BRIDGE_ADDRESS="0x953E1F2AF5D51Bbf28aD96659B49efd9fa06E34a"
    RPC_URL="https://gateway.tenderly.co/public/sepolia"
    SOURCE_EID=10161
else
    display_error "Invalid network: $network"
    exit 1
fi

# Encode the Solana OFT address as bytes32
SOLANA_OFT_ADDRESS_BYTES="0x"$(echo $OFT_STORE | bs58 -d | xxd -p -c 32)

# Get the address of the cast account
echo "Getting the address of the cast account"
CAST_ACCOUNT_ADDRESS=$(cast wallet address --account $account)

# Set the broadcast flag
BROADCAST_FLAG=""
if [ "$BROADCAST" == "true" ]; then
    BROADCAST_FLAG="--broadcast"
else
    echo "Skipping broadcast. To broadcast the transaction, append '--broadcast true' to the command"
fi

# Summary
echo ""
echo "Summary:"
echo "  Network: $network"
echo "  Cast Account: $account"
echo "  Cast Account Address: $CAST_ACCOUNT_ADDRESS"
echo "  RPC URL: $RPC_URL"
echo "  Broadcast: $BROADCAST"
echo ""
echo "  EVM Bridge Address: $BRIDGE_ADDRESS"
echo "  LayerZero Solana EID: $DEST_EID"
echo "  LayerZero EVM EID: $SOURCE_EID"
echo "  OFT Store: $OFT_STORE"
echo "  OFT Store (Bytes): $SOLANA_OFT_ADDRESS_BYTES"
echo ""

# Execute the script
forge script script/ConfigureCrossChainBridge.s.sol:ConfigureCrossChainBridge \
    --sig "run(address,bytes,uint16,uint16)" $BRIDGE_ADDRESS $SOLANA_OFT_ADDRESS_BYTES $SOURCE_EID $DEST_EID \
    --rpc-url $RPC_URL \
    --account $account \
    -vvv \
    --slow \
    $BROADCAST_FLAG
