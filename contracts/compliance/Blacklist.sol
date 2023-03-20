// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/compliance/IBlacklist.sol";

/// @author Solid World
/// @dev Abstract base contract for a blacklist. Function restrictions should be implemented by derived contracts.
abstract contract Blacklist is IBlacklist {
    address internal blacklister;

    mapping(address => bool) internal blacklisted;

    function setBlacklister(address newBlacklister) public virtual {
        if (newBlacklister == address(0)) {
            revert InvalidInput();
        }

        _setBlacklister(newBlacklister);
    }

    function blacklist(address subject) public virtual {
        _blacklist(subject);
    }

    function getBlacklister() external view returns (address) {
        return blacklister;
    }

    function isBlacklisted(address subject) external view returns (bool) {
        return blacklisted[subject];
    }

    function _setBlacklister(address newBlacklister) internal {
        address oldBlacklister = blacklister;
        blacklister = newBlacklister;

        emit BlacklisterUpdated(oldBlacklister, newBlacklister);
    }

    function _blacklist(address subject) internal {
        blacklisted[subject] = true;

        emit Blacklisted(subject);
    }
}
