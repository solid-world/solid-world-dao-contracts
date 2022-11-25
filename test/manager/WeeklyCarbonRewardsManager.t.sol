pragma solidity ^0.8.0;

import "./BaseSolidWorldManager.t.sol";

contract WeeklyCarbonRewardsManagerTest is BaseSolidWorldManager {
    event WeeklyRewardMinted(address rewardToken, uint rewardAmount);
    event WeeklyRewardRecalculationSkipped(address rewardToken);

    function testComputeAndMintWeeklyCarbonRewards_failsInputsOfDifferentLengths() public {
        vm.expectRevert(abi.encodePacked("INVALID_INPUT"));
        manager.computeAndMintWeeklyCarbonRewards(new address[](2), new uint[](1), testAccount);
    }

    function testComputeAndMintWeeklyCarbonRewards_failsInputUnknownCategory() public {
        address[] memory assets = new address[](2);
        uint[] memory categoryIds = new uint[](2);
        assets[0] = vm.addr(4);
        assets[1] = vm.addr(5);
        categoryIds[0] = CATEGORY_ID + 777;
        categoryIds[1] = CATEGORY_ID;

        vm.expectRevert(abi.encodePacked("UNKNOWN_CATEGORY"));
        manager.computeAndMintWeeklyCarbonRewards(assets, categoryIds, vm.addr(6));
    }

    function testUpdateRewardDistribution_allBatchesUsed() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT");
        manager.addCategory(CATEGORY_ID + 1, "Test token", "TT");
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        for (uint i = 1; i < 6; i++) {
            manager.addBatch(
                SolidWorldManager.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID + (i % 2),
                    totalAmount: 10000,
                    expectedDueDate: uint32(CURRENT_DATE + 1 minutes),
                    vintage: 2022,
                    discountRate: 1647,
                    owner: address(manager)
                })
            );
        }

        uint expectedBatchWeeklyRewardAmount = 16.47e18;

        address rewardsVault = vm.addr(6);

        address[] memory assets = new address[](2);
        uint[] memory categoryIds = new uint[](2);
        assets[0] = vm.addr(4);
        assets[1] = vm.addr(5);
        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;

        CollateralizedBasketToken rewardToken0 = manager.categoryToken(categoryIds[0]);
        CollateralizedBasketToken rewardToken1 = manager.categoryToken(categoryIds[1]);

        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken0), expectedBatchWeeklyRewardAmount * 2);
        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken1), expectedBatchWeeklyRewardAmount * 3);
        vm.mockCall(
            rewardsDistributor,
            abi.encodeWithSelector(IRewardsDistributor.isOngoingDistribution.selector),
            abi.encode(false)
        );
        (address[] memory carbonRewards, uint[] memory rewardAmounts) = manager
            .computeAndMintWeeklyCarbonRewards(assets, categoryIds, rewardsVault);

        assertEq(carbonRewards.length, 2);
        assertEq(rewardAmounts.length, 2);

        assertEq(carbonRewards[0], address(rewardToken0));
        assertEq(carbonRewards[1], address(rewardToken1));

        assertEq(rewardAmounts[0], expectedBatchWeeklyRewardAmount * 2);
        assertEq(rewardAmounts[1], expectedBatchWeeklyRewardAmount * 3);

        assertEq(rewardToken0.balanceOf(rewardsVault), expectedBatchWeeklyRewardAmount * 2);
        assertEq(rewardToken1.balanceOf(rewardsVault), expectedBatchWeeklyRewardAmount * 3);
    }

    function testUpdateRewardDistribution_oneRewardRecalculationSkipped() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT");
        manager.addCategory(CATEGORY_ID + 1, "Test token", "TT");
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        for (uint i = 1; i < 6; i++) {
            manager.addBatch(
                SolidWorldManager.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID + (i % 2),
                    totalAmount: 10000,
                    expectedDueDate: uint32(CURRENT_DATE + 1 minutes),
                    vintage: 2022,
                    discountRate: 1647,
                    owner: address(manager)
                })
            );
        }

        uint expectedBatchWeeklyRewardAmount = 16.47e18;

        address rewardsVault = vm.addr(6);

        address[] memory assets = new address[](2);
        uint[] memory categoryIds = new uint[](2);
        assets[0] = vm.addr(4);
        assets[1] = vm.addr(5);
        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;

        CollateralizedBasketToken rewardToken0 = manager.categoryToken(categoryIds[0]);
        CollateralizedBasketToken rewardToken1 = manager.categoryToken(categoryIds[1]);

        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken0), expectedBatchWeeklyRewardAmount * 2);
        vm.expectEmit(true, false, false, false, address(manager));
        emit WeeklyRewardRecalculationSkipped(address(rewardToken1));
        vm.mockCall(
            rewardsDistributor,
            abi.encodeWithSelector(
                IRewardsDistributor.isOngoingDistribution.selector,
                assets[0],
                rewardToken0
            ),
            abi.encode(false)
        );
        vm.mockCall(
            rewardsDistributor,
            abi.encodeWithSelector(
                IRewardsDistributor.isOngoingDistribution.selector,
                assets[1],
                rewardToken1
            ),
            abi.encode(true)
        );
        (address[] memory carbonRewards, uint[] memory rewardAmounts) = manager
            .computeAndMintWeeklyCarbonRewards(assets, categoryIds, rewardsVault);

        assertEq(carbonRewards.length, 2);
        assertEq(rewardAmounts.length, 2);

        assertEq(carbonRewards[0], address(rewardToken0));
        assertEq(carbonRewards[1], address(0));

        assertEq(rewardAmounts[0], expectedBatchWeeklyRewardAmount * 2);
        assertEq(rewardAmounts[1], 0);

        assertEq(rewardToken0.balanceOf(rewardsVault), expectedBatchWeeklyRewardAmount * 2);
        assertEq(rewardToken1.balanceOf(rewardsVault), 0);
    }
}
