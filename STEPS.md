Follow the instructions here: https://github.com/LayerZero-Labs/devtools/blob/ac8912867862f6dd737b0febabd8d3cb8f142df7/examples/lzapp-migration/README.md


At the "Create the Solana OFT202 Accounts" step, continue with these commands.

Populate env.json with the values

`./shell/createOft.sh` (with the appropriate arguments)

Update "<network>.oft.oftStore" in env.json with the oftStore value from `deployments/solana-<network>/OFT.json`

