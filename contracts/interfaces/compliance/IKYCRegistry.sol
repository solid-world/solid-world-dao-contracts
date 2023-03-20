// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World
interface IKYCRegistry {
    error InvalidInput();

    event VerifierUpdated(address indexed oldVerifier, address indexed newVerifier);

    function setVerifier(address newVerifier) external;

    function getVerifier() external view returns (address);
}
