#!/bin/bash

# Usage: ./shell/oft_build.sh
#   --network <devnet|mainnet>

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

# Get the program ID from the environment
PROGRAM_ID=$(jq -r ".${network}.oft.programId" env.json)
if [ -z "$PROGRAM_ID" ]; then
    display_error "Error: programId is not set for network $network"
    exit 1
fi

echo ""
echo "Summary:"
echo "  Network: $network"
echo "  Program ID: $PROGRAM_ID"
echo ""

# Create the OFT
echo "Building the OFT program"
anchor build -v -e OFT_ID=$PROGRAM_ID
