// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { TimelockController as TC } from "@openzeppelin/contracts/governance/TimelockController.sol";

/// @author OpenZeppelin
contract TimelockController is TC {
    constructor(
        uint minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TC(minDelay, proposers, executors, admin) {}
}
