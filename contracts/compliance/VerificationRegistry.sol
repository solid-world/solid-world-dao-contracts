// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./KYCRegistry.sol";
import "./Blacklist.sol";

/// @author Solid World
/// @notice A contract for maintaining a registry of KYCed and blacklisted addresses.
/// @dev does not inherit from IVerificationRegistry because of https://github.com/ethereum/solidity/issues/12554
contract VerificationRegistry is Initializable, OwnableUpgradeable, Blacklist, KYCRegistry {
    modifier authorizedBlacklister() {
        if (msg.sender != getBlacklister() && msg.sender != owner()) {
            revert BlacklistingNotAuthorized(msg.sender);
        }
        _;
    }

    modifier authorizedVerifier() {
        if (msg.sender != getVerifier() && msg.sender != owner()) {
            revert VerificationNotAuthorized(msg.sender);
        }
        _;
    }

    function initialize(address owner) public initializer {
        __Ownable_init();
        transferOwnership(owner);
    }

    function setBlacklister(address newBlacklister) public override onlyOwner {
        super.setBlacklister(newBlacklister);
    }

    function setVerifier(address newVerifier) public override onlyOwner {
        super.setVerifier(newVerifier);
    }

    function blacklist(address subject) public override authorizedBlacklister {
        super.blacklist(subject);
    }

    function unBlacklist(address subject) public override authorizedBlacklister {
        super.unBlacklist(subject);
    }

    function registerVerification(address subject) public override authorizedVerifier {
        super.registerVerification(subject);
    }

    function revokeVerification(address subject) public override authorizedVerifier {
        super.revokeVerification(subject);
    }

    function isVerifiedAndNotBlacklisted(address subject) external view returns (bool) {
        return isVerified(subject) && !isBlacklisted(subject);
    }
}
