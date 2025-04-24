// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.22;

interface ICrossChainBridge {
    function sendOhm(uint16 dstChainId_, address to_, uint256 amount_) external payable;

    function sendOhm(
        uint16 dstChainId_,
        address to_,
        uint256 amount_,
        bytes memory adapterParams_
    ) external payable;

    function sendOhm(
        uint16 dstChainId_,
        bytes32 to_,
        uint256 amount_,
        bytes memory adapterParams_
    ) external payable;

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

    function setSendVersion(uint16 version_) external;

    function setReceiveVersion(uint16 version_) external;

    function setConfig(uint16 version_, uint16 chainId_, uint256 configType_, bytes calldata config_) external;

    function setTrustedRemote(uint16 srcChainId_, bytes calldata path_) external;

    function setTrustedRemoteAddress(uint16 remoteChainId_, bytes calldata remoteAddress_) external;

    function setBridgeStatus(bool isActive_) external;
}
