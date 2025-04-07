Follow the instructions here: https://github.com/LayerZero-Labs/devtools/blob/ac8912867862f6dd737b0febabd8d3cb8f142df7/examples/lzapp-migration/README.md

Install solana-verify: `cargo install solana-verify@0.3.1`

At the "Create the Solana OFT202 Accounts" step, continue with these commands.

Populate env.json with the values

`./shell/createOft.sh` (with the appropriate arguments)

Update "<network>.oft.oftStore" in env.json with the oftStore value from `deployments/solana-<network>/OFT.json`

`./shell/initConfig.sh` (solana -> destination)

Verify the OFT program: `./shell/verifyProgram.sh` (run Docker before)

Migrate OFT ownership to MS

`./shell/wire.sh` (destination -> solana) only if the caller ("bridge_admin") is not an MS

Update the config (e.g. new chains) here: https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/configuring-pathways
