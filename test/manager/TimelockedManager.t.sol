// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract TimelockedManager is BaseSolidWorldManager {
    function testGetTimelockController() public {
        assertEq(manager.getTimelockController(), timelockController);
    }
}
