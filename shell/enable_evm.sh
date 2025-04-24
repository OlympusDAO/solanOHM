#!/bin/bash

# Usage: ./shell/enable_evm.sh
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

# Get the EVM bridge address from the environment
BRIDGE_ADDRESS=$(jq -r ".${network}.ethereum.bridge" env.json)
if [ -z "$BRIDGE_ADDRESS" ]; then
    display_error "Error: bridge is not set for network $network"
    exit 1
fi

# Determine the RPC URL
if [ "$network" == "mainnet" ]; then
    RPC_URL="https://eth.llamarpc.com"
elif [ "$network" == "devnet" ]; then
    RPC_URL="https://gateway.tenderly.co/public/sepolia"
else
    display_error "Invalid network: $network"
    exit 1
fi

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
echo ""

# Execute the script
forge script script/ConfigureCrossChainBridge.s.sol:ConfigureCrossChainBridge \
    --sig "enableBridge(address)" $BRIDGE_ADDRESS \
    --rpc-url $RPC_URL \
    --account $account \
    -vvv \
    --slow \
    $BROADCAST_FLAG
