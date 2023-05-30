// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

contract SolidZapStaker {
    address public immutable router;

    constructor(address _router) {
        router = _router;
    }
}
