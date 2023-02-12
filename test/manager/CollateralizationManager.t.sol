// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract CollateralizationManagerTest is BaseSolidWorldManager {
    uint24 constant TIME_APPRECIATION = 100_000; // 10%

    event BatchCollateralized(
        uint indexed batchId,
        address indexed batchSupplier,
        uint amountIn,
        uint amountOut
    );
    event CollateralizationFeeUpdated(uint indexed collateralizationFee);

    function testCollateralizeBatchWhenInvalidBatchId() public {
        _expectRevert_InvalidBatchId(1);
        manager.collateralizeBatch(CATEGORY_ID, 1, 0);
    }

    function testCollateralizeBatch_failsIfManagerIsPaused() public {
        manager.pause();

        _expectRevert_Paused();
        manager.collateralizeBatch(CATEGORY_ID, 1, 0);
    }

    function testCollateralizeBatch_whenCollateralizing0() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 12, 100);

        vm.prank(testAccount);
        _expectRevert_InvalidInput();
        manager.collateralizeBatch(BATCH_ID, 0, 0);
    }

    function testCollateralizeBatchWhenNotEnoughFunds() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 1 weeks, 100);

        vm.prank(testAccount);
        _expectRevertWithMessage("ERC1155: insufficient balance for transfer");
        manager.collateralizeBatch(BATCH_ID, 1000, 1000);
    }

    function testCollateralizeBatch_theWeekBeforeCertification() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 1 weeks - 1, 100);

        vm.prank(testAccount);
        _expectRevert_CannotCollateralizeTheWeekBeforeCertification();
        manager.collateralizeBatch(BATCH_ID, 100, 0);
    }

    function testCollateralizeBatchWhenERC20OutputIsLessThanMinimum() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 100);

        uint cbtUserCut = 81.03e18;
        vm.prank(testAccount);
        _expectRevert_AmountOutLessThanMinimum(81023310000000000000, cbtUserCut);
        manager.collateralizeBatch(BATCH_ID, 100, cbtUserCut);
    }

    function testCollateralizeBatch_failsIfBatchIsCertified() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + 1 weeks, 100);

        vm.warp(PRESET_CURRENT_DATE + 1 weeks);

        _expectRevert_BatchCertified(BATCH_ID);
        manager.collateralizeBatch(BATCH_ID, 100, 81e18);
    }

    function testCollateralizeBatchMintsERC20AndTransfersERC1155ToManager() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 100);

        uint cbtUserCut = 81e18;
        uint cbtDaoCut = 9e18;

        vm.prank(testAccount);
        _expectEmitBatchCollateralized(BATCH_ID, testAccount, 100, cbtUserCut);
        manager.collateralizeBatch(BATCH_ID, 100, cbtUserCut);

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 0);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 100);
        assertEq(manager.getBatch(BATCH_ID).collateralizedCredits, 100);
        assertApproxEqAbs(
            manager.getCategoryToken(CATEGORY_ID).balanceOf(testAccount),
            cbtUserCut,
            0.02331e18
        );
        assertApproxEqAbs(
            manager.getCategoryToken(CATEGORY_ID).balanceOf(feeReceiver),
            cbtDaoCut,
            0.00259e18
        );
    }

    function testCollateralizeBatch_updatesBatchTAAndRebalancesCategory() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + 1 weeks, 100);

        vm.prank(testAccount);
        _expectEmitCategoryRebalanced(CATEGORY_ID, TIME_APPRECIATION, 100);
        manager.collateralizeBatch(BATCH_ID, 100, 0);

        DomainDataTypes.Batch memory batch = manager.getBatch(BATCH_ID);
        assertEq(batch.batchTA, TIME_APPRECIATION);

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, TIME_APPRECIATION);
        assertEq(category.totalCollateralized, 100);
    }

    function testCollateralizeBatchWorksWhenCollateralizationFeeIs0() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 100);

        manager.setCollateralizationFee(0);

        uint cbtUserCut = 90e18;
        uint cbtDaoCut = 0;

        vm.prank(testAccount);
        _expectEmitBatchCollateralized(BATCH_ID, testAccount, 100, cbtUserCut);
        manager.collateralizeBatch(BATCH_ID, 100, cbtUserCut);

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 0);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 100);
        assertEq(manager.getBatch(BATCH_ID).collateralizedCredits, 100);
        assertApproxEqAbs(
            manager.getCategoryToken(CATEGORY_ID).balanceOf(testAccount),
            cbtUserCut,
            0.0259e18
        );
        assertEq(manager.getCategoryToken(CATEGORY_ID).balanceOf(feeReceiver), cbtDaoCut);
    }

    function testCollateralizeBatch_failsIfBatchIsNotAccumulating() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 100);

        manager.setBatchAccumulating(BATCH_ID, false);

        vm.prank(testAccount);
        _expectRevert_BatchCertified(BATCH_ID);
        manager.collateralizeBatch(BATCH_ID, 100, 0);
    }

    function testSimulateBatchCollateralization_inputAmountIs0() public {
        _expectRevert_InvalidInput();
        manager.simulateBatchCollateralization(BATCH_ID, 0);
    }

    function testSimulateBatchCollateralizationWhenBatchIdIsInvalid() public {
        _expectRevert_InvalidBatchId(BATCH_ID);
        manager.simulateBatchCollateralization(BATCH_ID, 10000);
    }

    function testSimulateBatchCollateralization_failsIfBatchIsCertified() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + 1 weeks, 10000);

        vm.warp(PRESET_CURRENT_DATE + 1 weeks);

        _expectRevert_BatchCertified(BATCH_ID);
        manager.simulateBatchCollateralization(BATCH_ID, 10000);
    }

    function testSimulateBatchCollateralization_weekBeforeCertification() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + 1 weeks - 1, 10000);
        _addBatch(BATCH_ID + 1, PRESET_CURRENT_DATE + 1, 10000);

        _expectRevert_CannotCollateralizeTheWeekBeforeCertification();
        manager.simulateBatchCollateralization(BATCH_ID, 10000);

        _expectRevert_CannotCollateralizeTheWeekBeforeCertification();
        manager.simulateBatchCollateralization(BATCH_ID + 1, 10000);
    }

    function testSimulateBatchCollateralization() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 10000);

        uint expectedCbtUserCut = 8100e18;
        uint expectedCbtDaoCut = 900e18;
        uint expectedCbtForfeited = 1000e18;

        (uint cbtUserCut, uint cbtDaoCut, uint cbtForfeited) = manager.simulateBatchCollateralization(
            BATCH_ID,
            10000
        );
        assertApproxEqAbs(cbtUserCut, expectedCbtUserCut, 2.331e18);
        assertApproxEqAbs(cbtDaoCut, expectedCbtDaoCut, 0.259e18);
        assertApproxEqAbs(cbtForfeited, expectedCbtForfeited, 2.59e18);
    }

    function testSimulateBatchCollateralization_failsIfBatchIsNotAccumulating() public {
        _addBatchWithDependencies(TIME_APPRECIATION, PRESET_CURRENT_DATE + ONE_YEAR, 100);

        manager.setBatchAccumulating(BATCH_ID, false);

        _expectRevert_BatchCertified(BATCH_ID);
        manager.simulateBatchCollateralization(BATCH_ID, 10000);
    }

    function testSetCollateralizationFee() public {
        uint16 newCollateralizationFee = 1234;

        _expectEmitFeeUpdated(newCollateralizationFee);
        manager.setCollateralizationFee(newCollateralizationFee);
        assertEq(manager.getCollateralizationFee(), newCollateralizationFee);
    }

    function _expectEmitCategoryRebalanced(
        uint categoryId,
        uint averageTA,
        uint totalCollateralized
    ) private {
        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(categoryId, averageTA, totalCollateralized);
    }

    function _expectEmitBatchCollateralized(
        uint batchId,
        address user,
        uint amount,
        uint cbtUserCut
    ) private {
        vm.expectEmit(true, true, false, false, address(manager));
        emit BatchCollateralized(batchId, user, amount, cbtUserCut);
    }

    function _expectEmitFeeUpdated(uint16 newCollateralizationFee) private {
        vm.expectEmit(true, false, false, false, address(manager));
        emit CollateralizationFeeUpdated(newCollateralizationFee);
    }

    function _expectRevert_InvalidBatchId(uint batchId) private {
        vm.expectRevert(abi.encodeWithSelector(CollateralizationManager.InvalidBatchId.selector, batchId));
    }

    function _expectRevert_InvalidInput() private {
        vm.expectRevert(abi.encodeWithSelector(CollateralizationManager.InvalidInput.selector));
    }

    function _expectRevert_CannotCollateralizeTheWeekBeforeCertification() private {
        vm.expectRevert(
            abi.encodeWithSelector(
                CollateralizationManager.CannotCollateralizeTheWeekBeforeCertification.selector
            )
        );
    }

    function _expectRevert_AmountOutLessThanMinimum(uint amountOut, uint minAmountOut) private {
        vm.expectRevert(
            abi.encodeWithSelector(
                CollateralizationManager.AmountOutLessThanMinimum.selector,
                amountOut,
                minAmountOut
            )
        );
    }

    function _expectRevert_BatchCertified(uint batchId) private {
        vm.expectRevert(abi.encodeWithSelector(CollateralizationManager.BatchCertified.selector, batchId));
    }
}
