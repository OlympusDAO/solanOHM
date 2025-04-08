#!/bin/bash

PRIVATE_KEY=$(npx hardhat lz:solana:base-58 --keypair-file ~/.config/solana/olympus-deployer.json)
echo "Private Key: $PRIVATE_KEY"
