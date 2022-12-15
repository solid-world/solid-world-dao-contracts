// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract SolidWorldManagerTest is BaseSolidWorldManager {
    uint24 constant TIME_APPRECIATION = 100_000; // 10%

    event BatchCollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed batchSupplier
    );
    event TokensDecollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed tokensOwner
    );
    event CategoryCreated(uint indexed categoryId);
    event ProjectCreated(uint indexed projectId);
    event BatchCreated(uint indexed batchId);

    function testAddCategory() public {
        assertEq(address(manager.categoryToken(CATEGORY_ID)), address(0));
        assertEq(manager.categoryIds(CATEGORY_ID), false);
        (, , , uint24 averageTAStart, , , ) = manager.categories(CATEGORY_ID);
        assertEq(averageTAStart, 0);

        vm.expectEmit(true, false, false, false, address(manager));
        emit CategoryCreated(CATEGORY_ID);
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);

        assertNotEq(address(manager.categoryToken(CATEGORY_ID)), address(0));
        assertEq(manager.categoryIds(CATEGORY_ID), true);

        (, , , uint24 averageTA, , , ) = manager.categories(CATEGORY_ID);
        assertEq(averageTA, INITIAL_CATEGORY_TA);
    }

    function testAddProject() public {
        uint projectId = 5;
        uint categoryId = 3;

        assertEq(manager.projectIds(projectId), false);

        manager.addCategory(categoryId, "Test token", "TT", INITIAL_CATEGORY_TA);

        vm.expectEmit(true, false, false, false, address(manager));
        emit ProjectCreated(projectId);
        manager.addProject(categoryId, projectId);

        assertEq(manager.projectIds(projectId), true);
    }

    function testAddMultipleProjects() public {
        assertEq(manager.getProjectIdsByCategory(3).length, 0);

        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);
        manager.addProject(3, 7);

        assertEq(manager.getProjectIdsByCategory(3).length, 2);
        assertEq(manager.getProjectIdsByCategory(3)[0], 5);
        assertEq(manager.getProjectIdsByCategory(3)[1], 7);
    }

    function testFailAddProjectWhenCategoryDoesntExist() public {
        manager.addProject(3, 5);
    }

    function testFailAddProjectWhenProjectAlreadyAdded() public {
        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);
        manager.addProject(3, 5);
    }

    function testAddBatch() public {
        uint batchId = 7;

        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);

        assertEq(manager.batchCreated(batchId), false);

        vm.expectEmit(true, false, false, false, address(manager));
        emit BatchCreated(batchId);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: batchId,
                status: 0,
                projectId: 5,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                reactiveTA: 1,
                supplier: testAccount
            }),
            10
        );

        assertEq(manager.batchCreated(batchId), true);

        (
            uint id,
            uint projectId,
            address supplier,
            uint32 certificationDate,
            uint16 vintage,
            uint8 status,
            uint24 reactiveTA
        ) = manager.batches(batchId);

        assertEq(id, batchId);
        assertEq(status, 0);
        assertEq(projectId, 5);
        assertEq(certificationDate, uint32(CURRENT_DATE + 12));
        assertEq(vintage, 2022);
        assertEq(reactiveTA, 1);
        assertEq(supplier, testAccount);
        assertEq(manager.batchIds(0), batchId);
    }

    function testAddMultipleBatches() public {
        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);

        assertEq(manager.getBatchIdsByProject(5).length, 0);

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                reactiveTA: 1,
                supplier: testAccount
            }),
            10
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 11,
                status: 0,
                projectId: 5,
                certificationDate: uint32(CURRENT_DATE + 24),
                vintage: 2022,
                reactiveTA: 1,
                supplier: testAccount
            }),
            20
        );

        assertEq(manager.getBatchIdsByProject(5).length, 2);
        assertEq(manager.getBatchIdsByProject(5)[0], 7);
        assertEq(manager.getBatchIdsByProject(5)[1], 11);
    }

    function testAddBatchIssuesERC1155Tokens() public {
        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);

        assertEq(manager.forwardContractBatch().balanceOf(address(this), 7), 0);

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                reactiveTA: 1,
                supplier: testAccount
            }),
            10
        );

        assertEq(manager.forwardContractBatch().balanceOf(testAccount, 7), 10);
    }

    function testCollateralizeBatchWhenInvalidBatchId() public {
        vm.expectRevert(
            abi.encodeWithSelector(ISolidWorldManagerErrors.InvalidBatchId.selector, 1)
        );
        manager.collateralizeBatch(CATEGORY_ID, 0, 0);
    }

    function testCollateralizeBatchWhenNotEnoughFunds() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                reactiveTA: 1,
                supplier: testAccount
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

    function testCollateralizeBatchWhenERC20OutputIsLessThanMinimum() public {
        uint cbtUserCut = 81e18;
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                reactiveTA: TIME_APPRECIATION,
                supplier: testAccount
            }),
            100
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISolidWorldManagerErrors.AmountOutLessThanMinimum.selector,
                cbtUserCut,
                cbtUserCut + 1
            )
        );
        manager.collateralizeBatch(BATCH_ID, 100, cbtUserCut + 1);
        vm.stopPrank();
    }

    function testCollateralizeBatch_failsIfBatchIsCertified() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                reactiveTA: TIME_APPRECIATION,
                supplier: testAccount
            }),
            100
        );

        vm.warp(CURRENT_DATE + 1 weeks);

        vm.expectRevert(
            abi.encodeWithSelector(ISolidWorldManagerErrors.BatchCertified.selector, 5)
        );
        manager.collateralizeBatch(BATCH_ID, 100, 81e18);
    }

    function testCollateralizeBatchMintsERC20AndTransfersERC1155ToManager() public {
        uint cbtUserCut = 81e18;
        uint cbtDaoCut = 9e18;

        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                reactiveTA: TIME_APPRECIATION,
                supplier: testAccount
            }),
            100
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);

        vm.expectEmit(true, true, false, true, address(manager));
        emit BatchCollateralized(BATCH_ID, 100, cbtUserCut, testAccount);
        manager.collateralizeBatch(BATCH_ID, 100, cbtUserCut);

        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 0);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 100);
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(testAccount), cbtUserCut);
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(feeReceiver), cbtDaoCut);
    }

    function testCollateralizeBatchWorksWhenCollateralizationFeeIs0() public {
        manager.setCollateralizationFee(0);

        uint cbtUserCut = 90e18;
        uint cbtDaoCut = 0;

        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                reactiveTA: TIME_APPRECIATION,
                supplier: testAccount
            }),
            100
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);

        vm.expectEmit(true, true, false, true, address(manager));
        emit BatchCollateralized(BATCH_ID, 100, cbtUserCut, testAccount);
        manager.collateralizeBatch(BATCH_ID, 100, cbtUserCut);

        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 0);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 100);
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(testAccount), cbtUserCut);
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(feeReceiver), cbtDaoCut);
    }

    function testDecollateralizeTokensWhenInvalidBatchId() public {
        vm.expectRevert(
            abi.encodeWithSelector(ISolidWorldManagerErrors.InvalidBatchId.selector, 5)
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
                reactiveTA: 1,
                supplier: testAccount
            }),
            100
        );

        vm.expectRevert(abi.encodePacked("ERC20: insufficient allowance"));
        manager.decollateralizeTokens(BATCH_ID, 1000e18, 500);
    }

    function testDecollateralizeTokensWhenERC20InputIsTooLow() public {
        uint amountOutMin = 81e18;

        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                reactiveTA: TIME_APPRECIATION,
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.categoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), 10000);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 10000, amountOutMin);
        vm.expectRevert(
            abi.encodeWithSelector(ISolidWorldManagerErrors.AmountOutTooLow.selector, 0)
        );
        manager.decollateralizeTokens(BATCH_ID, 1e17, 0);
        vm.stopPrank();
    }

    function testDecollateralizeTokensWhenERC1155OutputIsLessThanMinimum() public {
        uint cbtUserCut = 81e18;

        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                reactiveTA: TIME_APPRECIATION,
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.categoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), 10000);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 10000, cbtUserCut);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISolidWorldManagerErrors.AmountOutLessThanMinimum.selector,
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

        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                reactiveTA: TIME_APPRECIATION,
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.categoryToken(CATEGORY_ID);

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
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(testAccount), 0);
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(feeReceiver), cbtDaoCut + 810e18);
    }

    function testDecollateralizeTokensBurnsERC20AndReceivesERC1155() public {
        uint cbtUserCut = 8100e18;
        uint cbtDaoCut = 900e18;

        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                reactiveTA: TIME_APPRECIATION,
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.categoryToken(CATEGORY_ID);

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
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(testAccount), 0);
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(feeReceiver), cbtDaoCut + 810e18);
    }

    function testSimulateBatchCollateralizationWhenBatchIdIsInvalid() public {
        vm.expectRevert(
            abi.encodeWithSelector(ISolidWorldManagerErrors.InvalidBatchId.selector, 5)
        );
        manager.simulateBatchCollateralization(BATCH_ID, 10000);
    }

    function testSimulateBatchCollateralization_failsIfBatchIsCertified() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2025,
                reactiveTA: TIME_APPRECIATION,
                supplier: testAccount
            }),
            10000
        );

        vm.warp(CURRENT_DATE + 1 weeks);

        vm.expectRevert(
            abi.encodeWithSelector(ISolidWorldManagerErrors.BatchCertified.selector, 5)
        );
        manager.simulateBatchCollateralization(BATCH_ID, 10000);
    }

    function testSimulateBatchCollateralization() public {
        uint expectedCbtUserCut = 8100e18;
        uint expectedCbtDaoCut = 900e18;
        uint expectedCbtForfeited = 1000e18;

        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2025,
                reactiveTA: TIME_APPRECIATION,
                supplier: testAccount
            }),
            10000
        );

        (uint cbtUserCut, uint cbtDaoCut, uint cbtForfeited) = manager
            .simulateBatchCollateralization(BATCH_ID, 10000);

        assertEq(cbtUserCut, expectedCbtUserCut);
        assertEq(cbtDaoCut, expectedCbtDaoCut);
        assertEq(cbtForfeited, expectedCbtForfeited);
    }

    function testBulkDecollateralizeTokensWhenInvalidInput() public {
        uint[] memory arrayLength1 = new uint[](1);
        uint[] memory arrayLength2 = new uint[](2);

        vm.expectRevert(abi.encodeWithSelector(ISolidWorldManagerErrors.InvalidInput.selector));
        manager.bulkDecollateralizeTokens(arrayLength1, arrayLength2, arrayLength1);

        vm.expectRevert(abi.encodeWithSelector(ISolidWorldManagerErrors.InvalidInput.selector));
        manager.bulkDecollateralizeTokens(arrayLength1, arrayLength1, arrayLength2);

        vm.expectRevert(abi.encodeWithSelector(ISolidWorldManagerErrors.InvalidInput.selector));
        manager.bulkDecollateralizeTokens(arrayLength2, arrayLength1, arrayLength2);

        vm.expectRevert(abi.encodeWithSelector(ISolidWorldManagerErrors.InvalidInput.selector));
        manager.bulkDecollateralizeTokens(arrayLength2, arrayLength1, arrayLength1);
    }

    function testBulkDecollateralizeTokens() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                reactiveTA: TIME_APPRECIATION,
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
                reactiveTA: 5_0000, // 5%
                supplier: testAccount
            }),
            10000
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.categoryToken(CATEGORY_ID);

        vm.startPrank(testAccount);
        collateralizedToken.approve(address(manager), 8000e18);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 10000, 8100e18);
        manager.collateralizeBatch(BATCH_ID + 1, 10000, 8550e18);

        uint[] memory batchIds = new uint[](2);
        batchIds[0] = BATCH_ID;
        batchIds[1] = BATCH_ID + 1;
        uint[] memory amountsIn = new uint[](2);
        amountsIn[0] = 4000e18;
        amountsIn[1] = 4000e18;
        uint[] memory amountsOutMin = new uint[](2);
        amountsOutMin[0] = 4000;
        amountsOutMin[1] = 3789;

        manager.bulkDecollateralizeTokens(batchIds, amountsIn, amountsOutMin);
        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID), 4000);
        assertEq(forwardContractBatch.balanceOf(testAccount, BATCH_ID + 1), 3789);

        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 10000 - 4000);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID + 1), 10000 - 3789);

        assertEq(
            manager.categoryToken(CATEGORY_ID).balanceOf(testAccount),
            8100e18 + 8550e18 - 4000e18 - 4000e18
        );
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(feeReceiver), 2650e18);
    }

    function testGetBatchesDecollateralizationInfo() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addCategory(CATEGORY_ID + 1, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                certificationDate: uint32(CURRENT_DATE + 1 weeks),
                vintage: 2022,
                reactiveTA: TIME_APPRECIATION,
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
                reactiveTA: TIME_APPRECIATION,
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
                reactiveTA: TIME_APPRECIATION,
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
                reactiveTA: TIME_APPRECIATION,
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
                reactiveTA: 5_0000, // 5%
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
        assertEq(info[2].amountOut, 947);
    }

    function testFailAddBatchWhenProjectDoesntExist() public {
        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                reactiveTA: 1,
                supplier: testAccount
            }),
            10000
        );
    }

    function testFailAddBatchWhenBatchAlreadyAdded() public {
        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                reactiveTA: 1,
                supplier: testAccount
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                reactiveTA: 1,
                supplier: testAccount
            }),
            10000
        );
    }

    function testFailAddBatchWhenSupplierIsNotDefined() public {
        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                certificationDate: uint32(CURRENT_DATE + 12),
                vintage: 2022,
                reactiveTA: 1,
                supplier: address(0)
            }),
            10000
        );
    }

    function testFailAddBatchWhenDueDateIsNow() public {
        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                certificationDate: uint32(CURRENT_DATE),
                vintage: 2022,
                reactiveTA: 1,
                supplier: testAccount
            }),
            10000
        );
    }

    function testFailAddBatchWhenDueDateInThePast() public {
        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                certificationDate: uint32(CURRENT_DATE - 1),
                vintage: 2022,
                reactiveTA: 1,
                supplier: testAccount
            }),
            10000
        );
    }

    function assertNotEq(address a, address b) private {
        if (a == b) {
            emit log("Error: a != b not satisfied [address]");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }
}
