// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World
interface IRegulatoryCompliant {
    error InvalidVerificationRegistry();

    event VerificationRegistryUpdated(address indexed verificationRegistry);

    function setVerificationRegistry(address _verificationRegistry) external;

    function getVerificationRegistry() external view returns (address);
}
