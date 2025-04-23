import assert from 'assert'

import { Connection, Keypair, PublicKey } from '@solana/web3.js'
import pMemoize from 'p-memoize'

import {
    OmniAddress,
    OmniPoint,
    OmniSigner,
    OmniTransaction,
    OmniTransactionReceipt,
    OmniTransactionResponse,
    firstFactory,
    formatEid,
    makeBytes32,
    mapError,
    normalizePeer,
} from '@layerzerolabs/devtools'
import { createConnectedContractFactory } from '@layerzerolabs/devtools-evm-hardhat'
import {
    type ConnectionFactory,
    OmniSignerSolana,
    OmniSignerSolanaSquads,
    type PublicKeyFactory,
    createConnectionFactory,
    createRpcUrlFactory,
    defaultRpcUrlFactory,
} from '@layerzerolabs/devtools-solana'
import { ChainType, EndpointId, endpointIdToChainType } from '@layerzerolabs/lz-definitions'
import { oft } from '@layerzerolabs/oft-v2-solana-sdk'
import { IOApp, OAppFactory } from '@layerzerolabs/ua-devtools'
import { createOAppFactory } from '@layerzerolabs/ua-devtools-evm'
import { OFT } from '@layerzerolabs/ua-devtools-solana'

export const createSolanaConnectionFactory = () =>
    createConnectionFactory(
        createRpcUrlFactory({
            [EndpointId.SOLANA_V2_MAINNET]: process.env.RPC_URL_SOLANA,
            [EndpointId.SOLANA_V2_TESTNET]: process.env.RPC_URL_SOLANA_TESTNET,
        })
    )

/**
 * Syntactic sugar that creates an instance of Solana `OFT` SDK
 * based on an `OmniPoint` with help of an `ConnectionFactory`
 * and a `PublicKeyFactory`
 *
 * @param {PublicKeyFactory} userAccountFactory A function that accepts an `OmniPoint` representing an OFT and returns the user wallet public key
 * @param {PublicKeyFactory} mintAccountFactory A function that accepts an `OmniPoint` representing an OFT and returns the mint public key
 * @param {ConnectionFactory} connectionFactory A function that returns a `Connection` based on an `EndpointId`
 * @returns {OAppFactory<OFT>}
 */
export const createOFTFactory = (
    userAccountFactory: PublicKeyFactory,
    programIdFactory: PublicKeyFactory,
    connectionFactory: ConnectionFactory = createConnectionFactory(defaultRpcUrlFactory)
): OAppFactory<OFT> =>
    pMemoize(
        async (point: OmniPoint) =>
            new OFTDeterministic(
                await connectionFactory(point.eid),
                point,
                await userAccountFactory(point),
                await programIdFactory(point)
            )
    )

export const createSdkFactory = (
    userAccount: PublicKey,
    programId: PublicKey,
    connectionFactory = createSolanaConnectionFactory()
) => {
    // To create a EVM/Solana SDK factory we need to merge the EVM and the Solana factories into one
    //
    // We do this by using the firstFactory helper function that is provided by the devtools package.
    // This function will try to execute the factories one by one and return the first one that succeeds.
    const evmSdkfactory = createOAppFactory(createConnectedContractFactory())
    const solanaSdkFactory = createOFTFactory(
        // The first parameter to createOFTFactory is a user account factory
        //
        // This is a function that receives an OmniPoint ({ eid, address } object)
        // and returns a user account to be used with that SDK.
        //
        // For our purposes this will always be the user account coming from the secret key passed in
        () => userAccount,
        // The second parameter is a program ID factory
        //
        // This is a function that receives an OmniPoint ({ eid, address } object)
        // and returns a program ID to be used with that SDK.
        //
        // Since we only have one OFT deployed, this will always be the program ID passed as a CLI parameter.
        //
        // In situations where we might have multiple configs with OFTs using multiple program IDs,
        // this function needs to decide which one to use.
        () => programId,
        // Last but not least the SDK will require a connection
        connectionFactory
    )

    // We now "merge" the two SDK factories into one.
    //
    // We do this by using the firstFactory helper function that is provided by the devtools package.
    // This function will try to execute the factories one by one and return the first one that succeeds.
    return firstFactory<[OmniPoint], IOApp>(evmSdkfactory, solanaSdkFactory)
}

export const createSolanaSignerFactory = (
    wallet: Keypair,
    connectionFactory = createSolanaConnectionFactory(),
    multisigKey?: PublicKey
) => {
    return async (eid: EndpointId): Promise<OmniSigner<OmniTransactionResponse<OmniTransactionReceipt>>> => {
        assert(
            endpointIdToChainType(eid) === ChainType.SOLANA,
            `Solana signer factory can only create signers for Solana networks. Received ${formatEid(eid)}`
        )

        return multisigKey
            ? new OmniSignerSolanaSquads(eid, await connectionFactory(eid), multisigKey, wallet)
            : new OmniSignerSolana(eid, await connectionFactory(eid), wallet)
    }
}

export class OFTDeterministic extends OFT {
    constructor(connection: Connection, point: OmniPoint, userAccount: PublicKey, programId: PublicKey) {
        super(connection, point, userAccount, programId)
    }

    async setPeer(eid: EndpointId, address: OmniAddress | null | undefined): Promise<OmniTransaction> {
        const eidLabel = formatEid(eid)
        // We use the `mapError` and pretend `normalizePeer` is async to avoid having a let and a try/catch block
        const normalizedPeer = await mapError(
            async () => normalizePeer(address, eid),
            (error) =>
                new Error(`Failed to convert peer ${address} for ${eidLabel} for ${this.label} to bytes: ${error}`)
        )
        const peerAsBytes32 = makeBytes32(normalizedPeer)
        const delegate = await this.safeGetDelegate()

        const oftStore = this.umiPublicKey

        const instructions = [
            await this._createSetPeerAddressIx(normalizedPeer, eid), // admin
        ]

        const isSendLibraryInitialized = await this.isSendLibraryInitialized(eid)
        if (!isSendLibraryInitialized) {
            instructions.push(
                oft.initSendLibrary({ admin: delegate, oftStore }, eid) // delegate
            )
        }

        const isReceiveLibraryInitialized = await this.isReceiveLibraryInitialized(eid)
        if (!isReceiveLibraryInitialized) {
            instructions.push(
                oft.initReceiveLibrary({ admin: delegate, oftStore }, eid) // delegate
            )
        }

        instructions.push(
            await this._setPeerEnforcedOptionsIx(new Uint8Array([0, 3]), new Uint8Array([0, 3]), eid), // admin
            await this._setPeerFeeBpsIx(eid), // admin
            oft.initOAppNonce({ admin: delegate, oftStore }, eid, normalizedPeer), // delegate
            await this._createSetPeerAddressIx(normalizedPeer, eid) // admin but is this needed?  set twice...
        )

        this.logger.debug(`Setting peer for eid ${eid} (${eidLabel}) to address ${peerAsBytes32}`)
        return {
            ...(await this.createTransaction(this._umiToWeb3Tx(instructions))),
            description: `Setting peer for eid ${eid} (${eidLabel}) to address ${peerAsBytes32} ${delegate.publicKey} ${(await this._getAdmin()).publicKey}`,
        }
    }
}
