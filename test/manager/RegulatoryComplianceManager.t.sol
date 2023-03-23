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

    function testSetBatchKYCRequired_revertsIfBatchDoesNotExist() public {
        _expectRevert_InvalidBatchId(BATCH_ID);
        manager.setBatchKYCRequired(BATCH_ID, true);
    }

    function testSetBatchKYCRequired() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 1, 10000);

        manager.setBatchKYCRequired(BATCH_ID, true);
        assertTrue(manager.forwardContractBatch().isKYCRequired(BATCH_ID));
    }

    function testSetCategoryVerificationRegistry_revertsIfCategoryDoesNotExist() public {
        _expectRevert_InvalidCategoryId(CATEGORY_ID);
        manager.setCategoryVerificationRegistry(CATEGORY_ID, vm.addr(1));
    }

    function testSetCategoryVerificationRegistry() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 1, 10000);

        manager.setCategoryVerificationRegistry(CATEGORY_ID, vm.addr(1));
        assertEq(manager.getCategoryToken(CATEGORY_ID).getVerificationRegistry(), vm.addr(1));
    }

    function testSetForwardsVerificationRegistry() public {
        manager.setForwardsVerificationRegistry(vm.addr(1));
        assertEq(manager.forwardContractBatch().getVerificationRegistry(), vm.addr(1));
    }

    function testSetCollateralizedBasketTokenDeployerVerificationRegistry() public {
        manager.setCollateralizedBasketTokenDeployerVerificationRegistry(vm.addr(1));
        assertEq(manager.collateralizedBasketTokenDeployer().getVerificationRegistry(), vm.addr(1));
    }

    function _expectRevert_InvalidCategoryId(uint categoryId) private {
        vm.expectRevert(
            abi.encodeWithSelector(RegulatoryComplianceManager.InvalidCategoryId.selector, categoryId)
        );
    }

    function _expectRevert_InvalidBatchId(uint batchId) private {
        vm.expectRevert(abi.encodeWithSelector(RegulatoryComplianceManager.InvalidBatchId.selector, batchId));
    }
}
