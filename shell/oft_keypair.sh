#!/bin/bash

# Usage: ./shell/oft_keypair.sh

# Exit if any error occurs
set -e

# Load named arguments
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $SCRIPT_DIR/lib/arguments.sh
source $SCRIPT_DIR/lib/solana.sh
load_named_args "$@"

# Check if the keypairs already exist
if [ -f "target/deploy/endpoint-keypair.json" ] && [ -f "target/deploy/oft-keypair.json" ]; then
    echo "Keypairs already exist in target/deploy/"
    echo "  If you want to generate new keypairs, delete the existing files"
    exit 1
fi

# Determine the keypair being used
set_keypair_path

echo ""
echo "Summary:"
echo "  Keypair: $keypair_path"
echo ""

# Generate the keypairs
echo "Generating the keypairs"
solana-keygen new -o target/deploy/endpoint-keypair.json
solana-keygen new -o target/deploy/oft-keypair.json

echo "Syncing with Anchor"
anchor keys sync

# Get the OFT ID
ANCHOR_OUTPUT=$(anchor keys list)
OFT_ID=$(echo "$ANCHOR_OUTPUT" | grep "oft:" | sed 's/oft: //')
echo "OFT ID: $OFT_ID"
