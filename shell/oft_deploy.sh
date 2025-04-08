#!/bin/bash

# Usage: ./shell/oft_deploy.sh
#   --network <devnet|mainnet>
#   [--priority-fee <number>]
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

# Get the priority fee, if defined
priority_fee_flag=""
if [ -z "$priority_fee" ]; then
    priority_fee_flag=""
elif ! [[ "$priority_fee" =~ ^[0-9]+$ ]]; then
    display_error "Invalid priority fee: $priority_fee"
    display_error "Provide the priority fee as --priority-fee <number>"
    exit 1
else
    priority_fee_flag="--with-compute-unit-price $priority_fee"
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
set_public_key

echo ""
echo "Summary:"
echo "  Network: $network"
echo "  Keypair: $keypair_path"
echo "  Public Key: $public_key"
echo "  Priority Fee Flag: $priority_fee_flag"
echo ""

if [ "$broadcast" != "true" ]; then
    echo "Skipping broadcast"
    echo "  To broadcast the transaction, append '--broadcast true' to the command"
    exit 0
fi

# Switch the Solana version
echo "Switching to Solana 1.18.26"
sh -c "$(curl -sSfL https://release.solana.com/v1.18.26/install)"

# Deploy the OFT
echo "Deploying the OFT"
solana program deploy \
    --program-id target/deploy/oft-keypair.json target/verifiable/oft.so \
    -u $network \
    $priority_fee_flag

# Switch back to the previous Solana version
echo "Switching back to Solana 1.17.31"
sh -c "$(curl -sSfL https://release.solana.com/v1.17.31/install)"
