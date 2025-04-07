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

# Get the eid from the environment
EID=$(jq -r ".${network}.solana.eid" env.json)
if [ -z "$EID" ]; then
    display_error "Error: eid is not set for network $network"
    exit 1
fi

# Get the owner from the environment
OWNER=$(jq -r ".${network}.olympus.owner" env.json)
if [ -z "$OWNER" ]; then
    display_error "Error: owner is not set for network $network"
    exit 1
fi

# Define other attributes
TOKEN_NAME="Olympus"
TOKEN_SYMBOL="OHM"
TOKEN_DECIMALS=9
TOKEN_METADATA_URI="https://raw.githubusercontent.com/OlympusDAO/solanOHM/62f0a01f8b5387d2865e6e84e6da28489dda55b8/assets/metadata.json"

echo ""
echo "Summary:"
echo "  Network: $network"
echo "  Program ID: $PROGRAM_ID"
echo "  EID: $EID"
echo "  Owner: $OWNER"
echo "  Additional Minters: None"
echo "  Token Name: $TOKEN_NAME"
echo "  Token Symbol: $TOKEN_SYMBOL"
echo "  Token Decimals: $TOKEN_DECIMALS"
echo "  Token Metadata URI: $TOKEN_METADATA_URI"
echo ""

if [ "$broadcast" == "false" ]; then
    echo "Skipping broadcast"
    echo "  To broadcast the transaction, append '--broadcast true' to the command"
    exit 0
fi

# Create the OFT
pnpm hardhat lz:oft:solana:create \
    --eid $EID \
    --program-id $PROGRAM_ID \
    --additional-minters "" \
    --local-decimals $TOKEN_DECIMALS \
    --name $TOKEN_NAME \
    --symbol $TOKEN_SYMBOL \
    --uri $TOKEN_METADATA_URI
