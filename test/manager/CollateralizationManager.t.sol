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
        vm.expectRevert(
            abi.encodeWithSelector(CollateralizationManager.InvalidBatchId.selector, 1)
        );
        manager.collateralizeBatch(CATEGORY_ID, 1, 0);
    }

    function testCollateralizeBatch_failsIfManagerIsPaused() public {
        manager.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.Paused.selector));
        manager.collateralizeBatch(CATEGORY_ID, 1, 0);
    }

    function testCollateralizeBatch_whenCollateralizing0() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", 1);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            100
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        vm.expectRevert(abi.encodeWithSelector(CollateralizationManager.InvalidInput.selector));
        manager.collateralizeBatch(BATCH_ID, 0, 0);
        vm.stopPrank();
    }

    function testCollateralizeBatchWhenNotEnoughFunds() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", 1);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            100
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        vm.expectRevert(abi.encodePacked("ERC1155: insufficient balance for transfer"));
        manager.collateralizeBatch(BATCH_ID, 1000, 1000);
        vm.stopPrank();
    }

    function testCollateralizeBatch_theWeekBeforeCertification() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", 1);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks - 1),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            100
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        vm.expectRevert(
            abi.encodeWithSelector(
                CollateralizationManager.CannotCollateralizeTheWeekBeforeCertification.selector
            )
        );
        manager.collateralizeBatch(BATCH_ID, 100, 0);
        vm.stopPrank();
    }

    function testCollateralizeBatchWhenERC20OutputIsLessThanMinimum() public {
        uint cbtUserCut = 81.03e18;
        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            100
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        vm.expectRevert(
            abi.encodeWithSelector(
                CollateralizationManager.AmountOutLessThanMinimum.selector,
                81023310000000000000,
                cbtUserCut
            )
        );
        manager.collateralizeBatch(BATCH_ID, 100, cbtUserCut);
        vm.stopPrank();
    }

    function testCollateralizeBatch_failsIfBatchIsCertified() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            100
        );

        vm.warp(CURRENT_DATE + 1 weeks);

        vm.expectRevert(
            abi.encodeWithSelector(CollateralizationManager.BatchCertified.selector, 5)
        );
        manager.collateralizeBatch(BATCH_ID, 100, 81e18);
    }

    function testCollateralizeBatchMintsERC20AndTransfersERC1155ToManager() public {
        uint cbtUserCut = 81e18;
        uint cbtDaoCut = 9e18;

        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            100
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);

        vm.expectEmit(true, true, false, false, address(manager));
        emit BatchCollateralized(BATCH_ID, testAccount, 100, cbtUserCut);
        manager.collateralizeBatch(BATCH_ID, 100, cbtUserCut);

        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 0);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 100);
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
        manager.addCategory(CATEGORY_ID, "", "", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            100
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);

        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(CATEGORY_ID, TIME_APPRECIATION, 100);
        manager.collateralizeBatch(BATCH_ID, 100, 0);
        vm.stopPrank();

        DomainDataTypes.Batch memory batch = manager.getBatch(BATCH_ID);
        assertEq(batch.batchTA, TIME_APPRECIATION);

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, TIME_APPRECIATION);
        assertEq(category.totalCollateralized, 100);
    }

    function testCollateralizeBatchWorksWhenCollateralizationFeeIs0() public {
        manager.setCollateralizationFee(0);

        uint cbtUserCut = 90e18;
        uint cbtDaoCut = 0;

        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            100
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);

        vm.expectEmit(true, true, false, false, address(manager));
        emit BatchCollateralized(BATCH_ID, testAccount, 100, cbtUserCut);
        manager.collateralizeBatch(BATCH_ID, 100, cbtUserCut);

        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 0);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 100);
        assertApproxEqAbs(
            manager.getCategoryToken(CATEGORY_ID).balanceOf(testAccount),
            cbtUserCut,
            0.0259e18
        );
        assertEq(manager.getCategoryToken(CATEGORY_ID).balanceOf(feeReceiver), cbtDaoCut);
    }

    function testCollateralizeBatchWorks_failsIfBatchIsNotAccumulating() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            100
        );

        manager.setBatchAccumulating(BATCH_ID, false);
        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);

        vm.expectRevert(
            abi.encodeWithSelector(CollateralizationManager.BatchCertified.selector, BATCH_ID)
        );
        manager.collateralizeBatch(BATCH_ID, 100, 0);

        vm.stopPrank();
    }

    function testSimulateBatchCollateralization_inputAmountIs0() public {
        vm.expectRevert(abi.encodeWithSelector(CollateralizationManager.InvalidInput.selector));
        manager.simulateBatchCollateralization(BATCH_ID, 0);
    }

    function testSimulateBatchCollateralizationWhenBatchIdIsInvalid() public {
        vm.expectRevert(
            abi.encodeWithSelector(CollateralizationManager.InvalidBatchId.selector, 5)
        );
        manager.simulateBatchCollateralization(BATCH_ID, 10000);
    }

    function testSimulateBatchCollateralization_failsIfBatchIsCertified() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2025,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            10000
        );

        vm.warp(CURRENT_DATE + 1 weeks);

        vm.expectRevert(
            abi.encodeWithSelector(CollateralizationManager.BatchCertified.selector, 5)
        );
        manager.simulateBatchCollateralization(BATCH_ID, 10000);
    }

    function testSimulateBatchCollateralization_weekBeforeCertification() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks - 1),
                vintage: 2025,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            10000
        );
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 1,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1),
                vintage: 2025,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            10000
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                CollateralizationManager.CannotCollateralizeTheWeekBeforeCertification.selector
            )
        );
        manager.simulateBatchCollateralization(BATCH_ID, 10000);

        vm.expectRevert(
            abi.encodeWithSelector(
                CollateralizationManager.CannotCollateralizeTheWeekBeforeCertification.selector
            )
        );
        manager.simulateBatchCollateralization(BATCH_ID + 1, 10000);
    }

    function testSimulateBatchCollateralization() public {
        uint expectedCbtUserCut = 8100e18;
        uint expectedCbtDaoCut = 900e18;
        uint expectedCbtForfeited = 1000e18;

        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
                vintage: 2025,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            10000
        );

        (uint cbtUserCut, uint cbtDaoCut, uint cbtForfeited) = manager
            .simulateBatchCollateralization(BATCH_ID, 10000);
        assertApproxEqAbs(cbtUserCut, expectedCbtUserCut, 2.331e18);
        assertApproxEqAbs(cbtDaoCut, expectedCbtDaoCut, 0.259e18);
        assertApproxEqAbs(cbtForfeited, expectedCbtForfeited, 2.59e18);
    }

    function testSimulateBatchCollateralization_failsIfBatchIsNotAccumulating() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
                vintage: 2025,
                batchTA: 0,
                supplier: testAccount,
                isAccumulating: false
            }),
            10000
        );

        manager.setBatchAccumulating(BATCH_ID, false);

        vm.expectRevert(
            abi.encodeWithSelector(CollateralizationManager.BatchCertified.selector, BATCH_ID)
        );
        manager.simulateBatchCollateralization(BATCH_ID, 10000);
    }

    function testSetCollateralizationFee() public {
        uint16 newCollateralizationFee = 1234;

        vm.expectEmit(true, false, false, false, address(manager));
        emit CollateralizationFeeUpdated(newCollateralizationFee);
        manager.setCollateralizationFee(newCollateralizationFee);
        assertEq(manager.getCollateralizationFee(), newCollateralizationFee);
    }
}
