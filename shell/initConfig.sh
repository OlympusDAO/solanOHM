#!/bin/bash

# Usage: ./shell/createOft.sh
#   --network <devnet|mainnet>
#   [--broadcast <true|false>]

# Exit if any error occurs
set -e

# Load named arguments
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $SCRIPT_DIR/lib/arguments.sh
load_named_args "$@"

# Validate named arguments
echo ""
echo "Validating arguments"
validate_text "$network" "No network specified. Provide the network as --network <devnet|mainnet>"

# Validate the network
if [ -z "$network" ] || [ "$network" != "devnet" ] && [ "$network" != "mainnet" ]; then
    display_error "Invalid network: $network"
    display_error "Provide the network as --network <devnet|mainnet>"
    exit 1
fi

# Get the eid from the environment
EID=$(jq -r ".${network}.solana.eid" env.json)
if [ -z "$EID" ]; then
    display_error "Error: eid is not set for network $network"
    exit 1
fi

echo ""
echo "Summary:"
echo "  Network: $network"
echo "  EID: $EID"
echo ""

if [ "$broadcast" == "false" ]; then
    echo "Skipping broadcast"
    echo "  To broadcast the transaction, append '--broadcast true' to the command"
    exit 0
fi

# TODO
# Fix RPC URL error

pnpm hardhat lz:oft:solana:init-config \
    --oapp-config layerzero.config.ts \
    --solana-eid $EID
