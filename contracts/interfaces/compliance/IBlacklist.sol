// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World
interface IBlacklist {
    error InvalidInput();

    event BlacklisterUpdated(address indexed oldBlacklister, address indexed newBlacklister);
    event Blacklisted(address indexed subject);

    function setBlacklister(address newBlacklister) external;

    function blacklist(address subject) external;

    function getBlacklister() external view returns (address);

    function isBlacklisted(address subject) external view returns (bool);
}
