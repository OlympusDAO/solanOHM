#!/bin/bash

# Usage: ./shell/bridge_from_evm.sh
#   --network <devnet|mainnet>
#   --amount <amount>
#   --to <recipient-address>
#   --account <cast account>
#   [--broadcast <true|false>]

# Exit if any error occurs
set -e

# Load named arguments
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $SCRIPT_DIR/lib/arguments.sh
source $SCRIPT_DIR/lib/solana.sh
load_named_args "$@"

# Set sane defaults
BROADCAST=${broadcast:-false}

# Validate named arguments
echo ""
echo "Validating arguments"
validate_network "$network"
validate_text "$to" "Error: the --to argument must be set and be a valid Solana address"
validate_number "$amount" "Error: the --amount argument must be set and be a valid number in wei"
validate_text "$account" "Cast account must be specified using the --account flag"

# Validate that the to address is in the format of a Solana address
# A-Za-z0-9 characters, 44 characters long
if [[ ! "$to" =~ ^[A-Za-z0-9]{44}$ ]]; then
    display_error "Error: the --to argument must be set and be a valid Solana address"
    exit 1
fi

# Get the eid from the environment
TO_EID=$(jq -r ".${network}.solana.eid" env.json)
if [ -z "$TO_EID" ]; then
    display_error "Error: eid is not set for network $network"
    exit 1
fi

# Determine the source EID
if [ "$network" == "devnet" ]; then
    BRIDGE_ADDRESS="0x56A07e0b05D60EF41318c60935c57924804d4541"
    FROM_OHM="0x75201BC8207fb06bFEc6CD0AbA99451320aa8e89"
    FROM_MINTER="0x09F317888a27E14bBFb78Ea53B89De3c23e617BB"
    RPC_URL="https://gateway.tenderly.co/public/sepolia"
    FROM_EID=10161
elif [ "$network" == "mainnet" ]; then
    BRIDGE_ADDRESS="0x45e563c39cDdbA8699A90078F42353A57509543a"
    FROM_OHM="0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5"
    FROM_MINTER="0xa90bFe53217da78D900749eb6Ef513ee5b6a491e"
    RPC_URL="https://eth.llamarpc.com"
    FROM_EID=101
else
    display_error "Invalid network: $network"
    exit 1
fi

# Get the address of the cast account
echo "Getting the address of the cast account"
CAST_ACCOUNT_ADDRESS=$(cast wallet address --account $account)

# Encode the Solana recipient address as bytes
TO_BYTES="0x"$(echo $to | bs58 -d | xxd -p -c 32)

# Set the broadcast flag
BROADCAST=${broadcast:-false}
if [ "$BROADCAST" == "true" ]; then
    BROADCAST_FLAG="--broadcast"
else
    BROADCAST_FLAG=""
fi

echo ""
echo "Summary:"
echo "  Network: $network"
echo "  Cast Account: $account"
echo "  Cast Account Address: $CAST_ACCOUNT_ADDRESS"
echo "  RPC URL: $RPC_URL"
echo "  Broadcast: $broadcast"
echo "  From EID: $FROM_EID"
echo "  From Bridge: $BRIDGE_ADDRESS"
echo "  From Ohm: $FROM_OHM"
echo "  From Minter: $FROM_MINTER"
echo "  To EID: $TO_EID"
echo "  Recipient: $to"
echo "  Recipient Bytes: $TO_BYTES"
echo "  Amount: $amount"
echo ""

echo "Sending the OHM"
forge script script/Bridge.s.sol:BridgeScript \
    --rpc-url $RPC_URL \
    --account $account \
    -vvv \
    --sig "bridge(uint16,address,address,address,uint16,bytes,uint256)" \
    $FROM_EID $BRIDGE_ADDRESS $FROM_OHM $FROM_MINTER $TO_EID $TO_BYTES $amount \
    $BROADCAST_FLAG
