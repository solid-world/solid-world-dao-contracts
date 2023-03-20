// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/compliance/IKYCRegistry.sol";

/// @author Solid World
/// @dev Abstract base contract for a KYC registry. Function restrictions should be implemented by derived contracts.
abstract contract KYCRegistry is IKYCRegistry {
    address internal verifier;

    mapping(address => bool) internal verified;

    function setVerifier(address newVerifier) public virtual {
        if (newVerifier == address(0)) {
            revert InvalidInput();
        }

        _setVerifier(newVerifier);
    }

    function registerVerification(address subject) public virtual {
        _registerVerification(subject);
    }

    function revokeVerification(address subject) public virtual {
        _revokeVerification(subject);
    }

    function getVerifier() external view returns (address) {
        return verifier;
    }

    function isVerified(address subject) external view returns (bool) {
        return verified[subject];
    }

    function _setVerifier(address newVerifier) internal {
        address oldVerifier = verifier;
        verifier = newVerifier;

        emit VerifierUpdated(oldVerifier, newVerifier);
    }

    function _registerVerification(address subject) internal {
        verified[subject] = true;

        emit Verified(subject);
    }

    function _revokeVerification(address subject) internal {
        verified[subject] = false;

        emit VerificationRevoked(subject);
    }
}
