#!/bin/bash

# Usage: ./shell/bridge_to_evm.sh
#   --network <devnet|mainnet>
#   --amount <amount>
#   --to <recipient-address>
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
validate_address "$to" "Error: the --to argument must be set and be a valid EVM address"
validate_number "$amount" "Error: the --amount argument must be set and be a valid number in wei"

# Get the eid from the environment
FROM_EID=$(jq -r ".${network}.solana.eid" env.json)
if [ -z "$FROM_EID" ]; then
    display_error "Error: eid is not set for network $network"
    exit 1
fi

# Determine the destination EID
if [ "$network" == "devnet" ]; then
    TO_EID=10161
elif [ "$network" == "mainnet" ]; then
    TO_EID=101
else
    display_error "Invalid network: $network"
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
echo "  From EID: $FROM_EID"
echo "  Program ID: $PROGRAM_ID"
echo "  Token Mint Address: $TOKEN_MINT_ADDRESS"
echo "  Escrow Address: $ESCROW_ADDRESS"
echo "  To EID: $TO_EID"
echo "  Recipient: $to"
echo "  Amount: $amount"
echo ""

if [ "$broadcast" != "true" ]; then
    echo "Skipping broadcast"
    echo "  To broadcast the transaction, append '--broadcast true' to the command"
    exit 0
fi

echo "Sending the tokens"
pnpm hardhat lz:oft:solana:send \
    --amount $amount \
    --from-eid $FROM_EID \
    --to $to \
    --to-eid $TO_EID
