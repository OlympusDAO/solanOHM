#!/bin/bash

# Usage: ./shell/oft_create.sh
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

# Determine the keypair being used
set_keypair_path

# Specify the OFT file
OFT_FILE=""
if [ "$network" == "devnet" ]; then
    OFT_FILE="deployments/solana-testnet/OFT.json"
elif [ "$network" == "mainnet" ]; then
    OFT_FILE="deployments/solana-mainnet/OFT.json"
else
    display_error "Invalid network: $network"
    display_error "Provide the network as --network <devnet|mainnet>"
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
echo "  Keypair: $keypair_path"
echo "  Program ID: $PROGRAM_ID"
echo "  EID: $EID"
echo "  Additional Minters: None"
echo "  Token Name: $TOKEN_NAME"
echo "  Token Symbol: $TOKEN_SYMBOL"
echo "  Token Decimals: $TOKEN_DECIMALS"
echo "  Token Metadata URI: $TOKEN_METADATA_URI"
echo ""

if [ "$broadcast" != "true" ]; then
    echo "Skipping broadcast"
    echo "  To broadcast the transaction, append '--broadcast true' to the command"
    exit 0
fi

# Create the OFT
echo "Creating the OFT"
pnpm hardhat lz:oft:solana:create \
    --eid $EID \
    --program-id $PROGRAM_ID \
    --additional-minters "" \
    --local-decimals $TOKEN_DECIMALS \
    --name $TOKEN_NAME \
    --symbol $TOKEN_SYMBOL \
    --uri $TOKEN_METADATA_URI

# Get the OFT store value
OFT_STORE=$(jq -r ".oftStore" $OFT_FILE)
echo "OFT store: $OFT_STORE"

# Get the token address
TOKEN_ADDRESS=$(jq -r ".mint" $OFT_FILE)
echo "Token address: $TOKEN_ADDRESS"
