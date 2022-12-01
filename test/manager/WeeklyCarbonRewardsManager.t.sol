pragma solidity ^0.8.0;

import "./BaseSolidWorldManager.t.sol";

contract WeeklyCarbonRewardsManagerTest is BaseSolidWorldManager {
    event WeeklyRewardMinted(address indexed rewardToken, uint indexed rewardAmount);

    function testComputeWeeklyCarbonRewards_failsInputsOfDifferentLengths() public {
        vm.expectRevert(abi.encodeWithSelector(ISolidWorldManagerErrors.InvalidInput.selector));
        manager.computeWeeklyCarbonRewards(new address[](2), new uint[](1));
    }

    function testMintWeeklyCarbonRewards_failsInputsOfDifferentLengths() public {
        vm.expectRevert(abi.encodeWithSelector(ISolidWorldManagerErrors.InvalidInput.selector));
        manager.mintWeeklyCarbonRewards(new address[](2), new uint[](1), testAccount);
    }

    function testComputeWeeklyCarbonRewards_failsInputUnknownCategory() public {
        address[] memory assets = new address[](2);
        uint[] memory categoryIds = new uint[](2);
        assets[0] = vm.addr(4);
        assets[1] = vm.addr(5);
        categoryIds[0] = CATEGORY_ID + 777;
        categoryIds[1] = CATEGORY_ID;

        vm.expectRevert(
            abi.encodeWithSelector(
                ISolidWorldManagerErrors.InvalidCategoryId.selector,
                categoryIds[0]
            )
        );
        manager.computeWeeklyCarbonRewards(assets, categoryIds);
    }

    function testComputeWeeklyCarbonRewards_allBatchesUsed() public {
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

        address[] memory assets = new address[](2);
        uint[] memory categoryIds = new uint[](2);
        assets[0] = vm.addr(4);
        assets[1] = vm.addr(5);
        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;

        CollateralizedBasketToken rewardToken0 = manager.categoryToken(categoryIds[0]);
        CollateralizedBasketToken rewardToken1 = manager.categoryToken(categoryIds[1]);

        (address[] memory carbonRewards, uint[] memory rewardAmounts) = manager
            .computeWeeklyCarbonRewards(assets, categoryIds);

        assertEq(carbonRewards.length, 2);
        assertEq(rewardAmounts.length, 2);

        assertEq(carbonRewards[0], address(rewardToken0));
        assertEq(carbonRewards[1], address(rewardToken1));

        assertEq(rewardAmounts[0], expectedBatchWeeklyRewardAmount * 2);
        assertEq(rewardAmounts[1], expectedBatchWeeklyRewardAmount * 3);
    }

    function testComputeWeeklyCarbonRewards_certifiedBatchesAreSkipped() public {
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
                    expectedDueDate: uint32(CURRENT_DATE + 7 weeks),
                    vintage: 2022,
                    discountRate: 1647,
                    owner: address(manager)
                })
            );
        }

        manager.addBatch(
            SolidWorldManager.Batch({
                id: BATCH_ID + 6,
                status: 0,
                projectId: PROJECT_ID,
                totalAmount: 10000,
                expectedDueDate: uint32(CURRENT_DATE + 1 minutes),
                vintage: 2022,
                discountRate: 1647,
                owner: address(manager)
            })
        );

        manager.addBatch(
            SolidWorldManager.Batch({
                id: BATCH_ID + 7,
                status: 0,
                projectId: PROJECT_ID + 1,
                totalAmount: 10000,
                expectedDueDate: uint32(CURRENT_DATE + 2 weeks),
                vintage: 2022,
                discountRate: 1647,
                owner: address(manager)
            })
        );

        // Batches 11 and 12 are certified
        vm.warp(CURRENT_DATE + 6 weeks + 6 days);

        uint expectedBatchWeeklyRewardAmount = 16.47e18;

        address[] memory assets = new address[](2);
        uint[] memory categoryIds = new uint[](2);
        assets[0] = vm.addr(4);
        assets[1] = vm.addr(5);
        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;

        CollateralizedBasketToken rewardToken0 = manager.categoryToken(categoryIds[0]);
        CollateralizedBasketToken rewardToken1 = manager.categoryToken(categoryIds[1]);

        (address[] memory carbonRewards, uint[] memory rewardAmounts) = manager
            .computeWeeklyCarbonRewards(assets, categoryIds);

        assertEq(carbonRewards.length, 2);
        assertEq(rewardAmounts.length, 2);

        assertEq(carbonRewards[0], address(rewardToken0));
        assertEq(carbonRewards[1], address(rewardToken1));

        assertEq(rewardAmounts[0], expectedBatchWeeklyRewardAmount * 2);
        assertEq(rewardAmounts[1], expectedBatchWeeklyRewardAmount * 3);

        // All batches are certified
        vm.warp(CURRENT_DATE + 7 weeks + 1 minutes);

        (address[] memory carbonRewardsCertified, uint[] memory rewardAmountsCertified) = manager
            .computeWeeklyCarbonRewards(assets, categoryIds);

        assertEq(carbonRewardsCertified.length, 2);
        assertEq(rewardAmountsCertified.length, 2);

        assertEq(carbonRewardsCertified[0], address(rewardToken0));
        assertEq(carbonRewardsCertified[1], address(rewardToken1));

        assertEq(rewardAmountsCertified[0], 0);
        assertEq(rewardAmountsCertified[1], 0);
    }

    function testMintWeeklyCarbonRewards_allBatchesUsed() public {
        vm.startPrank(address(manager));
        CollateralizedBasketToken rewardToken0 = new CollateralizedBasketToken("Test token", "TT");
        CollateralizedBasketToken rewardToken1 = new CollateralizedBasketToken("Test token", "TT");
        vm.stopPrank();

        uint mintAmount0 = 1000;
        uint mintAmount1 = 2000;

        address rewardsVault = vm.addr(6);

        address[] memory carbonRewards = new address[](2);
        uint[] memory rewardAmounts = new uint[](2);
        carbonRewards[0] = address(rewardToken0);
        carbonRewards[1] = address(rewardToken1);
        rewardAmounts[0] = mintAmount0;
        rewardAmounts[1] = mintAmount1;

        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken0), mintAmount0);

        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken1), mintAmount1);

        vm.prank(rewardsEmissionManager);
        manager.mintWeeklyCarbonRewards(carbonRewards, rewardAmounts, rewardsVault);

        assertEq(rewardToken0.balanceOf(rewardsVault), mintAmount0);
        assertEq(rewardToken1.balanceOf(rewardsVault), mintAmount1);
    }

    function testMintWeeklyCarbonRewards_failsIfNotCalledByWeeklyRewardsMinter() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IWeeklyCarbonRewardsManager.UnauthorizedRewardMinting.selector,
                address(this)
            )
        );
        manager.mintWeeklyCarbonRewards(new address[](0), new uint[](0), testAccount);
    }
}
