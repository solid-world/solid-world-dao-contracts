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
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount
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

        vm.stopPrank();
    }
}
