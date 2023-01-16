// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract DecollateralizationManagerTest is BaseSolidWorldManager {
    uint24 constant TIME_APPRECIATION = 100_000; // 10%

    event TokensDecollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed tokensOwner
    );
    event FeeReceiverUpdated(address indexed feeReceiver);
    event DecollateralizationFeeUpdated(uint indexed decollateralizationFee);

    function testDecollateralizeTokensWhenInvalidBatchId() public {
        vm.expectRevert(
            abi.encodeWithSelector(DecollateralizationManager.InvalidBatchId.selector, 5)
        );
        manager.decollateralizeTokens(BATCH_ID, 10, 5);
    }

    function testDecollateralizeTokensWhenNotEnoughFunds() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount
            }),
            100
        );

        vm.expectRevert(abi.encodePacked("ERC20: insufficient allowance"));
        manager.decollateralizeTokens(BATCH_ID, 1000e18, 500);
    }

    function testDecollateralizeTokensWhenERC20InputIsTooLow() public {
        uint amountOutMin = 81e18;

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
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.getCategoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), 10000);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 10000, amountOutMin);
        vm.expectRevert(
            abi.encodeWithSelector(DecollateralizationManager.AmountOutTooLow.selector, 0)
        );
        manager.decollateralizeTokens(BATCH_ID, 1e17, 0);
        vm.stopPrank();
    }

    function testDecollateralizeTokensWhenERC1155OutputIsLessThanMinimum() public {
        uint cbtUserCut = 81e18;

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
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.getCategoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), 10000);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 10000, cbtUserCut);
        vm.expectRevert(
            abi.encodeWithSelector(
                DecollateralizationManager.AmountOutLessThanMinimum.selector,
                81,
                10000
            )
        );
        manager.decollateralizeTokens(BATCH_ID, cbtUserCut, 10000);
        vm.stopPrank();
    }

    function testDecollateralizeTokens_whenBatchIsCertified() public {
        uint cbtUserCut = 8100e18;
        uint cbtDaoCut = 900e18;

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
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.getCategoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), cbtUserCut);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 10000, cbtUserCut);

        vm.warp(CURRENT_DATE + 1 weeks);

        uint expectedAmountDecollateralized = (8100 / 10) * 9; // 90%
        vm.expectEmit(true, true, true, true, address(manager));
        emit TokensDecollateralized(
            BATCH_ID,
            cbtUserCut,
            expectedAmountDecollateralized,
            testAccount
        );
        manager.decollateralizeTokens(BATCH_ID, cbtUserCut, expectedAmountDecollateralized);

        vm.stopPrank();

        assertEq(
            forwardContractBatch.balanceOf(testAccount, BATCH_ID),
            expectedAmountDecollateralized
        );
        assertEq(
            forwardContractBatch.balanceOf(address(manager), BATCH_ID),
            10000 - expectedAmountDecollateralized
        );
        assertEq(manager.getCategoryToken(CATEGORY_ID).balanceOf(testAccount), 0);
        assertEq(manager.getCategoryToken(CATEGORY_ID).balanceOf(feeReceiver), cbtDaoCut + 810e18);
    }

    function testDecollateralizeTokensBurnsERC20AndReceivesERC1155() public {
        uint cbtUserCut = 8100e18;
        uint cbtDaoCut = 900e18;

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
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.getCategoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), cbtUserCut);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 10000, cbtUserCut);

        vm.expectEmit(true, true, true, true, address(manager));
        emit TokensDecollateralized(BATCH_ID, cbtUserCut, 8100, testAccount);
        manager.decollateralizeTokens(BATCH_ID, cbtUserCut, 8100);

        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 8100);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 10000 - 8100);
        assertEq(manager.getCategoryToken(CATEGORY_ID).balanceOf(testAccount), 0);
        assertEq(manager.getCategoryToken(CATEGORY_ID).balanceOf(feeReceiver), cbtDaoCut + 810e18);
    }

    function testDecollateralizeTokens_triggersCategoryRebalance() public {
        uint cbtUserCut = 8100e18;

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
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.getCategoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), cbtUserCut);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 10000, cbtUserCut);

        vm.expectEmit(true, true, true, true, address(manager));
        emit TokensDecollateralized(BATCH_ID, cbtUserCut, 8100, testAccount);
        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(CATEGORY_ID, TIME_APPRECIATION, 10000 - 8100);
        manager.decollateralizeTokens(BATCH_ID, cbtUserCut, 8100);
        vm.stopPrank();

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, TIME_APPRECIATION);
        assertEq(category.totalCollateralized, 10000 - 8100);
    }

    function testBulkDecollateralizeTokensWhenInvalidInput() public {
        uint[] memory arrayLength1 = new uint[](1);
        uint[] memory arrayLength2 = new uint[](2);

        vm.expectRevert(abi.encodeWithSelector(DecollateralizationManager.InvalidInput.selector));
        manager.bulkDecollateralizeTokens(arrayLength1, arrayLength2, arrayLength1);

        vm.expectRevert(abi.encodeWithSelector(DecollateralizationManager.InvalidInput.selector));
        manager.bulkDecollateralizeTokens(arrayLength1, arrayLength1, arrayLength2);

        vm.expectRevert(abi.encodeWithSelector(DecollateralizationManager.InvalidInput.selector));
        manager.bulkDecollateralizeTokens(arrayLength2, arrayLength1, arrayLength2);

        vm.expectRevert(abi.encodeWithSelector(DecollateralizationManager.InvalidInput.selector));
        manager.bulkDecollateralizeTokens(arrayLength2, arrayLength1, arrayLength1);
    }

    function testBulkDecollateralizeTokens_failsForBatchesBelongingToDifferentCategories() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addCategory(CATEGORY_ID + 1, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 1,
                status: 0,
                projectId: PROJECT_ID + 1,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.getCategoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), 8000e18);
        forwardContractBatch.setApprovalForAll(address(manager), true);
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

        vm.expectRevert(
            abi.encodeWithSelector(
                DecollateralizationManager.BatchesNotInSameCategory.selector,
                CATEGORY_ID + 1,
                CATEGORY_ID
            )
        );
        manager.bulkDecollateralizeTokens(batchIds, amountsIn, amountsOutMin);
        vm.stopPrank();
    }

    function testBulkDecollateralizeTokens_verifyTokenBalances() public {
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
                supplier: testAccount
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 1,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.getCategoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), 8000e18);
        forwardContractBatch.setApprovalForAll(address(manager), true);
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

        manager.bulkDecollateralizeTokens(batchIds, amountsIn, amountsOutMin);
        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 4000);
        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID + 1), 4000);

        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 10000 - 4000);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID + 1), 10000 - 4000);

        assertEq(
            manager.getCategoryToken(CATEGORY_ID).balanceOf(testAccount),
            8100e18 + 8100e18 - 4000e18 - 4000e18
        );
    }

    function testBulkDecollateralizeTokens_triggersCategoryRebalance() public {
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
                supplier: testAccount
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 1,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.getCategoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), 8000e18);
        forwardContractBatch.setApprovalForAll(address(manager), true);
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

        uint newTotalCollateralized = 2 * (10000 - 4000);
        uint newAverageTA = TIME_APPRECIATION;

        vm.expectEmit(true, true, true, false, address(manager));
        emit CategoryRebalanced(CATEGORY_ID, newAverageTA, newTotalCollateralized);
        manager.bulkDecollateralizeTokens(batchIds, amountsIn, amountsOutMin);
        vm.stopPrank();

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, newAverageTA);
        assertEq(category.totalCollateralized, newTotalCollateralized);
    }

    function testGetBatchesDecollateralizationInfo() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", TIME_APPRECIATION);
        manager.addCategory(CATEGORY_ID + 1, "Test token", "TT", TIME_APPRECIATION);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 1,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 2,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2023,
                batchTA: 0,
                supplier: testAccount
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 3,
                status: 0,
                projectId: PROJECT_ID + 1,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID + 4,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                batchTA: 0,
                supplier: testAccount
            }),
            10000
        );

        vm.startPrank(testAccount);
        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        forwardContractBatch.setApprovalForAll(address(manager), true);

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
        assertEq(info[0].amountOut, 1000);

        assertEq(info[1].batchId, BATCH_ID + 1);
        assertEq(info[1].availableBatchTokens, 5100);
        assertEq(info[1].amountOut, 1000);

        assertEq(info[2].batchId, BATCH_ID + 4);
        assertEq(info[2].availableBatchTokens, 5400);
        assertEq(info[2].amountOut, 1000);
    }

    function testSetDecollateralizationFee() public {
        uint16 newDecollateralizationFee = 1234;

        vm.expectEmit(true, false, false, false, address(manager));
        emit DecollateralizationFeeUpdated(newDecollateralizationFee);
        manager.setDecollateralizationFee(newDecollateralizationFee);
        assertEq(manager.getDecollateralizationFee(), newDecollateralizationFee);
    }

    function testSetFeeReceiver() public {
        address newFeeReceiver = vm.addr(1234);

        vm.expectEmit(true, false, false, false, address(manager));
        emit FeeReceiverUpdated(newFeeReceiver);
        manager.setFeeReceiver(newFeeReceiver);
        assertEq(manager.getFeeReceiver(), newFeeReceiver);
    }
}