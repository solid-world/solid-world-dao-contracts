// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./KYCRegistry.sol";
import "./Blacklist.sol";

/// @author Solid World
/// @dev does not inherit from IVerificationRegistry because of https://github.com/ethereum/solidity/issues/12554
contract VerificationRegistry is Initializable, OwnableUpgradeable, Blacklist, KYCRegistry {
    modifier authorizedBlacklister() {
        if (msg.sender != getBlacklister() && msg.sender != owner()) {
            revert BlacklistingNotAuthorized(msg.sender);
        }
        _;
    }

    function initialize(address owner) public initializer {
        __Ownable_init();
        transferOwnership(owner);
    }

    function blacklist(address subject) public override authorizedBlacklister {
        super.blacklist(subject);
    }

    function unBlacklist(address subject) public override authorizedBlacklister {
        super.unBlacklist(subject);
    }
}
