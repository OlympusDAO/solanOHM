# solanOHM

This repository is a modified version of the LayerZero [Endpoint V1 + Solana OFT](https://github.com/LayerZero-Labs/devtools/tree/c097c4fa9d3ae307755338dad7a581fc93e9f97e/examples/lzapp-migration) example. It has been modified to support Olympus' bridge setup using Endpoint V1 and the LzApp approach (see the [CrossChainBridge policy](https://github.com/OlympusDAO/olympus-v3/blob/7303abb70ed055a7063210ea9641c3a2490c34d4/src/policies/CrossChainBridge.sol)).

It provides:

- Deployment of an OFT on Solana
- Setting the mainnet/sepolia CrossChainBridge policy as a trusted remote

## Setup

### Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
```

### Install Solana

```bash
sh -c "$(curl -sSfL https://release.solana.com/v1.17.31/install)"
```

### Install Anchor

Install and use the correct version

```bash
cargo install --git https://github.com/coral-xyz/anchor --tag v0.29.0 anchor-cli --locked
```

### Install solana-verify

`cargo install solana-verify`

### Install Deployer Keypair

#### Olympus Deployer

If using the Olympus Deployer wallet, place the keypair in the `~/.config/solana/olympus-deployer.json` file.

Then configure the Solana CLI to use that keypair by default: `solana config set --keypair ~/.config/solana/olympus-deployer.json`

#### Other Wallet

Otherwise, the default wallet at `~/.config/solana/id.json` will be used. You may need to create this.

### Install OFT Program Keypair

#### Existing Keypairs

Place the keypair files in `target/deploy/endpoint-keypair.json` and `target/deploy/oft-keypair.json`. These will need to be manually shared. These keypairs are tied to the deployer keypair, and must be re-generated if the keypair is changed.

#### New Keypairs

```bash
./shell/oft_keypair.sh
```

Ensure the following files have the updated OFT ID:

- Anchor.toml: programs.localnet.oft
- env.json: <network>.oft.programId (for all affected networks)

### Get Devnet SOL

```bash
solana airdrop 5 -u devnet
```

We recommend that you request 5 devnet SOL, which should be sufficient for this walkthrough. For the example here, we will be using Solana Devnet. If you hit rate limits, you can also use the [official Solana faucet](https://faucet.solana.com/).

### Prepare `.env`

```bash
cp .env.example .env
```

In the `.env` just created, set `SOLANA_PRIVATE_KEY` to your private key value in base58 format. Since the locally stored keypair is in an integer array format, we'd need to encode it into base58 first.

You can run the `npx hardhat lz:solana:base-58` to output your private key in base58 format. Optionally, pass in a value for the `--keypair-file` flag if you want to use the keypair other than the default at `~/.config/solana/id.json`

Also set the `RPC_URL_SOLANA_TESTNET` value. Note that while the naming used here is `TESTNET`, it refers to the [Solana Devnet](https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts#solana-testnet). We use `TESTNET` to keep it consistent with the existing EVM testnets.

### Install Dependencies

`pnpm install`

## Config

The local scripts use the [env.json](env.json) file to store configuration variables.

LayerZero requires an additional configuration file. The local scripts will use [layerzero-testnet.config.ts] or [layerzero-mainnet.config.ts] automatically, depending on the network specified.

### Adding a New Network

TODO

https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/configuring-pathways

## Deployment

The steps below can be used for either the Solana testnet/devnet or mainnet by changing the appropriate flag.

### Configure Solana CLI

Configure the Solana CLI to use the correct RPC URL:

```bash
solana config set --url <devnet|mainnet>
```

### Build the Solana OFT Program

```bash
./shell/oft_build.sh --network <devnet|mainnet>
```

### Deploy the Solana OFT Program

While for building, we must use Solana `v1.17.31`, for deploying, we will be using `v1.18.26` as it provides an improved program deployment experience (i.e. ability to attach priority fees and also exact-sized on-chain program length which prevents needing to provide 2x the rent as in `v1.17.31`). The deploy script will automatically switch versions and restore.

```bash
./shell/oft_deploy.sh --network <devnet|mainnet> --broadcast <true|false>
```

#### Priority Fee

This section applies if you are unable to land your deployment transaction due to network congestion.

:information_source: [Priority Fees](https://solana.com/developers/guides/advanced/how-to-use-priority-fees) are Solana's mechanism to allow transactions to be prioritized during periods of network congestion. When the network is busy, transactions without priority fees might never be processed. It is then necessary to include priority fees, or wait until the network is less congested. Priority fees are calculated as follows: `priorityFee = compute budget * compute unit price`. We can make use of priority fees by attaching the `--priority-fee` flag to our `oft_deploy.sh` command. Note that the flag takes in a value in micro lamports, where 1 micro lamport = 0.000001 lamport.

You can run refer QuickNode's [Solana Priority Fee Tracker](https://www.quicknode.com/gas-tracker/solana) to know what value you'd need to pass into the `--priority-fee` flag.

### Create the Solana OFT202 Accounts

```bash
./shell/oft_create.sh --network <devnet|mainnet> --broadcast <true|false>
```

The OFT account is created without any additional minters (the bridge is the only one).

The OFT store value will be printed.

Save that in:

- env.json: `<network>.oft.oftStore`
- layerzero-<network>.config.ts: `solanaContract.address`

:information_source: For **OFT** and **OFT Mint-and-Burn Adapter**, the SPL token's Mint Authority is set to the **Mint Authority Multisig**, which always has the **OFT Store** as a signer. The multisig is fixed to needing 1 of N signatures.

:information_source: For **OFT** and **OFT Mint-And-Burn Adapter**, you have the option to specify additional signers through the `--additional-minters` flag. If you choose not to, you must pass in `--only-oft-store true`, which means only the **OFT Store** will be a signer for the \_Mint Authority Multisig\*.

:warning: If you choose to go with `--only-oft-store`, you will not be able to add in other signers/minters or update the Mint Authority, and the Freeze Authority will be immediately renounced. The token Mint Authority will be fixed Mint Authority Multisig address while the Freeze Authority will be set to None.

### Verify the OFT Program

```bash
./shell/oft_verify.sh --network <devnet|mainnet> --broadcast <true|false>
```

### Link Solana Endpoint to EVM

The following command will link the Solana endpoint to the EVM (mainnet or sepolia, depending on the --network flag).

```bash
./shell/endpoint_solana.sh --network <devnet|mainnet> --broadcast <true|false>
```

### Transfer Ownership to MS

Prior to linking the EVM endpoint to Solana, transfer ownership of the OFT to the MS.

### Link EVM Endpoint to Solana

TODO

### Call `setDstMinGas`

TODO needed?

The script will set it to the default value of `1`, which is all that's needed in order to bypass gas assertion.

```bash
npx hardhat --network sepolia-testnet lz:lzapp:set-min-dst-gas --dst-eid 40168
```

### Sending Tokens

TODO verify these, create scripts

Sepolia V1 to Solana

```bash
npx hardhat --network sepolia-testnet lz:oft-v1:send --dst-eid 40168 --amount 1000000000000000000 --to <SOLANA_ADDRESS>
```

Solana to Sepolia V1

```bash
npx hardhat lz:oft:solana:send --amount 1000000000 --from-eid 40168 --to <EVM_ADDRESS> --to-eid 10161 --mint <MINT_ADDRESS> --program-id <PROGRAM_ID> --escrow <ESCROW>
```

### Update SolScan Metadata

TODO
