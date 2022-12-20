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
        manager.mintWeeklyCarbonRewards(
            new uint[](2),
            new address[](2),
            new uint[](1),
            testAccount
        );
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
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addCategory(CATEGORY_ID + 1, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        for (uint i = 1; i < 6; i++) {
            manager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID + (i % 2),
                    certificationDate: uint32(CURRENT_DATE + 1 minutes),
                    vintage: 2022,
                    batchTA: 1647,
                    supplier: address(manager)
                }),
                10000
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
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addCategory(CATEGORY_ID + 1, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        for (uint i = 1; i < 6; i++) {
            manager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID + (i % 2),
                    certificationDate: uint32(CURRENT_DATE + 7 weeks),
                    vintage: 2022,
                    batchTA: 1647,
                    supplier: address(manager)
                }),
                10000
            );
        }

        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 6,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 minutes),
                vintage: 2022,
                batchTA: 1647,
                supplier: address(manager)
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 7,
                status: 0,
                projectId: PROJECT_ID + 1,
                certificationDate: uint32(CURRENT_DATE + 2 weeks),
                vintage: 2022,
                batchTA: 1647,
                supplier: address(manager)
            }),
            10000
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
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addCategory(CATEGORY_ID + 1, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addCategory(CATEGORY_ID + 2, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        manager.addProject(CATEGORY_ID + 2, PROJECT_ID + 2);
        for (uint i = 1; i < 6; i++) {
            manager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID + (i % 2),
                    certificationDate: uint32(CURRENT_DATE + 7 weeks),
                    vintage: 2022,
                    batchTA: uint24(1647 + (i * 100)), // 1747, 1847, 1947, 2047, 2147
                    supplier: address(manager)
                }),
                10000 * ((i % 2) + 1)
            );
        }
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 6,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 3 weeks), // should be skipped
                vintage: 2022,
                batchTA: uint24(9999),
                supplier: address(manager)
            }),
            1000000
        );
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 7,
                status: 0,
                projectId: PROJECT_ID + 2,
                certificationDate: uint32(CURRENT_DATE + 7 weeks),
                vintage: 2022,
                batchTA: 1647,
                supplier: address(manager)
            }),
            0
        );
        vm.warp(CURRENT_DATE + 6 weeks);
        CollateralizedBasketToken rewardToken0 = manager.categoryToken(CATEGORY_ID);
        CollateralizedBasketToken rewardToken1 = manager.categoryToken(CATEGORY_ID + 1);
        CollateralizedBasketToken rewardToken2 = manager.categoryToken(CATEGORY_ID + 2);

        uint mintAmount0 = 1000;
        uint mintAmount1 = 2000;
        uint mintAmount2 = 0;

        address rewardsVault = vm.addr(6);

        uint[] memory categoryIds = new uint[](3);
        address[] memory carbonRewards = new address[](3);
        uint[] memory rewardAmounts = new uint[](3);
        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;
        categoryIds[2] = CATEGORY_ID + 2;
        carbonRewards[0] = address(rewardToken0);
        carbonRewards[1] = address(rewardToken1);
        carbonRewards[2] = address(rewardToken2);
        rewardAmounts[0] = mintAmount0;
        rewardAmounts[1] = mintAmount1;
        rewardAmounts[2] = mintAmount2;

        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken0), mintAmount0);
        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken1), mintAmount1);
        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken2), mintAmount2);

        vm.prank(weeklyRewardsMinter);
        manager.mintWeeklyCarbonRewards(categoryIds, carbonRewards, rewardAmounts, rewardsVault);

        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(CATEGORY_ID, uint24(1947), 20000);
        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(CATEGORY_ID + 1, 1947, 60000);
        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(CATEGORY_ID + 2, INITIAL_CATEGORY_TA, 0);
        vm.prank(weeklyRewardsMinter);
        manager.mintWeeklyCarbonRewards(categoryIds, carbonRewards, rewardAmounts, rewardsVault);

        assertEq(rewardToken0.balanceOf(rewardsVault), mintAmount0 * 2);
        assertEq(rewardToken1.balanceOf(rewardsVault), mintAmount1 * 2);
        assertEq(rewardToken2.balanceOf(rewardsVault), mintAmount2);

        (, , , uint24 averageTA0, uint totalCollateralized0, , ) = manager.categories(CATEGORY_ID);
        (, , , uint24 averageTA1, uint totalCollateralized1, , ) = manager.categories(
            CATEGORY_ID + 1
        );
        (, , , uint24 averageTA2, uint totalCollateralized2, , ) = manager.categories(
            CATEGORY_ID + 2
        );

        assertEq(averageTA0, 1947);
        assertEq(totalCollateralized0, 20000);
        assertEq(averageTA1, 1947);
        assertEq(totalCollateralized1, 60000);
        assertEq(averageTA2, INITIAL_CATEGORY_TA);
        assertEq(totalCollateralized2, 0);
    }

    function testMintWeeklyCarbonRewards_failsIfNotCalledByWeeklyRewardsMinter() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IWeeklyCarbonRewardsManager.UnauthorizedRewardMinting.selector,
                address(this)
            )
        );
        manager.mintWeeklyCarbonRewards(
            new uint[](0),
            new address[](0),
            new uint[](0),
            testAccount
        );
    }
}
