// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @notice Simple contract exposing a modifier used on setup functions
 *         to prevent them from being called more than once
 * @author Solid World DAO
 */
abstract contract PostConstruct {
    bool private _initialized;

    modifier postConstruct() {
        require(!_initialized, "PostConstruct: Already initialized");
        _initialized = true;
        _;
    }
}
