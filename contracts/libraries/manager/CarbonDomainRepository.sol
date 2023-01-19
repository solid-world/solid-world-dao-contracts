// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../DomainDataTypes.sol";
import "../ReactiveTimeAppreciationMath.sol";
import "../../SolidWorldManagerStorage.sol";

/// @notice Handles all CRUD operations for categories, projects, batches
/// @author Solid World DAO
library CarbonDomainRepository {
    event CategoryCreated(uint indexed categoryId);
    event CategoryUpdated(
        uint indexed categoryId,
        uint indexed volumeCoefficient,
        uint indexed decayPerSecond,
        uint maxDepreciation
    );
    event ProjectCreated(uint indexed projectId);
    event BatchCreated(uint indexed batchId);

    error CategoryAlreadyExists(uint categoryId);
    error InvalidCategoryId(uint categoryId);
    error ProjectAlreadyExists(uint projectId);
    error InvalidProjectId(uint projectId);
    error InvalidBatchId(uint batchId);
    error BatchAlreadyExists(uint batchId);
    error InvalidBatchSupplier();
    error BatchCertificationDateInThePast(uint32 dueDate);
    error InvalidInput();

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param categoryId The category ID
    /// @param tokenName The name of the ERC20 token that will be created for the category
    /// @param tokenSymbol The symbol of the ERC20 token that will be created for the category
    /// @param initialTA The initial time appreciation for the category. Category's averageTA will be set to this value.
    function addCategory(
        SolidWorldManagerStorage.Storage storage _storage,
        uint categoryId,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint24 initialTA
    ) external {
        if (_storage.categoryCreated[categoryId]) {
            revert CategoryAlreadyExists(categoryId);
        }

        _storage.categoryCreated[categoryId] = true;
        _storage.categoryToken[categoryId] = _storage._collateralizedBasketTokenDeployer.deploy(
            tokenName,
            tokenSymbol
        );

        _storage.categories[categoryId].averageTA = initialTA;

        emit CategoryCreated(categoryId);
    }

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param categoryId The category ID to be updated
    /// @param volumeCoefficient The new volume coefficient for the category
    /// @param decayPerSecond The new decay per second for the category
    /// @param maxDepreciation The new max depreciation for the category. Quantified per year.
    function updateCategory(
        SolidWorldManagerStorage.Storage storage _storage,
        uint categoryId,
        uint volumeCoefficient,
        uint40 decayPerSecond,
        uint16 maxDepreciation
    ) external {
        if (!_storage.categoryCreated[categoryId]) {
            revert InvalidCategoryId(categoryId);
        }

        if (volumeCoefficient == 0 || decayPerSecond == 0) {
            revert InvalidInput();
        }

        DomainDataTypes.Category storage category = _storage.categories[categoryId];
        category.lastCollateralizationMomentum = ReactiveTimeAppreciationMath.inferMomentum(
            category,
            volumeCoefficient,
            maxDepreciation
        );
        category.volumeCoefficient = volumeCoefficient;
        category.decayPerSecond = decayPerSecond;
        category.maxDepreciation = maxDepreciation;
        category.lastCollateralizationTimestamp = uint32(block.timestamp);

        emit CategoryUpdated(categoryId, volumeCoefficient, decayPerSecond, maxDepreciation);
    }

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param categoryId The category ID to which the project belongs
    /// @param projectId The project ID
    function addProject(
        SolidWorldManagerStorage.Storage storage _storage,
        uint categoryId,
        uint projectId
    ) external {
        if (!_storage.categoryCreated[categoryId]) {
            revert InvalidCategoryId(categoryId);
        }

        if (_storage.projectCreated[projectId]) {
            revert ProjectAlreadyExists(projectId);
        }

        _storage.categoryProjects[categoryId].push(projectId);
        _storage.projectCategory[projectId] = categoryId;
        _storage.projectCreated[projectId] = true;

        emit ProjectCreated(projectId);
    }

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param batch Struct containing all the data for the batch
    /// @param mintableAmount The amount of ERC1155 tokens to be minted to the batch supplier
    function addBatch(
        SolidWorldManagerStorage.Storage storage _storage,
        DomainDataTypes.Batch calldata batch,
        uint mintableAmount
    ) external {
        if (!_storage.projectCreated[batch.projectId]) {
            revert InvalidProjectId(batch.projectId);
        }

        if (_storage.batchCreated[batch.id]) {
            revert BatchAlreadyExists(batch.id);
        }

        if (batch.supplier == address(0)) {
            revert InvalidBatchSupplier();
        }

        if (batch.certificationDate <= block.timestamp) {
            revert BatchCertificationDateInThePast(batch.certificationDate);
        }

        _storage.batchCreated[batch.id] = true;
        _storage.batches[batch.id] = batch;
        _storage.batches[batch.id].isAccumulating = true;
        _storage.batchIds.push(batch.id);
        _storage.projectBatches[batch.projectId].push(batch.id);
        _storage.batchCategory[batch.id] = _storage.projectCategory[batch.projectId];
        _storage._forwardContractBatch.mint(batch.supplier, batch.id, mintableAmount, "");

        emit BatchCreated(batch.id);
    }

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param batchId The batch ID
    /// @param isAccumulating The new isAccumulating value for the batch
    function setBatchAccumulating(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        bool isAccumulating
    ) external {
        if (!_storage.batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }

        _storage.batches[batchId].isAccumulating = isAccumulating;
    }
}
