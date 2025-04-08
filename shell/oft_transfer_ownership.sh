#!/bin/bash

# Transfers ownership of the OFT program to the DAO multisig
# Usage: ./shell/oft_transfer_ownership.sh
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

# Get the owner from the environment
NEW_OWNER=$(jq -r ".${network}.olympus.daoMS" env.json)
if [ -z "$NEW_OWNER" ]; then
    display_error "Error: daoMS is not set for network $network"
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
echo "  Program ID: $PROGRAM_ID"
echo "  New Owner: $NEW_OWNER"
echo ""

if [ "$broadcast" != "true" ]; then
    echo "Skipping broadcast"
    echo "  To broadcast the transaction, append '--broadcast true' to the command"
    exit 0
fi

echo "Transferring ownership of the OFT program"
solana program set-upgrade-authority \
    --skip-new-upgrade-authority-signer-check \
    $PROGRAM_ID \
    --new-upgrade-authority $NEW_OWNER
