// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.22;

import { Script } from "forge-std/Script.sol";
import { ICrossChainBridge } from "src/interfaces/ICrossChainBridge.sol";

import { console2 } from "forge-std/console2.sol";

contract ConfigureCrossChainBridge is Script {
    uint16 public constant SEPOLIA_CHAIN_ID = 10161;

    uint256 public constant CONFIG_TYPE_EXECUTOR = 1;
    uint256 public constant CONFIG_TYPE_ULN = 2;

    uint16 public constant SEND_LIBRARY_VERSION = 4;
    uint16 public constant RECEIVE_LIBRARY_VERSION = 5;

    mapping(uint16 chainId => address executor) public chainToExecutor;
    mapping(uint16 chainId => address dvn) public chainToDvn;

    struct UlnConfig {
        uint64 confirmations;
        uint8 requiredDVNCount;
        uint8 optionalDVNCount;
        uint8 optionalDVNThreshold;
        address[] requiredDVNs;
        address[] optionalDVNs;
    }

    function _setUp() internal {
        chainToExecutor[SEPOLIA_CHAIN_ID] = 0x718B92b5CB0a5552039B593faF724D182A881eDA;

        chainToDvn[SEPOLIA_CHAIN_ID] = 0x8eebf8b423B73bFCa51a1Db4B7354AA0bFCA9193;
    }

    function _getChainExecutor(uint16 chainId_) internal view returns (address) {
        address executor = chainToExecutor[chainId_];
        if (executor == address(0)) {
            revert("Executor not set for chain");
        }

        return executor;
    }

    function _getChainDvn(
        uint16 chainId_
    )
        internal
        view
        returns (
            uint8 requiredDVNCount,
            uint8 optionalDVNCount,
            uint8 optionalDVNThreshold,
            address[] memory requiredDVNs,
            address[] memory optionalDVNs
        )
    {
        address dvn = chainToDvn[chainId_];
        if (dvn == address(0)) {
            revert("DVN not set for chain");
        }

        address[] memory requiredDVNs_ = new address[](1);
        requiredDVNs_[0] = dvn;

        address[] memory optionalDVNs_ = new address[](0);

        return (1, 0, 0, requiredDVNs_, optionalDVNs_);
    }

    function run(
        address localBridge_,
        bytes calldata remoteBridge_,
        uint16 localChainId_,
        uint16 remoteChainId_
    ) external {
        _setUp();

        // Send version
        console2.log("Setting the send version for the EVM bridge to index 4 (ULN301)");
        vm.startBroadcast();
        ICrossChainBridge(localBridge_).setSendVersion(SEND_LIBRARY_VERSION);
        vm.stopBroadcast();

        // Receive version
        console2.log("Setting the receive version for the EVM bridge to index 5 (ULN301)");
        vm.startBroadcast();
        ICrossChainBridge(localBridge_).setReceiveVersion(RECEIVE_LIBRARY_VERSION);
        vm.stopBroadcast();

        // Executor config
        console2.log("Setting the executor config for the EVM bridge");
        vm.startBroadcast();
        ICrossChainBridge(localBridge_).setConfig(
            SEND_LIBRARY_VERSION,
            remoteChainId_,
            CONFIG_TYPE_EXECUTOR,
            abi.encode(10000, _getChainExecutor(localChainId_))
        );
        vm.stopBroadcast();

        (
            uint8 requiredDVNCount,
            uint8 optionalDVNCount,
            uint8 optionalDVNThreshold,
            address[] memory requiredDVNs,
            address[] memory optionalDVNs
        ) = _getChainDvn(localChainId_);

        // Send ULN config
        console2.log("Setting the send ULN config for the EVM bridge");
        vm.startBroadcast();
        ICrossChainBridge(localBridge_).setConfig(
            SEND_LIBRARY_VERSION,
            remoteChainId_,
            CONFIG_TYPE_ULN,
            abi.encode(
                UlnConfig({
                    confirmations: 2,
                    requiredDVNCount: requiredDVNCount,
                    optionalDVNCount: optionalDVNCount,
                    optionalDVNThreshold: optionalDVNThreshold,
                    requiredDVNs: requiredDVNs,
                    optionalDVNs: optionalDVNs
                })
            )
        );
        vm.stopBroadcast();

        // Receive ULN config
        console2.log("Setting the receive ULN config for the EVM bridge");
        vm.startBroadcast();
        ICrossChainBridge(localBridge_).setConfig(
            RECEIVE_LIBRARY_VERSION,
            remoteChainId_,
            CONFIG_TYPE_ULN,
            abi.encode(
                UlnConfig({
                    confirmations: 2,
                    requiredDVNCount: requiredDVNCount,
                    optionalDVNCount: optionalDVNCount,
                    optionalDVNThreshold: optionalDVNThreshold,
                    requiredDVNs: requiredDVNs,
                    optionalDVNs: optionalDVNs
                })
            )
        );
        vm.stopBroadcast();

        // Set trusted remote
        console2.log("Setting the trusted remote for the EVM bridge");
        vm.startBroadcast();
        ICrossChainBridge(localBridge_).setTrustedRemoteAddress(remoteChainId_, remoteBridge_);
        vm.stopBroadcast();
    }
}
