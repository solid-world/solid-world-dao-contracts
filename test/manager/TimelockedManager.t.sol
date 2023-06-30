// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseSolidWorldManager.sol";

contract TimelockedManager is BaseSolidWorldManager {
    function testGetTimelockController() public {
        assertEq(manager.getTimelockController(), timelockController);
    }

    function testUpdateCategory_onlyTimelockController() public {
        _expectRevert_NotTimelockController(address(this));
        manager.updateCategory(CATEGORY_ID, 0, 0, 0);
    }

    function testSetCollateralizationFee_onlyTimelockController() public {
        _expectRevert_NotTimelockController(address(this));
        manager.setCollateralizationFee(0);
    }

    function testSetDecollateralizationFee_onlyTimelockController() public {
        _expectRevert_NotTimelockController(address(this));
        manager.setDecollateralizationFee(0);
    }

    function testSetBoostedDecollateralizationFee_onlyTimelockController() public {
        _expectRevert_NotTimelockController(address(this));
        manager.setBoostedDecollateralizationFee(0);
    }

    function testSetRewardsFee_onlyTimelockController() public {
        _expectRevert_NotTimelockController(address(this));
        manager.setRewardsFee(0);
    }

    function testSetCategoryKYCRequired_onlyTimelockController() public {
        _expectRevert_NotTimelockController(address(this));
        manager.setCategoryKYCRequired(CATEGORY_ID, true);
    }

    function testSetBatchKYCRequired_onlyTimelockController() public {
        _expectRevert_NotTimelockController(address(this));
        manager.setBatchKYCRequired(BATCH_ID, true);
    }
}
