// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract ReactiveTimeAppreciationScenarios is BaseSolidWorldManager {
    function testReactiveTAOutcomes_initialCategoryParams() public {
        _addBatchWithDependencies(CURRENT_DATE + ONE_YEAR, 50000);

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 1000, 828e18); // you lose 8% from TA and then 10% from fee
        _assertBatchTaEqualsExactlyInitialCategoryTa();

        (uint decollateralizationAmountOut, , ) = manager.simulateDecollateralization(
            BATCH_ID,
            1000e18
        );
        assertEq(decollateralizationAmountOut, 978); // you lose 10% from fee and gain 1/0.92 from TA

        manager.collateralizeBatch(BATCH_ID, 1000, 828e18);
        _assertBatchTaEqualsApproxInitialCategoryTa();

        manager.collateralizeBatch(BATCH_ID, 1000, 828e18);
        _assertBatchTaEqualsApproxInitialCategoryTa();

        manager.collateralizeBatch(BATCH_ID, 1000, 828e18);
        _assertBatchTaEqualsApproxInitialCategoryTa();

        DomainDataTypes.Category memory category0 = manager.getCategory(CATEGORY_ID);
        assertEq(category0.averageTA, INITIAL_CATEGORY_TA);
        assertEq(category0.totalCollateralized, 4000);
        assertEq(category0.lastCollateralizationMomentum, 1000);
    }

    function testReactiveTAOutcomes_updatedCategoryParams_batch1YearFromCertification() public {
        _addBatchWithDependencies(CURRENT_DATE + ONE_YEAR + 5 days, 50000);

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10); // 5% decay per day

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, INITIAL_CATEGORY_TA);
        assertEq(category.totalCollateralized, 0);
        assertEq(category.lastCollateralizationMomentum, 10000);

        vm.warp(CURRENT_DATE + 5 days);
        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 5000, 4140e18);

        _assertBatchTaEqualsExactlyInitialCategoryTa();
        DomainDataTypes.Category memory category0 = manager.getCategory(CATEGORY_ID);
        assertEq(category0.averageTA, INITIAL_CATEGORY_TA);

        manager.collateralizeBatch(BATCH_ID, 10000, 8214.5e18);

        DomainDataTypes.Batch memory batch1 = manager.getBatch(BATCH_ID);
        assertApproxEqAbs(batch1.batchTA, 85000, 1);

        DomainDataTypes.Category memory category1 = manager.getCategory(CATEGORY_ID);
        assertEq(category1.averageTA, 85000);

        manager.collateralizeBatch(BATCH_ID, 20000, 16070e18);
        vm.stopPrank();

        DomainDataTypes.Batch memory batch2 = manager.getBatch(BATCH_ID);
        assertApproxEqAbs(batch2.batchTA, 97857, 2);

        DomainDataTypes.Category memory category2 = manager.getCategory(CATEGORY_ID);
        assertApproxEqAbs(category2.averageTA, 97857, 1);

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertApproxEqAbs(mintedERC20 + rewards, 5000e18 + 10000e18 + 20000e18, 0.065e18);

        vm.warp(CURRENT_DATE + 5 days);

        (, uint reactiveTABeforeUpdate0) = ReactiveTimeAppreciationMath.computeReactiveTA(
            manager.getCategory(CATEGORY_ID),
            0
        );

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 20); // 5% decay per day

        (, uint reactiveTAAfterUpdate0) = ReactiveTimeAppreciationMath.computeReactiveTA(
            manager.getCategory(CATEGORY_ID),
            0
        );

        assertEq(reactiveTABeforeUpdate0, reactiveTAAfterUpdate0);

        vm.warp(CURRENT_DATE + 100 days);
        (, uint reactiveTABeforeUpdate1) = ReactiveTimeAppreciationMath.computeReactiveTA(
            manager.getCategory(CATEGORY_ID),
            0
        );

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 0); // 0% decay per day

        (, uint reactiveTAAfterUpdate1) = ReactiveTimeAppreciationMath.computeReactiveTA(
            manager.getCategory(CATEGORY_ID),
            0
        );

        assertEq(reactiveTABeforeUpdate1, 77857);
        assertEq(reactiveTAAfterUpdate1, 97857); // values matching py implementation
    }

    function testReactiveTAOutcomes_updatedCategoryParams_batch7YearFromCertification() public {
        _addBatchWithDependencies(CURRENT_DATE + _yearsToSeconds(7) + 5 days, 50000);

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10); // 5% decay per day

        vm.warp(CURRENT_DATE + 5 days);
        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 5000, 0);

        _assertBatchTaEqualsExactlyInitialCategoryTa();
        DomainDataTypes.Category memory category0 = manager.getCategory(CATEGORY_ID);
        assertEq(category0.averageTA, INITIAL_CATEGORY_TA);

        manager.collateralizeBatch(BATCH_ID, 10000, 0);
        manager.collateralizeBatch(BATCH_ID, 20000, 0);
        vm.stopPrank();

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertApproxEqAbs(mintedERC20 + rewards, 5000e18 + 10000e18 + 20000e18, 0.11e18);
    }

    function testReactiveTAOutcomes_updatedCategoryParams_batch7YearFromCertification_moreCollateralizationOps()
        public
    {
        _addBatchWithDependencies(CURRENT_DATE + _yearsToSeconds(7) + 5 days, 50000);

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10); // 5% decay per day

        vm.warp(CURRENT_DATE + 5 days);
        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 5000, 0);

        _assertBatchTaEqualsExactlyInitialCategoryTa();
        DomainDataTypes.Category memory category0 = manager.getCategory(CATEGORY_ID);
        assertEq(category0.averageTA, INITIAL_CATEGORY_TA);

        manager.collateralizeBatch(BATCH_ID, 10000, 0);
        manager.collateralizeBatch(BATCH_ID, 20000, 0);
        manager.collateralizeBatch(BATCH_ID, 10000, 0);
        manager.collateralizeBatch(BATCH_ID, 5000, 0);
        vm.stopPrank();

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertApproxEqAbs(mintedERC20 + rewards, 50000e18, 0.425e18);
    }

    function testReactiveTAOutcomes_updatedCategoryParams_5Batches_7YearsFromCertification_1CollateralizationPerBatch()
        public
    {
        _addCategoryAndProjectWithApprovedSpending();
        for (uint i; i < 5; i++) {
            _addBatch(BATCH_ID + i, CURRENT_DATE + _yearsToSeconds(7) + 5 days, 50000);
        }

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10); // 5% decay per day

        vm.warp(CURRENT_DATE + 5 days);
        vm.startPrank(testAccount);
        for (uint i; i < 5; i++) {
            manager.collateralizeBatch(BATCH_ID + i, 10000, 0);
        }
        vm.stopPrank();

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertEq(mintedERC20 + rewards, 50000e18);
    }

    function testReactiveTAOutcomes_updatedCategoryParams_5Batches_7YearsFromCertification_5CollateralizationOps()
        public
    {
        _addCategoryAndProjectWithApprovedSpending();
        for (uint i; i < 5; i++) {
            _addBatch(BATCH_ID + i, CURRENT_DATE + _yearsToSeconds(7) + 5 days, 50000);
        }

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10); // 5% decay per day

        vm.warp(CURRENT_DATE + 5 days);
        vm.startPrank(testAccount);
        for (uint i; i < 5; i++) {
            manager.collateralizeBatch(BATCH_ID + i, 5000, 0);
            manager.collateralizeBatch(BATCH_ID + i, 10000, 0);
            manager.collateralizeBatch(BATCH_ID + i, 20000, 0);
            manager.collateralizeBatch(BATCH_ID + i, 10000, 0);
            manager.collateralizeBatch(BATCH_ID + i, 5000, 0);
        }
        vm.stopPrank();

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertApproxEqAbs(mintedERC20 + rewards, 250000e18, 0.965e18);
    }

    function testReactiveTAOutcomes_updatedCategoryParams_5Batches_7YearsFromCertif_5CollatOps_rewardsEqualForfeitedAmounts()
        public
    {
        _addCategoryAndProjectWithApprovedSpending();
        for (uint i; i < 5; i++) {
            _addBatch(BATCH_ID + i, CURRENT_DATE + _yearsToSeconds(7) + 5 days, 50000);
        }

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10); // 5% decay per day

        vm.warp(CURRENT_DATE + 5 days);
        uint[] memory cbtUserCut = new uint[](5);
        uint[] memory cbtDaoCut = new uint[](5);
        uint[] memory cbtForfeited = new uint[](5);
        vm.startPrank(testAccount);
        for (uint i; i < 5; i++) {
            uint[] memory _cbtUserCut = new uint[](5);
            uint[] memory _cbtDaoCut = new uint[](5);
            uint[] memory _cbtForfeited = new uint[](5);

            (_cbtUserCut[0], _cbtDaoCut[0], _cbtForfeited[0]) = manager
                .simulateBatchCollateralization(BATCH_ID + i, 5000);
            manager.collateralizeBatch(BATCH_ID + i, 5000, 0);

            (_cbtUserCut[1], _cbtDaoCut[1], _cbtForfeited[1]) = manager
                .simulateBatchCollateralization(BATCH_ID + i, 10000);
            manager.collateralizeBatch(BATCH_ID + i, 10000, 0);

            (_cbtUserCut[2], _cbtDaoCut[2], _cbtForfeited[2]) = manager
                .simulateBatchCollateralization(BATCH_ID + i, 20000);
            manager.collateralizeBatch(BATCH_ID + i, 20000, 0);

            (_cbtUserCut[3], _cbtDaoCut[3], _cbtForfeited[3]) = manager
                .simulateBatchCollateralization(BATCH_ID + i, 10000);
            manager.collateralizeBatch(BATCH_ID + i, 10000, 0);

            (_cbtUserCut[4], _cbtDaoCut[4], _cbtForfeited[4]) = manager
                .simulateBatchCollateralization(BATCH_ID + i, 5000);
            manager.collateralizeBatch(BATCH_ID + i, 5000, 0);

            cbtUserCut[i] =
                _cbtUserCut[0] +
                _cbtUserCut[1] +
                _cbtUserCut[2] +
                _cbtUserCut[3] +
                _cbtUserCut[4];
            cbtDaoCut[i] =
                _cbtDaoCut[0] +
                _cbtDaoCut[1] +
                _cbtDaoCut[2] +
                _cbtDaoCut[3] +
                _cbtDaoCut[4];
            cbtForfeited[i] =
                _cbtForfeited[0] +
                _cbtForfeited[1] +
                _cbtForfeited[2] +
                _cbtForfeited[3] +
                _cbtForfeited[4];
        }
        vm.stopPrank();

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint rewards = _computeRewards();
        uint cbtUserCutTotal = cbtUserCut[0] +
            cbtUserCut[1] +
            cbtUserCut[2] +
            cbtUserCut[3] +
            cbtUserCut[4];
        uint cbtDaoCutTotal = cbtDaoCut[0] +
            cbtDaoCut[1] +
            cbtDaoCut[2] +
            cbtDaoCut[3] +
            cbtDaoCut[4];
        uint cbtForfeitedTotal = cbtForfeited[0] +
            cbtForfeited[1] +
            cbtForfeited[2] +
            cbtForfeited[3] +
            cbtForfeited[4];

        assertEq(cbtUserCutTotal, userERC20Balance);
        assertEq(cbtDaoCutTotal, feesERC20);
        assertEq(cbtUserCutTotal + cbtDaoCutTotal + cbtForfeitedTotal, 250000e18);
        assertApproxEqAbs(cbtForfeitedTotal, rewards, 0.965e18);
    }

    function _assertBatchTaEqualsExactlyInitialCategoryTa() private {
        DomainDataTypes.Batch memory batch = manager.getBatch(BATCH_ID);
        assertEq(batch.batchTA, INITIAL_CATEGORY_TA);
    }

    function _assertBatchTaEqualsApproxInitialCategoryTa() private {
        DomainDataTypes.Batch memory batch = manager.getBatch(BATCH_ID);

        // probably just rounding happening in exponentiation math
        assertApproxEqAbs(batch.batchTA, INITIAL_CATEGORY_TA, 1);
    }

    function _computeRewards() private returns (uint rewards) {
        vm.warp(CURRENT_DATE + 5 days + 1);
        uint[] memory categories = new uint[](1);
        categories[0] = CATEGORY_ID;
        for (uint i = 1; i <= 52 * 7 + 2; i++) {
            (, uint[] memory rewardAmounts, uint[] memory rewardFees) = manager
                .computeWeeklyCarbonRewards(categories);
            rewards += rewardAmounts[0];
            rewards += rewardFees[0];
            vm.warp(CURRENT_DATE + 5 days + 1 + i * 1 weeks);
        }
    }
}
