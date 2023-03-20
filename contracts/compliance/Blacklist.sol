// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/compliance/IBlacklist.sol";

/// @author Solid World
/// @dev Abstract base contract for a blacklist. Function restrictions should be implemented by derived contracts.
abstract contract Blacklist is IBlacklist {
    address private blacklister;

    mapping(address => bool) private blacklisted;

    function setBlacklister(address newBlacklister) public virtual {
        if (newBlacklister == address(0)) {
            revert InvalidInput();
        }

        _setBlacklister(newBlacklister);
    }

    function blacklist(address subject) public virtual {
        _blacklist(subject);
    }

    function unBlacklist(address subject) public virtual {
        _unBlacklist(subject);
    }

    function getBlacklister() public view returns (address) {
        return blacklister;
    }

    function isBlacklisted(address subject) public view returns (bool) {
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

    function _unBlacklist(address subject) internal {
        blacklisted[subject] = false;

        emit UnBlacklisted(subject);
    }
}
