// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract ManagerAuthorizationTest is BaseSolidWorldManager {
    function testAuthorization() public {
        vm.startPrank(vm.addr(77));

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.addCategory(3, "", "", INITIAL_CATEGORY_TA);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.updateCategory(CATEGORY_ID, 0, 0, 0);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.addProject(3, 5);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                collateralizedCredits: 0,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
            }),
            10000
        );

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.setWeeklyRewardsMinter(vm.addr(1234));

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.setCollateralizationFee(1);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.setDecollateralizationFee(1);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.setRewardsFee(1);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.setFeeReceiver(vm.addr(1234));

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.pause();

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.unpause();

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.setBatchAccumulating(1, true);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        manager.setBatchCertificationDate(1, 1);

        vm.stopPrank();
    }

    function testERC1155TransfersToManager() public {
        _addBatchWithDependencies(CURRENT_DATE + 3 weeks, 10000);
        _addBatch(BATCH_ID + 1, CURRENT_DATE + 3 weeks, 10000);

        vm.startPrank(testAccount);
        vm.expectRevert(abi.encodePacked("ERC1155: ERC1155Receiver rejected tokens"));
        forwardContractBatch.safeTransferFrom(testAccount, address(manager), BATCH_ID, 1, "");

        uint[] memory ids = new uint[](2);
        ids[0] = BATCH_ID;
        ids[1] = BATCH_ID + 1;
        uint[] memory amounts = new uint[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.expectRevert(abi.encodePacked("ERC1155: ERC1155Receiver rejected tokens"));
        forwardContractBatch.safeBatchTransferFrom(testAccount, address(manager), ids, amounts, "");
    }
}
