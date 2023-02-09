// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./BaseSolidWorldManager.t.sol";

contract CarbonDomainRepositoryTest is BaseSolidWorldManager {
    event CategoryCreated(uint indexed categoryId);
    event CategoryUpdated(
        uint indexed categoryId,
        uint indexed volumeCoefficient,
        uint indexed decayPerSecond,
        uint maxDepreciation
    );
    event ProjectCreated(uint indexed projectId);
    event BatchCreated(uint indexed batchId);

    function testAddCategory() public {
        assertEq(address(manager.getCategoryToken(CATEGORY_ID)), address(0));
        assertEq(manager.isCategoryCreated(CATEGORY_ID), false);
        DomainDataTypes.Category memory categoryStart = manager.getCategory(CATEGORY_ID);
        assertEq(categoryStart.averageTA, 0);

        _expectEmitCategoryCreated();
        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);

        assertNotEq(address(manager.getCategoryToken(CATEGORY_ID)), address(0));
        assertEq(manager.isCategoryCreated(CATEGORY_ID), true);

        DomainDataTypes.Category memory category = manager.getCategory(CATEGORY_ID);
        assertEq(category.averageTA, INITIAL_CATEGORY_TA);
    }

    function testUpdateCategory_failsForInvalidCategoryId() public {
        _expectRevert_InvalidCategoryId(CATEGORY_ID);
        manager.updateCategory(CATEGORY_ID, 0, 0, 0);
    }

    function testUpdateCategory_failsForInvalidInput() public {
        manager.addCategory(CATEGORY_ID, "", "", INITIAL_CATEGORY_TA);

        _expectRevert_InvalidInput();
        manager.updateCategory(CATEGORY_ID, 0, 0, 0);
    }

    function testUpdateCategory() public {
        manager.addCategory(CATEGORY_ID, "", "", INITIAL_CATEGORY_TA);

        uint volumeCoefficientInput0 = 50000;
        uint40 decayPerSecondInput0 = _getTestDecayPerSecond();
        uint16 maxDepreciationInput0 = 10;
        // 1% yearly rate

        vm.warp(PRESET_CURRENT_DATE + 2 days);
        _expectEmitCategoryUpdated(
            CATEGORY_ID,
            volumeCoefficientInput0,
            decayPerSecondInput0,
            maxDepreciationInput0
        );
        manager.updateCategory(
            CATEGORY_ID,
            volumeCoefficientInput0,
            decayPerSecondInput0,
            maxDepreciationInput0
        );

        DomainDataTypes.Category memory category0 = manager.getCategory(CATEGORY_ID);

        assertEq(category0.volumeCoefficient, volumeCoefficientInput0);
        assertEq(category0.decayPerSecond, decayPerSecondInput0);
        assertEq(category0.maxDepreciation, maxDepreciationInput0);
        assertEq(category0.lastCollateralizationTimestamp, PRESET_CURRENT_DATE + 2 days);
        assertEq(category0.lastCollateralizationMomentum, 50000);

        uint volumeCoefficientInput1 = 75000;
        uint40 decayPerSecondInput1 = _getTestDecayPerSecond();
        uint16 maxDepreciationInput1 = 20;
        // 2% yearly rate

        vm.warp(PRESET_CURRENT_DATE + 4 days);
        _expectEmitCategoryUpdated(
            CATEGORY_ID,
            volumeCoefficientInput1,
            decayPerSecondInput1,
            maxDepreciationInput1
        );
        manager.updateCategory(
            CATEGORY_ID,
            volumeCoefficientInput1,
            decayPerSecondInput1,
            maxDepreciationInput1
        );

        DomainDataTypes.Category memory category1 = manager.getCategory(CATEGORY_ID);

        assertEq(category1.volumeCoefficient, volumeCoefficientInput1);
        assertEq(category1.decayPerSecond, decayPerSecondInput1);
        assertEq(category1.maxDepreciation, maxDepreciationInput1);
        assertEq(category1.lastCollateralizationTimestamp, PRESET_CURRENT_DATE + 4 days);
        assertEq(category1.lastCollateralizationMomentum, 142500);
        // 90% * 50000 * 75000 / 50000 + 75000 = 142500
    }

    function testAddProject() public {
        uint projectId = 5;
        uint categoryId = 3;

        assertEq(manager.isProjectCreated(projectId), false);

        manager.addCategory(categoryId, "Test token", "TT", INITIAL_CATEGORY_TA);

        _expectEmitProjectCreated(projectId);
        manager.addProject(categoryId, projectId);

        assertEq(manager.isProjectCreated(projectId), true);
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

        assertEq(manager.isBatchCreated(batchId), false);

        _expectEmitBatchCreated(batchId);
        manager.addBatch(
            DomainDataTypes.Batch({
                id: batchId,
                status: 0,
                projectId: 5,
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + 12,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
            }),
            10
        );

        assertEq(manager.isBatchCreated(batchId), true);

        DomainDataTypes.Batch memory batch = manager.getBatch(batchId);

        assertEq(batch.id, batchId);
        assertEq(batch.status, 0);
        assertEq(batch.projectId, 5);
        assertEq(batch.certificationDate, PRESET_CURRENT_DATE + 12);
        assertEq(batch.vintage, 2022);
        assertEq(batch.batchTA, 1);
        assertEq(batch.supplier, testAccount);
        assertEq(batch.isAccumulating, true);
        assertEq(manager.getBatchId(0), batchId);
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
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + 12,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
            }),
            10
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 11,
                status: 0,
                projectId: 5,
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + 24,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
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
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + 12,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
            }),
            10
        );

        assertEq(manager.forwardContractBatch().balanceOf(testAccount, 7), 10);
    }

    function testSetBatchAccumulating() public {
        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + 12,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
            }),
            10
        );

        assertEq(manager.getBatch(7).isAccumulating, true);

        manager.setBatchAccumulating(7, false);
        assertEq(manager.getBatch(7).isAccumulating, false);

        _expectRevert_InvalidBatchId(17);
        manager.setBatchAccumulating(17, false);
    }

    function testFailAddBatchWhenProjectDoesntExist() public {
        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + 12,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
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
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + 12,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
            }),
            10000
        );

        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + 12,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
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
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE + 12,
                vintage: 2022,
                batchTA: 1,
                supplier: address(0),
                isAccumulating: false
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
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
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
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE - 1,
                vintage: 2022,
                batchTA: 1,
                supplier: testAccount,
                isAccumulating: false
            }),
            10000
        );
    }

    function testAddBatch_failsForInvalidSupplier() public {
        manager.addCategory(3, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(3, 5);

        _expectRevert_InvalidBatchSupplier();
        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE - 1,
                vintage: 2022,
                batchTA: 1,
                supplier: address(0),
                isAccumulating: false
            }),
            10000
        );

        _expectRevert_InvalidBatchSupplier();
        manager.addBatch(
            DomainDataTypes.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                collateralizedCredits: 0,
                certificationDate: PRESET_CURRENT_DATE - 1,
                vintage: 2022,
                batchTA: 1,
                supplier: address(manager),
                isAccumulating: false
            }),
            10000
        );
    }

    function testSetBatchCertificationDate_failsForNonExistingBatch() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 52 weeks, 10000);

        _expectRevert_InvalidBatchId(17);
        manager.setBatchCertificationDate(17, PRESET_CURRENT_DATE + 53 weeks);
    }

    function testSetBatchCertificationDate_failsForCertificationDateLaterThanCurrent() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 52 weeks, 10000);

        _expectRevert_InvalidInput();
        manager.setBatchCertificationDate(BATCH_ID, PRESET_CURRENT_DATE + 53 weeks);
    }

    function testSetBatchCertificationDate() public {
        _addBatchWithDependencies(PRESET_CURRENT_DATE + 52 weeks, 10000);

        manager.setBatchCertificationDate(BATCH_ID, PRESET_CURRENT_DATE + 51 weeks);

        assertEq(manager.getBatch(BATCH_ID).certificationDate, PRESET_CURRENT_DATE + 51 weeks);
    }

    function _expectEmitCategoryCreated() private {
        vm.expectEmit(true, false, false, false, address(manager));
        emit CategoryCreated(CATEGORY_ID);
    }

    function _expectEmitCategoryUpdated(
        uint categoryId,
        uint volumeCoefficient,
        uint decayPerSecond,
        uint maxDepreciation
    ) private {
        vm.expectEmit(true, true, true, true, address(manager));
        emit CategoryUpdated(categoryId, volumeCoefficient, decayPerSecond, maxDepreciation);
    }

    function _expectEmitProjectCreated(uint projectId) private {
        vm.expectEmit(true, false, false, false, address(manager));
        emit ProjectCreated(projectId);
    }

    function _expectEmitBatchCreated(uint batchId) private {
        vm.expectEmit(true, false, false, false, address(manager));
        emit BatchCreated(batchId);
    }

    function _expectRevert_InvalidCategoryId(uint categoryId) private {
        vm.expectRevert(
            abi.encodeWithSelector(CarbonDomainRepository.InvalidCategoryId.selector, categoryId)
        );
    }

    function _expectRevert_InvalidBatchId(uint batchId) private {
        vm.expectRevert(abi.encodeWithSelector(CarbonDomainRepository.InvalidBatchId.selector, batchId));
    }

    function _expectRevert_InvalidInput() private {
        vm.expectRevert(abi.encodeWithSelector(CarbonDomainRepository.InvalidInput.selector));
    }

    function _expectRevert_InvalidBatchSupplier() private {
        vm.expectRevert(abi.encodeWithSelector(CarbonDomainRepository.InvalidBatchSupplier.selector));
    }
}
