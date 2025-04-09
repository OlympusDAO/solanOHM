#!/bin/bash

# Usage: ./shell/endpoint_solana.sh
#   --network <devnet|mainnet>
#   [--broadcast <true|false>]

# Exit if any error occurs
set -e

# Load named arguments
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $SCRIPT_DIR/lib/arguments.sh
source $SCRIPT_DIR/lib/solana.sh
load_named_args "$@"

# Validate named arguments
echo ""
echo "Validating arguments"
validate_network "$network"

# Get the eid from the environment
EID=$(jq -r ".${network}.solana.eid" env.json)
if [ -z "$EID" ]; then
    display_error "Error: eid is not set for network $network"
    exit 1
fi

# Get the layerzero config
if [ "$network" == "devnet" ]; then
    LAYERZERO_CONFIG="layerzero-devnet.config.ts"
elif [ "$network" == "mainnet" ]; then
    LAYERZERO_CONFIG="layerzero-mainnet.config.ts"
else
    display_error "Invalid network: $network"
    display_error "Provide the network as --network <devnet|mainnet>"
    exit 1
fi

# Determine the keypair being used
set_keypair_path
set_public_key

echo ""
echo "Summary:"
echo "  Network: $network"
echo "  Keypair: $keypair_path"
echo "  Public Key: $public_key"
echo "  EID: $EID"
echo "  LayerZero Config: $LAYERZERO_CONFIG"
echo ""

if [ "$broadcast" != "true" ]; then
    echo "Skipping broadcast"
    echo "  To broadcast the transaction, append '--broadcast true' to the command"
    exit 0
fi

echo "Initializing the OFT config"
pnpm hardhat lz:oft:solana:init-config \
    --oapp-config $LAYERZERO_CONFIG \
    --solana-eid $EID
