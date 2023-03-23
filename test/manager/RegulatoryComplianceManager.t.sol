// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract RegulatoryComplianceManagerTest is BaseSolidWorldManager {
    function testSetCategoryKYCRequired_revertsIfCategoryDoesNotExist() public {
        _expectRevert_InvalidCategoryId(CATEGORY_ID);
        manager.setCategoryKYCRequired(CATEGORY_ID, true);
    }

    function testSetCategoryKYCRequired() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 1, 10000);

        manager.setCategoryKYCRequired(CATEGORY_ID, true);
        assertTrue(manager.getCategoryToken(CATEGORY_ID).isKYCRequired());
    }

    function _expectRevert_InvalidCategoryId(uint categoryId) private {
        vm.expectRevert(
            abi.encodeWithSelector(RegulatoryComplianceManager.InvalidCategoryId.selector, categoryId)
        );
    }
}
