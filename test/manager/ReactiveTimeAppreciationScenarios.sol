// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract ReactiveTimeAppreciationScenarios is BaseSolidWorldManager {
    function testReactiveTAOutcomes_initialCategoryParams() public {
        manager.addCategory(CATEGORY_ID, "", "", INITIAL_CATEGORY_TA); // 8% per year
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 52 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            50000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 1000, 828e18); // you lose 8% from TA and then 10% from fee
        vm.stopPrank();

        DomainDataTypes.Batch memory batch0 = manager.getBatch(BATCH_ID);
        assertEq(batch0.batchTA, INITIAL_CATEGORY_TA);

        (uint decollateralizationAmountOut, , ) = manager.simulateDecollateralization(
            BATCH_ID,
            1000e18
        );

        assertEq(decollateralizationAmountOut, 978); // you lose 10% from fee and gain 1/0.92 from TA

        vm.prank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 1000, 828e18);

        DomainDataTypes.Batch memory batch1 = manager.getBatch(BATCH_ID);
        // probably not precision loss, but just rounding happening in exponentiation math
        assertApproxEqAbs(batch1.batchTA, INITIAL_CATEGORY_TA, 1);

        vm.prank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 1000, 828e18);

        DomainDataTypes.Batch memory batch2 = manager.getBatch(BATCH_ID);
        assertApproxEqAbs(batch2.batchTA, INITIAL_CATEGORY_TA, 1);

        vm.prank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 1000, 828e18);

        DomainDataTypes.Batch memory batch3 = manager.getBatch(BATCH_ID);
        assertApproxEqAbs(batch3.batchTA, INITIAL_CATEGORY_TA, 1);

        DomainDataTypes.Category memory category0 = manager.getCategory(CATEGORY_ID);

        assertApproxEqAbs(category0.averageTA, INITIAL_CATEGORY_TA, 1);
        assertEq(category0.totalCollateralized, 4000);
        assertEq(category0.lastCollateralizationMomentum, 1000);
    }

    function testReactiveTAOutcomes_updatedCategoryParams_batch1YearFromCertification() public {
        manager.addCategory(CATEGORY_ID, "", "", INITIAL_CATEGORY_TA); // 8% per year
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 52 weeks + 5 days),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            50000
        );

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        cbt.approve(address(manager), type(uint).max);
        vm.stopPrank();

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10, 193); // 5% decay per day

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, INITIAL_CATEGORY_TA);
        assertEq(category.totalCollateralized, 0);
        assertEq(category.lastCollateralizationMomentum, 10000);

        vm.warp(CURRENT_DATE + 5 days);
        vm.prank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 5000, 4140e18);

        DomainDataTypes.Batch memory batch0 = manager.getBatch(BATCH_ID);
        assertEq(batch0.batchTA, INITIAL_CATEGORY_TA);
        DomainDataTypes.Category memory category0 = manager.getCategory(CATEGORY_ID);
        assertEq(category0.averageTA, INITIAL_CATEGORY_TA);

        vm.prank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, 8218.6e18);

        DomainDataTypes.Batch memory batch1 = manager.getBatch(BATCH_ID);
        assertApproxEqAbs(batch1.batchTA, 1696, 1);

        DomainDataTypes.Category memory category1 = manager.getCategory(CATEGORY_ID);
        assertApproxEqAbs(category1.averageTA, 1696, 1);

        vm.prank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 20000, 16104.5e18);

        DomainDataTypes.Batch memory batch2 = manager.getBatch(BATCH_ID);
        assertApproxEqAbs(batch2.batchTA, 1947, 1);

        DomainDataTypes.Category memory category2 = manager.getCategory(CATEGORY_ID);
        assertApproxEqAbs(category2.averageTA, 1948, 1);

        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertApproxEqAbs(mintedERC20 + rewards, 5000e18 + 10000e18 + 20000e18, 4.74e18);
        /// 35000 - 34995 = 5
        /// 5 / 35000 = 0.0001428571429 ~ 0.0143% error for 3 collateralizations, batch is 1 year from certification
        /// 5 carbon credits are lost in the math operations and rounding

        vm.warp(CURRENT_DATE + 5 days);

        (, uint reactiveTABeforeUpdate0) = ReactiveTimeAppreciationMath.computeReactiveTA(
            manager.getCategory(CATEGORY_ID),
            0
        );

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 20, 387); // 5% decay per day

        (, uint reactiveTAAfterUpdate0) = ReactiveTimeAppreciationMath.computeReactiveTA(
            manager.getCategory(CATEGORY_ID),
            0
        );

        assertApproxEqAbs(reactiveTABeforeUpdate0, reactiveTAAfterUpdate0, 7); // 0.27% error

        vm.warp(CURRENT_DATE + 100 days);
        (, uint reactiveTABeforeUpdate1) = ReactiveTimeAppreciationMath.computeReactiveTA(
            manager.getCategory(CATEGORY_ID),
            0
        );

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 0, 0); // 0% decay per day

        (, uint reactiveTAAfterUpdate1) = ReactiveTimeAppreciationMath.computeReactiveTA(
            manager.getCategory(CATEGORY_ID),
            0
        );

        assertEq(reactiveTABeforeUpdate1, 1561);
        assertEq(reactiveTAAfterUpdate1, 1948); // values matching py implementation
    }

    function testReactiveTAOutcomes_updatedCategoryParams_batch7YearFromCertification() public {
        manager.addCategory(CATEGORY_ID, "", "", INITIAL_CATEGORY_TA); // 8% per year
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 7 * 52 weeks + 5 days),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            50000
        );

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        cbt.approve(address(manager), type(uint).max);
        vm.stopPrank();

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10, 193); // 5% decay per day

        vm.warp(CURRENT_DATE + 5 days);
        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 5000, 0);

        DomainDataTypes.Batch memory batch0 = manager.getBatch(BATCH_ID);
        assertEq(batch0.batchTA, INITIAL_CATEGORY_TA);
        DomainDataTypes.Category memory category0 = manager.getCategory(CATEGORY_ID);
        assertEq(category0.averageTA, INITIAL_CATEGORY_TA);

        manager.collateralizeBatch(BATCH_ID, 10000, 0);
        manager.collateralizeBatch(BATCH_ID, 20000, 0);
        vm.stopPrank();

        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertApproxEqAbs(mintedERC20 + rewards, 5000e18 + 10000e18 + 20000e18, 28.3368e18);
        /// 35000 - 34971.66 = 28.34
        /// 28.34 / 35000 = 0.0008097142857 ~ 0.081% error for 3 collateralizations, batch is 7 years from certification
        /// 29 carbon credits are lost in the math operations and rounding
    }

    function testReactiveTAOutcomes_updatedCategoryParams_batch7YearFromCertification_moreCollateralizationOps()
        public
    {
        manager.addCategory(CATEGORY_ID, "", "", INITIAL_CATEGORY_TA); // 8% per year
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 7 * 52 weeks + 5 days),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            50000
        );

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        cbt.approve(address(manager), type(uint).max);
        vm.stopPrank();

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10, 193); // 5% decay per day

        vm.warp(CURRENT_DATE + 5 days);
        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 5000, 0);

        DomainDataTypes.Batch memory batch0 = manager.getBatch(BATCH_ID);
        assertEq(batch0.batchTA, INITIAL_CATEGORY_TA);
        DomainDataTypes.Category memory category0 = manager.getCategory(CATEGORY_ID);
        assertEq(category0.averageTA, INITIAL_CATEGORY_TA);

        manager.collateralizeBatch(BATCH_ID, 10000, 0);
        manager.collateralizeBatch(BATCH_ID, 20000, 0);
        manager.collateralizeBatch(BATCH_ID, 10000, 0);
        manager.collateralizeBatch(BATCH_ID, 5000, 0);
        vm.stopPrank();

        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertApproxEqAbs(mintedERC20 + rewards, 50000e18, 50.45e18);
        /// 50000 - 49949.55 = 50.45
        /// 50.45 / 50000 = 0.001009 ~ 0.1% error for 5 collateralizations, batch is 7 years from certification
        /// 51 carbon credits are lost in the math operations and rounding
    }

    function testReactiveTAOutcomes_updatedCategoryParams_5Batches_7YearsFromCertification_1CollateralizationPerBatch()
        public
    {
        manager.addCategory(CATEGORY_ID, "", "", INITIAL_CATEGORY_TA); // 8% per year
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        for (uint i; i < 5; i++) {
            manager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID,
                    certificationDate: uint32(CURRENT_DATE + 7 * 52 weeks + 5 days),
                    vintage: 2022,
                    batchTA: 0,
                    supplier: testAccount
                }),
                50000
            );
        }

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        cbt.approve(address(manager), type(uint).max);
        vm.stopPrank();

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10, 193); // 5% decay per day

        vm.warp(CURRENT_DATE + 5 days);
        vm.startPrank(testAccount);
        for (uint i; i < 5; i++) {
            manager.collateralizeBatch(BATCH_ID + i, 10000, 0);
        }
        vm.stopPrank();

        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertApproxEqAbs(mintedERC20 + rewards, 50000e18, 64e18);
        /// 50000 - 49936.23 = 63.77
        /// 63,77 / 50000 = 0.0012754 ~ 0.13% error for 5 batches, 5 collateralizations, batch is 7 years from certification
        /// 64 carbon credits are lost in the math operations and rounding
    }

    function testReactiveTAOutcomes_updatedCategoryParams_5Batches_7YearsFromCertification_5CollateralizationOps()
        public
    {
        manager.addCategory(CATEGORY_ID, "", "", INITIAL_CATEGORY_TA); // 8% per year
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        for (uint i; i < 5; i++) {
            manager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID,
                    certificationDate: uint32(CURRENT_DATE + 7 * 52 weeks + 5 days),
                    vintage: 2022,
                    batchTA: 0,
                    supplier: testAccount
                }),
                50000
            );
        }

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        cbt.approve(address(manager), type(uint).max);
        vm.stopPrank();

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10, 193); // 5% decay per day

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

        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertApproxEqAbs(mintedERC20 + rewards, 250000e18, 1335e18);
        /// 250000 - 248665.1 = 1334.9
        /// 1334.9 / 250000 = 0.0053396 ~ 0.53% error for 5 batches, 25 collateralizations, batch is 7 years from certification
        /// 1335 carbon credits are lost in the math operations and rounding
    }

    function testReactiveTAOutcomes_updatedCategoryParams_5Batches_7YearsFromCertif_5CollatOps_rewardsEqualForfeitedAmounts()
        internal
    {
        manager.addCategory(CATEGORY_ID, "", "", INITIAL_CATEGORY_TA); // 8% per year
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        for (uint i; i < 5; i++) {
            manager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID,
                    certificationDate: uint32(CURRENT_DATE + 7 * 52 weeks + 5 days),
                    vintage: 2022,
                    batchTA: 0,
                    supplier: testAccount
                }),
                50000
            );
        }

        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);
        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        cbt.approve(address(manager), type(uint).max);
        vm.stopPrank();

        manager.updateCategory(CATEGORY_ID, 10000, 57870, 10, 193); // 5% decay per day

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

        uint userERC20Balance = cbt.balanceOf(testAccount);
        uint feesERC20 = cbt.balanceOf(feeReceiver);
        uint mintedERC20 = userERC20Balance + feesERC20;
        uint rewards = _computeRewards();

        assertApproxEqAbs(mintedERC20 + rewards, 250000e18, 1335e18);
        /// 250000 - 248665.1 = 1334.9
        /// 1334.9 / 250000 = 0.0053396 ~ 0.53% error for 5 batches, 25 collateralizations, batch is 7 years from certification
        /// 1335 carbon credits are lost in the math operations and rounding

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

        console.log(cbtUserCutTotal, "cbtUserCutTotal");
        console.log(cbtDaoCutTotal, "cbtDaoCutTotal");
        console.log(cbtForfeitedTotal, "cbtForfeitedTotal");
        (, uint reactiveTA) = ReactiveTimeAppreciationMath.computeReactiveTA(
            manager.getCategory(CATEGORY_ID),
            0
        );
        console.log(reactiveTA, "reactiveTA");
        console.log(manager.getBatch(BATCH_ID + 4).batchTA, "batchTA");
        console.log(manager.getCategory(CATEGORY_ID).averageTA, "averageTA");
        console.log(
            manager.getCategory(CATEGORY_ID).lastCollateralizationMomentum,
            "lastCollateralizationMomentum"
        );

        assertEq(cbtUserCutTotal, userERC20Balance);
        assertEq(cbtDaoCutTotal, feesERC20);
        assertEq(cbtUserCutTotal + cbtDaoCutTotal + cbtForfeitedTotal, 250000e18);
        assertApproxEqAbs(cbtForfeitedTotal, rewards, 0);
    }

    function _computeRewards() internal returns (uint rewards) {
        uint[] memory categories = new uint[](1);
        categories[0] = CATEGORY_ID;
        for (uint i = 1; i <= 52 * 7 + 1; i++) {
            (, uint[] memory rewardAmounts, uint[] memory rewardFees) = manager
                .computeWeeklyCarbonRewards(categories);
            rewards += rewardAmounts[0];
            rewards += rewardFees[0];
            vm.warp(CURRENT_DATE + 5 days + i * 1 weeks);
        }
    }
}
