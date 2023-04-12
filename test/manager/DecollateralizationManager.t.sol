// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract DecollateralizationManagerTest is BaseSolidWorldManager {
    uint24 constant TIME_APPRECIATION = 100_000; // 10%

    event TokensDecollateralized(
        uint indexed batchId,
        address indexed tokensOwner,
        uint amountIn,
        uint amountOut
    );
    event FeeReceiverUpdated(address indexed feeReceiver);
    event DecollateralizationFeeUpdated(uint indexed decollateralizationFee);
    event BoostedDecollateralizationFeeUpdated(uint indexed boostedDecollateralizationFee);

    function testDecollateralizeTokens_inputAmountIs0() public {
        _expectRevert_InvalidInput();
        manager.decollateralizeTokens(BATCH_ID, 0, 0);
    }

    function testDecollateralizeTokens_failsIfManagerIsPaused() public {
        manager.pause();

        _expectRevert_Paused();
        manager.decollateralizeTokens(BATCH_ID, 0, 0);
    }

    function testDecollateralizeTokensWhenInvalidBatchId() public {
        _expectRevert_InvalidBatchId(BATCH_ID);
        manager.decollateralizeTokens(BATCH_ID, 10, 5);
    }

    function testDecollateralizeTokens_failsIfDecollateralizingMoreTokensThanOwned() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 12, 100);

        vm.prank(testAccount);
        _expectRevertWithMessage("ERC20: burn amount exceeds balance");
        manager.decollateralizeTokens(BATCH_ID, 1000e18, 500);
    }

    function testDecollateralizeTokens_failsWithoutApprovingManagerToSpendTokens() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 12, 100);

        vm.startPrank(testAccount);
        manager.getCategoryToken(CATEGORY_ID).approve(address(manager), 0);

        _expectRevertWithMessage("ERC20: insufficient allowance");
        manager.decollateralizeTokens(BATCH_ID, 1000e18, 500);
    }

    function testDecollateralizeTokensWhenERC20InputIsTooLow() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + 1 weeks, 10000);

        uint amountOutMin = 81e18;

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, amountOutMin);
        _expectRevert_AmountOutTooLow(0);
        manager.decollateralizeTokens(BATCH_ID, 1e17, 0);
    }

    function testDecollateralizeTokensWhenERC1155OutputIsLessThanMinimum() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);

        uint cbtUserCut = 81e18;

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, cbtUserCut);
        _expectRevert_AmountOutLessThanMinimum(80, 10000);
        manager.decollateralizeTokens(BATCH_ID, cbtUserCut, 10000);
        assertEq(manager.getBatch(BATCH_ID).collateralizedCredits, 10000);
    }

    function testDecollateralizeTokens_whenBatchIsCertified() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);

        uint cbtUserCut = 8100e18;
        uint cbtDaoCut = 900e18;

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, cbtUserCut);

        vm.warp(PRESET_CURRENT_DATE + ONE_YEAR);

        uint expectedAmountDecollateralized = (8100 / 100) * 99; // 8019
        _expectEmitTokensDecollateralized(BATCH_ID, testAccount, cbtUserCut, expectedAmountDecollateralized);
        manager.decollateralizeTokens(BATCH_ID, cbtUserCut, expectedAmountDecollateralized);

        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), expectedAmountDecollateralized);
        assertEq(
            forwardContractBatch.balanceOf(address(manager), BATCH_ID),
            10000 - expectedAmountDecollateralized
        );
        assertEq(manager.getBatch(BATCH_ID).collateralizedCredits, 10000 - expectedAmountDecollateralized);
        assertEq(manager.getCategoryToken(CATEGORY_ID).balanceOf(testAccount), 2.331e18);
        assertApproxEqAbs(
            manager.getCategoryToken(CATEGORY_ID).balanceOf(feeReceiver),
            cbtDaoCut + 81e18,
            0.26e18
        );
    }

    function testDecollateralizeTokensBurnsERC20AndReceivesERC1155() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);

        uint cbtUserCut = 8102.331e18;
        uint cbtDaoCut = 900e18;

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, cbtUserCut);

        _expectEmitTokensDecollateralized(BATCH_ID, testAccount, cbtUserCut, 8099);
        manager.decollateralizeTokens(BATCH_ID, cbtUserCut, 8100);

        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 8100);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 10000 - 8100);
        assertEq(manager.getBatch(BATCH_ID).collateralizedCredits, 10000 - 8100);
        assertEq(manager.getCategoryToken(CATEGORY_ID).balanceOf(testAccount), 0);
        assertApproxEqAbs(
            manager.getCategoryToken(CATEGORY_ID).balanceOf(feeReceiver),
            cbtDaoCut + 810.2331e18,
            0.259e18
        );
    }

    function testDecollateralizeTokens_triggersCategoryRebalance() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);

        uint cbtUserCut = 8100e18;

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, cbtUserCut);

        _expectEmitTokensDecollateralized(BATCH_ID, testAccount, cbtUserCut, 8097);
        _expectEmitCategoryRebalanced(CATEGORY_ID, TIME_APPRECIATION, 10000 - 8097);
        manager.decollateralizeTokens(BATCH_ID, cbtUserCut, 8097);
        vm.stopPrank();

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, TIME_APPRECIATION);
        assertEq(category.totalCollateralized, 10000 - 8097);
    }

    function testBulkDecollateralizeTokens_failsIfManagerIsPaused() public {
        manager.pause();

        _expectRevert_Paused();
        manager.bulkDecollateralizeTokens(new uint[](1), new uint[](1), new uint[](2));
    }

    function testDecollateralizeTokens_triggersCategoryRebalance_batchesNotAccumulatingAreIgnored() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);
        _addBatch(BATCH_ID + 1, PROJECT_ID, PRESET_CURRENT_DATE + ONE_YEAR, 99999, 10000);

        uint cbtUserCut = 8100e18;

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, cbtUserCut);
        manager.collateralizeBatch(BATCH_ID + 1, 10000, 0);
        vm.stopPrank();

        manager.setBatchAccumulating(BATCH_ID + 1, false);

        vm.startPrank(testAccount);
        _expectEmitTokensDecollateralized(BATCH_ID, testAccount, cbtUserCut, 8097);
        _expectEmitCategoryRebalanced(CATEGORY_ID, TIME_APPRECIATION, 10000 - 8097);
        manager.decollateralizeTokens(BATCH_ID, cbtUserCut, 8097);
        vm.stopPrank();

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, TIME_APPRECIATION);
        assertEq(category.totalCollateralized, 10000 - 8097);
        assertEq(manager.getBatch(BATCH_ID).collateralizedCredits, 10000 - 8097);
        assertEq(manager.getBatch(BATCH_ID + 1).collateralizedCredits, 10000);
    }

    function testBulkDecollateralizeTokensWhenInvalidInput() public {
        uint[] memory arrayLength1 = new uint[](1);
        uint[] memory arrayLength2 = new uint[](2);

        _expectRevert_InvalidInput();
        manager.bulkDecollateralizeTokens(arrayLength1, arrayLength2, arrayLength1);

        _expectRevert_InvalidInput();
        manager.bulkDecollateralizeTokens(arrayLength1, arrayLength1, arrayLength2);

        _expectRevert_InvalidInput();
        manager.bulkDecollateralizeTokens(arrayLength2, arrayLength1, arrayLength2);

        _expectRevert_InvalidInput();
        manager.bulkDecollateralizeTokens(arrayLength2, arrayLength1, arrayLength1);
    }

    function testBulkDecollateralizeTokens_failsForBatchesBelongingToDifferentCategories() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);
        _addBatchWithDependencies(
            CATEGORY_ID + 1,
            PROJECT_ID + 1,
            BATCH_ID + 1,
            TIME_APPRECIATION,
            PRESET_CURRENT_DATE + ONE_YEAR,
            10000
        );

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, 8100e18);
        manager.collateralizeBatch(BATCH_ID + 1, 10000, 8100e18);

        uint[] memory batchIds = new uint[](2);
        batchIds[0] = BATCH_ID;
        batchIds[1] = BATCH_ID + 1;
        uint[] memory amountsIn = new uint[](2);
        amountsIn[0] = 4000e18;
        amountsIn[1] = 4000e18;
        uint[] memory amountsOutMin = new uint[](2);
        amountsOutMin[0] = 4000;
        amountsOutMin[1] = 4000;

        _expectRevert_BatchesNotInSameCategory(CATEGORY_ID + 1, CATEGORY_ID);
        manager.bulkDecollateralizeTokens(batchIds, amountsIn, amountsOutMin);
    }

    function testBulkDecollateralizeTokens_inputAmountIs0() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);
        _addBatch(BATCH_ID + 1, PRESET_CURRENT_DATE + ONE_YEAR, 10000);

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, 8100e18);
        manager.collateralizeBatch(BATCH_ID + 1, 10000, 8100e18);

        uint[] memory batchIds = new uint[](2);
        batchIds[0] = BATCH_ID;
        batchIds[1] = BATCH_ID + 1;
        uint[] memory amountsIn = new uint[](2);
        amountsIn[0] = 4000e18;
        amountsIn[1] = 0;
        uint[] memory amountsOutMin = new uint[](2);
        amountsOutMin[0] = 3998;
        amountsOutMin[1] = 0;

        _expectRevert_InvalidInput();
        manager.bulkDecollateralizeTokens(batchIds, amountsIn, amountsOutMin);
    }

    function testBulkDecollateralizeTokens_verifyTokenBalances() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);
        _addBatch(BATCH_ID + 1, PRESET_CURRENT_DATE + ONE_YEAR, 10000);

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, 8100e18);
        manager.collateralizeBatch(BATCH_ID + 1, 10000, 8100e18);

        uint[] memory batchIds = new uint[](2);
        batchIds[0] = BATCH_ID;
        batchIds[1] = BATCH_ID + 1;
        uint[] memory amountsIn = new uint[](2);
        amountsIn[0] = 4000e18;
        amountsIn[1] = 4000e18;
        uint[] memory amountsOutMin = new uint[](2);
        amountsOutMin[0] = 3998;
        amountsOutMin[1] = 3998;

        manager.bulkDecollateralizeTokens(batchIds, amountsIn, amountsOutMin);
        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 3998);
        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID + 1), 3998);

        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 10000 - 3998);
        assertEq(manager.getBatch(BATCH_ID).collateralizedCredits, 10000 - 3998);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID + 1), 10000 - 3998);
        assertEq(manager.getBatch(BATCH_ID + 1).collateralizedCredits, 10000 - 3998);

        assertEq(
            manager.getCategoryToken(CATEGORY_ID).balanceOf(testAccount),
            8102.331e18 + 8102.331e18 - 4000e18 - 4000e18
        );
    }

    function testBulkDecollateralizeTokens_triggersCategoryRebalance() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);
        _addBatch(BATCH_ID + 1, PRESET_CURRENT_DATE + ONE_YEAR, 10000);

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, 8100e18);
        manager.collateralizeBatch(BATCH_ID + 1, 10000, 8100e18);

        uint[] memory batchIds = new uint[](2);
        batchIds[0] = BATCH_ID;
        batchIds[1] = BATCH_ID + 1;
        uint[] memory amountsIn = new uint[](2);
        amountsIn[0] = 4000e18;
        amountsIn[1] = 4000e18;
        uint[] memory amountsOutMin = new uint[](2);
        amountsOutMin[0] = 3998;
        amountsOutMin[1] = 3998;

        uint newTotalCollateralized = 2 * (10000 - 3998);
        uint newAverageTA = TIME_APPRECIATION;

        _expectEmitCategoryRebalanced(CATEGORY_ID, newAverageTA, newTotalCollateralized);
        manager.bulkDecollateralizeTokens(batchIds, amountsIn, amountsOutMin);
        vm.stopPrank();

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, newAverageTA);
        assertEq(category.totalCollateralized, newTotalCollateralized);
    }

    function testBulkDecollateralizeTokens_triggersCategoryRebalance_batchesNotAccumulatingAreIgnored()
        public
    {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);
        _addBatch(BATCH_ID + 1, PRESET_CURRENT_DATE + ONE_YEAR, 10000);
        _addBatch(BATCH_ID + 2, PROJECT_ID, PRESET_CURRENT_DATE + ONE_YEAR, 99999, 10000);

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, 8100e18);
        manager.collateralizeBatch(BATCH_ID + 1, 10000, 8100e18);
        manager.collateralizeBatch(BATCH_ID + 2, 10000, 0);
        vm.stopPrank();

        manager.setBatchAccumulating(BATCH_ID + 2, false);
        vm.startPrank(testAccount);

        uint[] memory batchIds = new uint[](2);
        batchIds[0] = BATCH_ID;
        batchIds[1] = BATCH_ID + 1;
        uint[] memory amountsIn = new uint[](2);
        amountsIn[0] = 4000e18;
        amountsIn[1] = 4000e18;
        uint[] memory amountsOutMin = new uint[](2);
        amountsOutMin[0] = 3998;
        amountsOutMin[1] = 3998;

        uint newTotalCollateralized = 2 * (10000 - 3998);
        uint newAverageTA = TIME_APPRECIATION;

        _expectEmitCategoryRebalanced(CATEGORY_ID, newAverageTA, newTotalCollateralized);
        manager.bulkDecollateralizeTokens(batchIds, amountsIn, amountsOutMin);
        vm.stopPrank();

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, newAverageTA);
        assertEq(category.totalCollateralized, newTotalCollateralized);
    }

    function testGetBatchesDecollateralizationInfo() public {
        _addCategoryAndProjectWithApprovedSpending(CATEGORY_ID, PROJECT_ID, TIME_APPRECIATION);
        _addCategoryAndProjectWithApprovedSpending(CATEGORY_ID + 1, PROJECT_ID + 1, TIME_APPRECIATION);
        _addBatchWithVintageToProject(BATCH_ID, PROJECT_ID, 2022);
        _addBatchWithVintageToProject(BATCH_ID + 1, PROJECT_ID, 2022);
        _addBatchWithVintageToProject(BATCH_ID + 2, PROJECT_ID, 2023);
        _addBatchWithVintageToProject(BATCH_ID + 3, PROJECT_ID + 1, 2022);
        _addBatchWithVintageToProject(BATCH_ID + 4, PROJECT_ID, 2022);

        vm.startPrank(testAccount);

        manager.collateralizeBatch(BATCH_ID, 5000, 0);
        manager.collateralizeBatch(BATCH_ID + 1, 5100, 0);
        manager.collateralizeBatch(BATCH_ID + 2, 5200, 0);
        manager.collateralizeBatch(BATCH_ID + 3, 5300, 0);
        manager.collateralizeBatch(BATCH_ID + 4, 5400, 0);

        vm.stopPrank();

        DomainDataTypes.TokenDecollateralizationInfo[] memory info = manager
            .getBatchesDecollateralizationInfo(PROJECT_ID, 2022);

        assertEq(info.length, 3);
        assertEq(info[0].batchId, BATCH_ID);
        assertEq(info[0].availableBatchTokens, 5000);
        assertEq(info[0].amountOut, 999);

        assertEq(info[1].batchId, BATCH_ID + 1);
        assertEq(info[1].availableBatchTokens, 5100);
        assertEq(info[1].amountOut, 999);

        assertEq(info[2].batchId, BATCH_ID + 4);
        assertEq(info[2].availableBatchTokens, 5400);
        assertEq(info[2].amountOut, 999);
    }

    function testGetBoostedDecollateralizationFee() public {
        assertEq(manager.getBoostedDecollateralizationFee(), BOOSTED_DECOLLATERALIZATION_FEE);
    }

    function testSetDecollateralizationFee() public {
        uint16 newDecollateralizationFee = 1234;

        vm.prank(timelockController);
        _expectEmitDecollateralizationFeeUpdated(newDecollateralizationFee);
        manager.setDecollateralizationFee(newDecollateralizationFee);
        assertEq(manager.getDecollateralizationFee(), newDecollateralizationFee);
    }

    function testSetBoostedDecollateralizationFee() public {
        uint16 newBoostedDecollateralizationFee = 1234;

        vm.prank(timelockController);
        _expectEmitBoostedDecollateralizationFeeUpdated(newBoostedDecollateralizationFee);
        manager.setBoostedDecollateralizationFee(newBoostedDecollateralizationFee);
        assertEq(manager.getBoostedDecollateralizationFee(), newBoostedDecollateralizationFee);
    }

    function testSetFeeReceiver() public {
        address newFeeReceiver = vm.addr(1234);

        _expectEmitFeeReceiverUpdated(newFeeReceiver);
        manager.setFeeReceiver(newFeeReceiver);
        assertEq(manager.getFeeReceiver(), newFeeReceiver);
    }

    function testSimulateReverseDecollateralization_revertsForInvalidBatchId() public {
        _expectRevert_InvalidBatchId(BATCH_ID);
        manager.simulateReverseDecollateralization(BATCH_ID, 10000);
    }

    function testSimulateReverseDecollateralization() public {
        _addCategoryAndProjectWithApprovedSpending(CATEGORY_ID, PROJECT_ID, TIME_APPRECIATION);
        _addBatchWithVintageToProject(BATCH_ID, PROJECT_ID, 2023);

        vm.prank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, 8100e18);

        uint forwardCreditsAmount = 5000;

        (uint minCbt, uint minCbtDaoCut) = manager.simulateReverseDecollateralization(
            BATCH_ID,
            forwardCreditsAmount
        );

        assertApproxEqAbs(minCbt, 5000e18, 1.438888888888888888e18);
        assertApproxEqAbs(minCbtDaoCut, 500e18, 0.143888888888888888e18);
    }

    function testSimulateReverseDecollateralization_certifiedBatch() public {
        _addCategoryAndProjectWithApprovedSpending(CATEGORY_ID, PROJECT_ID, TIME_APPRECIATION);
        _addBatchWithVintageToProject(BATCH_ID, PROJECT_ID, 2023);

        vm.prank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, 8100e18);

        // certify batch
        vm.warp(PRESET_CURRENT_DATE + ONE_YEAR + 1);

        uint forwardCreditsAmount = 5000;

        (uint minCbt, uint minCbtDaoCut) = manager.simulateReverseDecollateralization(
            BATCH_ID,
            forwardCreditsAmount
        );

        assertApproxEqAbs(minCbt, 5050e18, 0.6e18);
        assertApproxEqAbs(minCbtDaoCut, 50.5e18, 0.006e18);
    }

    function testSimulateReverseDecollateralization_resultSatisfiesActualDecollateralization() public {
        _addCategoryAndProjectWithApprovedSpending(CATEGORY_ID, PROJECT_ID, TIME_APPRECIATION);
        _addBatchWithVintageToProject(BATCH_ID, PROJECT_ID, 2023);
        CollateralizedBasketToken cbt = manager.getCategoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        manager.collateralizeBatch(BATCH_ID, 10000, 8100e18);

        uint forwardCreditsAmount = 5000;

        (uint minCbt, uint minCbtDaoCut) = manager.simulateReverseDecollateralization(
            BATCH_ID,
            forwardCreditsAmount
        );

        (uint _forwardCreditsAmount, uint _minCbt, uint _minCbtDaoCut) = manager.simulateDecollateralization(
            BATCH_ID,
            minCbt
        );

        assertEq(_forwardCreditsAmount, forwardCreditsAmount);
        assertEq(_minCbt, minCbt);
        assertEq(_minCbtDaoCut, minCbtDaoCut);

        uint totalFeesCollectedBefore = cbt.balanceOf(manager.getFeeReceiver());
        manager.decollateralizeTokens(BATCH_ID, minCbt, forwardCreditsAmount);
        uint totalFeesCollectedAfter = cbt.balanceOf(manager.getFeeReceiver());

        assertEq(manager.forwardContractBatch().balanceOf(testAccount, BATCH_ID), forwardCreditsAmount);
        assertEq(totalFeesCollectedAfter - totalFeesCollectedBefore, minCbtDaoCut);
    }

    function _addBatchWithVintageToProject(
        uint batchId,
        uint projectId,
        uint vintage
    ) private {
        manager.addBatch(
            DomainDataTypes.Batch({
                id: batchId,
                status: 0,
                projectId: projectId,
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + ONE_YEAR,
                vintage: uint16(vintage),
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            10000
        );
    }

    function _expectEmitTokensDecollateralized(
        uint batchId,
        address tokensOwner,
        uint amountIn,
        uint amountOut
    ) private {
        vm.expectEmit(true, true, false, false, address(manager));
        emit TokensDecollateralized(batchId, tokensOwner, amountIn, amountOut);
    }

    function _expectEmitCategoryRebalanced(
        uint categoryId,
        uint newAverageTA,
        uint newTotalCollateralized
    ) private {
        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(categoryId, newAverageTA, newTotalCollateralized);
    }

    function _expectEmitDecollateralizationFeeUpdated(uint16 newDecollateralizationFee) private {
        vm.expectEmit(true, true, false, false, address(manager));
        emit DecollateralizationFeeUpdated(newDecollateralizationFee);
    }

    function _expectEmitBoostedDecollateralizationFeeUpdated(uint16 newBoostedDecollateralizationFee)
        private
    {
        vm.expectEmit(true, true, false, false, address(manager));
        emit BoostedDecollateralizationFeeUpdated(newBoostedDecollateralizationFee);
    }

    function _expectEmitFeeReceiverUpdated(address newFeeReceiver) private {
        vm.expectEmit(true, false, false, false, address(manager));
        emit FeeReceiverUpdated(newFeeReceiver);
    }

    function _expectRevert_InvalidInput() private {
        vm.expectRevert(abi.encodeWithSelector(DecollateralizationManager.InvalidInput.selector));
    }

    function _expectRevert_InvalidBatchId(uint batchId) private {
        vm.expectRevert(abi.encodeWithSelector(DecollateralizationManager.InvalidBatchId.selector, batchId));
    }

    function _expectRevert_AmountOutTooLow(uint amount) private {
        vm.expectRevert(abi.encodeWithSelector(DecollateralizationManager.AmountOutTooLow.selector, amount));
    }

    function _expectRevert_AmountOutLessThanMinimum(uint amountOut, uint amountOutMin) private {
        vm.expectRevert(
            abi.encodeWithSelector(
                DecollateralizationManager.AmountOutLessThanMinimum.selector,
                amountOut,
                amountOutMin
            )
        );
    }

    function _expectRevert_BatchesNotInSameCategory(uint categoryId1, uint categoryId2) private {
        vm.expectRevert(
            abi.encodeWithSelector(
                DecollateralizationManager.BatchesNotInSameCategory.selector,
                categoryId1,
                categoryId2
            )
        );
    }
}
