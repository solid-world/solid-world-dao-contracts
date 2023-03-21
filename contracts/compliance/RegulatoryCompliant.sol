// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/compliance/IRegulatoryCompliant.sol";

/// @author Solid World
/// @notice A contract that can integrate a verification registry, and offer a uniform way to
/// validate counterparties against the current registry.
/// @dev Function restrictions should be implemented by derived contracts.
abstract contract RegulatoryCompliant is IRegulatoryCompliant {
    address private verificationRegistry;

    constructor(address _verificationRegistry) {
        verificationRegistry = _verificationRegistry;
    }
}
