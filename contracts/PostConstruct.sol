// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract PostConstruct {
    bool private _initialized;

    modifier postConstruct() {
        require(!_initialized, "PostConstruct: Already initialized");
        _initialized = true;
        _;
    }
}
