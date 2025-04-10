// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.22;

interface ICrossChainBridge {
    function sendOhm(uint16 dstChainId_, address to_, uint256 amount_) external payable;

    function sendOhm(uint16 dstChainId_, bytes32 to_, uint256 amount_) external payable;

    function estimateSendFee(
        uint16 dstChainId_,
        address to_,
        uint256 amount_,
        bytes calldata adapterParams_
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function estimateSendFee(
        uint16 dstChainId_,
        bytes32 to_,
        uint256 amount_,
        bytes calldata adapterParams_
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function lzEndpoint() external view returns (address);
}
