// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract TimelockedManager is BaseSolidWorldManager {
    function testGetTimelockController() public {
        assertEq(manager.getTimelockController(), timelockController);
    }

    function testUpdateCategory_onlyTimelockController() public {
        _expectRevert_NotTimelockController(address(this));
        manager.updateCategory(CATEGORY_ID, 0, 0, 0);
    }
}
