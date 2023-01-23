pragma solidity ^0.8.0;

import "./BaseSolidWorldManager.t.sol";

contract WeeklyCarbonRewardsManagerTest is BaseSolidWorldManager {
    event WeeklyRewardMinted(address indexed rewardToken, uint indexed rewardAmount);
    event RewardsFeeUpdated(uint indexed rewardsFee);
    event RewardsMinterUpdated(address indexed rewardsMinter);

    function testMintWeeklyCarbonRewards_failsIfManagerIsPaused() public {
        manager.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.Paused.selector));
        manager.mintWeeklyCarbonRewards(
            new uint[](1),
            new address[](2),
            new uint[](1),
            new uint[](1),
            testAccount
        );

        manager.unpause();
        vm.prank(weeklyRewardsMinter);
        manager.mintWeeklyCarbonRewards(
            new uint[](0),
            new address[](0),
            new uint[](0),
            new uint[](0),
            testAccount
        );
    }

    function testMintWeeklyCarbonRewards_failsInputsOfDifferentLengths() public {
        vm.expectRevert(abi.encodeWithSelector(WeeklyCarbonRewards.InvalidInput.selector));
        manager.mintWeeklyCarbonRewards(
            new uint[](2),
            new address[](2),
            new uint[](1),
            new uint[](1),
            testAccount
        );
    }

    function testComputeWeeklyCarbonRewards_failsInputUnknownCategory() public {
        uint[] memory categoryIds = new uint[](2);
        categoryIds[0] = CATEGORY_ID + 777;
        categoryIds[1] = CATEGORY_ID;

        vm.expectRevert(
            abi.encodeWithSelector(WeeklyCarbonRewards.InvalidCategoryId.selector, categoryIds[0])
        );
        manager.computeWeeklyCarbonRewards(categoryIds);
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
                    batchTA: 10_0000,
                    supplier: address(manager),
                    isAccumulating: false
                }),
                10000
            );
        }

        uint expectedBatchWeeklyRewardAmount = 19.1764e18;
        uint expectedRewardFeeAmount = 1.0092e18;

        uint[] memory categoryIds = new uint[](2);
        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;

        CollateralizedBasketToken rewardToken0 = manager.getCategoryToken(categoryIds[0]);
        CollateralizedBasketToken rewardToken1 = manager.getCategoryToken(categoryIds[1]);

        (
            address[] memory carbonRewards,
            uint[] memory rewardAmounts,
            uint[] memory rewardFees
        ) = manager.computeWeeklyCarbonRewards(categoryIds);

        assertEq(carbonRewards.length, 2);
        assertEq(rewardAmounts.length, 2);
        assertEq(rewardFees.length, 2);

        assertEq(carbonRewards[0], address(rewardToken0));
        assertEq(carbonRewards[1], address(rewardToken1));

        assertApproxEqAbs(rewardAmounts[0], expectedBatchWeeklyRewardAmount * 2, 0.0082e18);
        assertApproxEqAbs(rewardAmounts[1], expectedBatchWeeklyRewardAmount * 3, 0.0123e18);

        assertApproxEqAbs(rewardFees[0], expectedRewardFeeAmount * 2, 0.0006e18);
        assertApproxEqAbs(rewardFees[1], expectedRewardFeeAmount * 3, 0.0009e18);
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
                    certificationDate: uint32(CURRENT_DATE + 7 weeks + ONE_YEAR),
                    vintage: 2022,
                    batchTA: 10_0000,
                    supplier: address(manager),
                    isAccumulating: false
                }),
                10000
            );
        }

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 11,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 minutes + ONE_YEAR),
                vintage: 2022,
                batchTA: 10_0000,
                supplier: address(manager),
                isAccumulating: false
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 12,
                status: 0,
                projectId: PROJECT_ID + 1,
                certificationDate: uint32(CURRENT_DATE + 2 weeks + ONE_YEAR),
                vintage: 2022,
                batchTA: 10_0000,
                supplier: address(manager),
                isAccumulating: false
            }),
            10000
        );

        // Batches 11 and 12 are certified
        vm.warp(CURRENT_DATE + 6 weeks + 6 days + ONE_YEAR);

        uint expectedBatchWeeklyRewardAmount = 19.1764e18;
        uint expectedRewardFeeAmount = 1.0092e18;

        uint[] memory categoryIds = new uint[](2);
        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;

        CollateralizedBasketToken rewardToken0 = manager.getCategoryToken(categoryIds[0]);
        CollateralizedBasketToken rewardToken1 = manager.getCategoryToken(categoryIds[1]);

        (
            address[] memory carbonRewards,
            uint[] memory rewardAmounts,
            uint[] memory rewardFees
        ) = manager.computeWeeklyCarbonRewards(categoryIds);

        assertEq(carbonRewards.length, 2);
        assertEq(rewardAmounts.length, 2);
        assertEq(rewardFees.length, 2);

        assertEq(carbonRewards[0], address(rewardToken0));
        assertEq(carbonRewards[1], address(rewardToken1));

        assertApproxEqAbs(rewardAmounts[0], expectedBatchWeeklyRewardAmount * 2, 0.0082e18);
        assertApproxEqAbs(rewardAmounts[1], expectedBatchWeeklyRewardAmount * 3, 0.0123e18);

        assertApproxEqAbs(rewardFees[0], expectedRewardFeeAmount * 2, 0.0006e18);
        assertApproxEqAbs(rewardFees[1], expectedRewardFeeAmount * 3, 0.0009e18);

        // All batches are certified
        vm.warp(CURRENT_DATE + 7 weeks + 1 minutes + ONE_YEAR);

        (
            address[] memory carbonRewardsCertified,
            uint[] memory rewardAmountsCertified,
            uint[] memory rewardFeesCertified
        ) = manager.computeWeeklyCarbonRewards(categoryIds);

        assertEq(carbonRewardsCertified.length, 2);
        assertEq(rewardAmountsCertified.length, 2);
        assertEq(rewardFeesCertified.length, 2);

        assertEq(carbonRewardsCertified[0], address(rewardToken0));
        assertEq(carbonRewardsCertified[1], address(rewardToken1));

        assertEq(rewardAmountsCertified[0], 0);
        assertEq(rewardAmountsCertified[1], 0);

        assertEq(rewardFeesCertified[0], 0);
        assertEq(rewardFeesCertified[1], 0);
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
                    supplier: address(manager),
                    isAccumulating: false
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
                supplier: address(manager),
                isAccumulating: false
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
                supplier: address(manager),
                isAccumulating: false
            }),
            0
        );
        vm.warp(CURRENT_DATE + 6 weeks);
        CollateralizedBasketToken rewardToken0 = manager.getCategoryToken(CATEGORY_ID);
        CollateralizedBasketToken rewardToken1 = manager.getCategoryToken(CATEGORY_ID + 1);
        CollateralizedBasketToken rewardToken2 = manager.getCategoryToken(CATEGORY_ID + 2);

        uint mintAmount0 = 950;
        uint mintAmount1 = 1900;
        uint mintAmount2 = 0;
        uint feeAmount0 = 50;
        uint feeAmount1 = 100;
        uint feeAmount2 = 0;

        address rewardsVault = vm.addr(6);

        uint[] memory categoryIds = new uint[](3);
        address[] memory carbonRewards = new address[](3);
        uint[] memory rewardAmounts = new uint[](3);
        uint[] memory feeAmounts = new uint[](3);
        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;
        categoryIds[2] = CATEGORY_ID + 2;
        carbonRewards[0] = address(rewardToken0);
        carbonRewards[1] = address(rewardToken1);
        carbonRewards[2] = address(rewardToken2);
        rewardAmounts[0] = mintAmount0;
        rewardAmounts[1] = mintAmount1;
        rewardAmounts[2] = mintAmount2;
        feeAmounts[0] = feeAmount0;
        feeAmounts[1] = feeAmount1;
        feeAmounts[2] = feeAmount2;

        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken0), mintAmount0);
        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken1), mintAmount1);
        vm.expectEmit(true, true, false, true, address(manager));
        emit WeeklyRewardMinted(address(rewardToken2), mintAmount2);

        vm.prank(weeklyRewardsMinter);
        manager.mintWeeklyCarbonRewards(
            categoryIds,
            carbonRewards,
            rewardAmounts,
            feeAmounts,
            rewardsVault
        );

        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(CATEGORY_ID, uint24(1947), 20000);
        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(CATEGORY_ID + 1, 1947, 60000);
        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(CATEGORY_ID + 2, INITIAL_CATEGORY_TA, 0);
        vm.prank(weeklyRewardsMinter);
        manager.mintWeeklyCarbonRewards(
            categoryIds,
            carbonRewards,
            rewardAmounts,
            feeAmounts,
            rewardsVault
        );

        assertEq(rewardToken0.balanceOf(rewardsVault), mintAmount0 * 2);
        assertEq(rewardToken1.balanceOf(rewardsVault), mintAmount1 * 2);
        assertEq(rewardToken2.balanceOf(rewardsVault), mintAmount2);

        assertEq(rewardToken0.balanceOf(feeReceiver), feeAmount0 * 2);
        assertEq(rewardToken1.balanceOf(feeReceiver), feeAmount1 * 2);
        assertEq(rewardToken2.balanceOf(feeReceiver), feeAmount2);

        DomainDataTypes.Category memory category0 = manager.getCategory(CATEGORY_ID);
        DomainDataTypes.Category memory category1 = manager.getCategory(CATEGORY_ID + 1);
        DomainDataTypes.Category memory category2 = manager.getCategory(CATEGORY_ID + 2);

        assertEq(category0.averageTA, 1947);
        assertEq(category0.totalCollateralized, 20000);
        assertEq(category1.averageTA, 1947);
        assertEq(category1.totalCollateralized, 60000);
        assertEq(category2.averageTA, INITIAL_CATEGORY_TA);
        assertEq(category2.totalCollateralized, 0);
    }

    function testMintWeeklyCarbonRewards_failsIfNotCalledByWeeklyRewardsMinter() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                WeeklyCarbonRewards.UnauthorizedRewardMinting.selector,
                address(this)
            )
        );
        manager.mintWeeklyCarbonRewards(
            new uint[](0),
            new address[](0),
            new uint[](0),
            new uint[](0),
            testAccount
        );
    }

    function testSetRewardsFee() public {
        uint16 newRewardsFee = 1234;

        vm.expectEmit(true, false, false, false, address(manager));
        emit RewardsFeeUpdated(newRewardsFee);
        manager.setRewardsFee(newRewardsFee);
        assertEq(manager.getRewardsFee(), newRewardsFee);
    }

    function testSetWeeklyRewardsMinter() public {
        address newWeeklyRewardsMinter = vm.addr(1234);

        vm.expectEmit(true, false, false, false, address(manager));
        emit RewardsMinterUpdated(newWeeklyRewardsMinter);
        manager.setWeeklyRewardsMinter(newWeeklyRewardsMinter);
        assertEq(manager.getWeeklyRewardsMinter(), newWeeklyRewardsMinter);
    }
}
