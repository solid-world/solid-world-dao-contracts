// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/compliance/IKYCRegistry.sol";

/// @author Solid World
contract KYCRegistry is IKYCRegistry {
    address internal verifier;

    function setVerifier(address newVerifier) public virtual {
        if (newVerifier == address(0)) {
            revert InvalidInput();
        }

        _setVerifier(newVerifier);
    }

    function getVerifier() external view returns (address) {
        return verifier;
    }

    function _setVerifier(address newVerifier) internal {
        address oldVerifier = verifier;
        verifier = newVerifier;

        emit VerifierUpdated(oldVerifier, newVerifier);
    }
}
