// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract ManagerAuthorizationTest is BaseSolidWorldManager {
    function testAuthorization() public {
        vm.startPrank(vm.addr(77));

        _expectRevert_NotOwner();
        manager.addCategory(3, "", "", INITIAL_CATEGORY_TA);

        _expectRevert_NotOwner();
        manager.updateCategory(CATEGORY_ID, 0, 0, 0);

        _expectRevert_NotOwner();
        manager.addProject(3, 5);

        _expectRevert_NotOwner();
        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + 12,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
            }),
            10000
        );

        _expectRevert_NotOwner();
        manager.setWeeklyRewardsMinter(vm.addr(1234));

        _expectRevert_NotOwner();
        manager.setCollateralizationFee(1);

        _expectRevert_NotOwner();
        manager.setDecollateralizationFee(1);

        _expectRevert_NotOwner();
        manager.setRewardsFee(1);

        _expectRevert_NotOwner();
        manager.setFeeReceiver(vm.addr(1234));

        _expectRevert_NotOwner();
        manager.pause();

        _expectRevert_NotOwner();
        manager.unpause();

        _expectRevert_NotOwner();
        manager.setBatchAccumulating(1, true);

        _expectRevert_NotOwner();
        manager.setBatchCertificationDate(1, 1);

        _expectRevert_NotOwner();
        manager.setCategoryKYCRequired(CATEGORY_ID, true);

        _expectRevert_NotOwner();
        manager.setBatchKYCRequired(BATCH_ID, true);

        _expectRevert_NotOwner();
        manager.setCategoryVerificationRegistry(CATEGORY_ID, vm.addr(1));

        vm.stopPrank();
    }

    function testERC1155TransfersToManager() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 3 weeks, 10000);
        _addBatch(BATCH_ID + 1, PRESET_CURRENT_DATE + 3 weeks, 10000);

        vm.startPrank(testAccount);
        _expectRevertWithMessage("ERC1155: ERC1155Receiver rejected tokens");
        forwardContractBatch.safeTransferFrom(testAccount, address(manager), BATCH_ID, 1, "");

        uint[] memory ids = new uint[](2);
        ids[0] = BATCH_ID;
        ids[1] = BATCH_ID + 1;
        uint[] memory amounts = new uint[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        _expectRevertWithMessage("ERC1155: ERC1155Receiver rejected tokens");
        forwardContractBatch.safeBatchTransferFrom(testAccount, address(manager), ids, amounts, "");
    }
}
