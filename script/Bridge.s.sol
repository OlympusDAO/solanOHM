// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.22;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {ICrossChainBridge} from "src/interfaces/ICrossChainBridge.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

contract BridgeScript is Script {
    function bridge(
        uint16 fromChainId_,
        address fromBridge_,
        address fromOhm_,
        address fromMinter_,
        uint16 toChainId_,
        bytes32 toAddress_,
        uint256 amount_
    ) external {
        // Approve spending of OHM by the bridge
        console2.log("Approving spending of OHM by the MINTR module");
        vm.startBroadcast();
        IERC20(fromOhm_).approve(fromMinter_, amount_);
        vm.stopBroadcast();

        // Estimate the send fee
        ICrossChainBridge bridgeContract = ICrossChainBridge(fromBridge_);

        (uint256 nativeFee,) = bridgeContract.estimateSendFee(toChainId_, toAddress_, amount_, bytes(""));

        console2.log("Bridging");
        console2.log("From chain:", fromChainId_);
        console2.log("To chain:", toChainId_);
        console2.log("Amount:", amount_);
        console2.log("To:", vm.toString(toAddress_));
        console2.log("Native fee:", nativeFee);

        // Bridge
        vm.startBroadcast();
        bridgeContract.sendOhm{value: nativeFee}(toChainId_, toAddress_, amount_);
        vm.stopBroadcast();

        console2.log("Bridge complete");
    }
}
