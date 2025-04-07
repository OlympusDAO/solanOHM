#!/bin/bash

# Verifies the OFT program on the given network
# Usage: ./shell/verifyProgram.sh
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

# Validate the keypair
KEYPAIR_FILE="~/.config/solana/id.json"
if [ -n "$keypair" ]; then
    if [ -f "$keypair" ]; then
        KEYPAIR_FILE="$keypair"
    else
        display_error "Error: Keypair file not found at $keypair"
        exit 1
    fi
fi

# Get the broadcast flag, if defined
broadcast=${broadcast:-false}
if [ "$broadcast" != "true" ] && [ "$broadcast" != "false" ]; then
    display_error "Invalid broadcast: $broadcast"
    display_error "Provide the broadcast as --broadcast <true|false>"
    exit 1
fi

# Get the program ID from the environment
PROGRAM_ID=$(jq -r ".${network}.oft.programId" env.json)
if [ -z "$PROGRAM_ID" ]; then
    display_error "Error: programId is not set for network $network"
    exit 1
fi

# Set the network flag
if [ "$network" == "devnet" ]; then
    NETWORK_FLAG="-ud"
elif [ "$network" == "mainnet" ]; then
    NETWORK_FLAG="-um"
else
    display_error "Invalid network: $network"
    display_error "Provide the network as --network <devnet|mainnet>"
    exit 1
fi

echo ""
echo "Summary:"
echo "  Network: $network"
echo "  Program ID: $PROGRAM_ID"
echo "  Keypair: $KEYPAIR_FILE"
echo ""

if [ "$broadcast" != "true" ]; then
    echo "Skipping broadcast"
    echo "  To broadcast the transaction, append '--broadcast true' to the command"
    exit 0
fi

echo "Verifying the OFT program"
solana-verify verify-from-repo \
    $NETWORK_FLAG \
    --program-id $PROGRAM_ID \
    --library-name oft \
    --keypair $KEYPAIR_FILE \
    https://github.com/OlympusDAO/solanOHM \
    -- --config env.OFT_ID=\'$PROGRAM_ID\'
