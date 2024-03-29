// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./libraries/DomainDataTypes.sol";
import "./CollateralizedBasketToken.sol";
import "./ForwardContractBatchToken.sol";
import "./CollateralizedBasketTokenDeployer.sol";

/// @title SolidWorldManager contract storage layout and getters
/// @author Solid World DAO
abstract contract SolidWorldManagerStorage {
    struct Storage {
        /// @notice Mapping is used for checking if Category ID already exists
        /// @dev CategoryId => isCreated
        mapping(uint => bool) categoryCreated;
        /// @notice Property is used for checking if Project ID already exists
        /// @dev ProjectId => isCreated
        mapping(uint => bool) projectCreated;
        /// @notice Property is used for checking if Batch ID already exists
        /// @dev BatchId => isCreated
        mapping(uint => bool) batchCreated;
        /// @notice Stores the state of categories
        /// @dev CategoryId => DomainDataTypes.Category
        mapping(uint => DomainDataTypes.Category) categories;
        /// @notice Property stores info about a batch
        /// @dev BatchId => DomainDataTypes.Batch
        mapping(uint => DomainDataTypes.Batch) batches;
        /// @notice Mapping determines a respective CollateralizedBasketToken (ERC-20) of a category
        /// @dev CategoryId => CollateralizedBasketToken address (ERC-20)
        mapping(uint => CollateralizedBasketToken) categoryToken;
        /// @notice Mapping determines what projects a category has
        /// @dev CategoryId => ProjectId[]
        mapping(uint => uint[]) categoryProjects;
        /// @notice Mapping determines what category a project belongs to
        /// @dev ProjectId => CategoryId
        mapping(uint => uint) projectCategory;
        /// @notice Mapping determines what category a batch belongs to
        /// @dev BatchId => CategoryId
        mapping(uint => uint) batchCategory;
        /// @notice Mapping determines what batches a project has
        /// @dev ProjectId => BatchId[]
        mapping(uint => uint[]) projectBatches;
        /// @notice Stores all batch ids ever created
        uint[] batchIds;
        /// @notice Contract that operates forward contract batch tokens (ERC-1155). Allows this contract to mint tokens.
        ForwardContractBatchToken _forwardContractBatch;
        /// @notice Contract that deploys new collateralized basket tokens. Allows this contract to mint tokens.
        CollateralizedBasketTokenDeployer _collateralizedBasketTokenDeployer;
        /// @notice The only account that is allowed to mint weekly carbon rewards
        address weeklyRewardsMinter;
        /// @notice The account where all protocol fees are captured.
        address feeReceiver;
        /// @notice The address controlling timelocked functions (e.g. changing fees)
        address timelockController;
        /// @notice Fee charged by DAO when collateralizing forward contract batch tokens.
        uint16 collateralizationFee;
        /// @notice Fee charged by DAO when decollateralizing collateralized basket tokens.
        uint16 decollateralizationFee;
        /// @notice Fee charged by DAO when decollateralizing collateralized basket tokens to certified batches.
        /// @notice This fee incentivizes certified batches to be decollateralize faster.
        uint16 boostedDecollateralizationFee;
        /// @notice Fee charged by DAO on the weekly carbon rewards.
        uint16 rewardsFee;
    }

    Storage internal _storage;

    function isCategoryCreated(uint categoryId) external view returns (bool) {
        return _storage.categoryCreated[categoryId];
    }

    function isProjectCreated(uint projectId) external view returns (bool) {
        return _storage.projectCreated[projectId];
    }

    function isBatchCreated(uint batchId) external view returns (bool) {
        return _storage.batchCreated[batchId];
    }

    function getCategory(uint categoryId) external view returns (DomainDataTypes.Category memory) {
        return _storage.categories[categoryId];
    }

    function getBatch(uint batchId) external view returns (DomainDataTypes.Batch memory) {
        return _storage.batches[batchId];
    }

    function getCategoryToken(uint categoryId) external view returns (CollateralizedBasketToken) {
        return _storage.categoryToken[categoryId];
    }

    function getCategoryProjects(uint categoryId) external view returns (uint[] memory) {
        return _storage.categoryProjects[categoryId];
    }

    function getProjectCategory(uint projectId) external view returns (uint) {
        return _storage.projectCategory[projectId];
    }

    function getBatchCategory(uint batchId) external view returns (uint) {
        return _storage.batchCategory[batchId];
    }

    function getBatchId(uint index) external view returns (uint) {
        return _storage.batchIds[index];
    }

    function forwardContractBatch() external view returns (ForwardContractBatchToken) {
        return _storage._forwardContractBatch;
    }

    function collateralizedBasketTokenDeployer() external view returns (CollateralizedBasketTokenDeployer) {
        return _storage._collateralizedBasketTokenDeployer;
    }

    function getWeeklyRewardsMinter() external view returns (address) {
        return _storage.weeklyRewardsMinter;
    }

    function getFeeReceiver() external view returns (address) {
        return _storage.feeReceiver;
    }

    function getTimelockController() external view returns (address) {
        return _storage.timelockController;
    }

    function getCollateralizationFee() external view returns (uint16) {
        return _storage.collateralizationFee;
    }

    function getDecollateralizationFee() external view returns (uint16) {
        return _storage.decollateralizationFee;
    }

    function getBoostedDecollateralizationFee() external view returns (uint16) {
        return _storage.boostedDecollateralizationFee;
    }

    function getRewardsFee() external view returns (uint16) {
        return _storage.rewardsFee;
    }

    function getProjectIdsByCategory(uint categoryId) external view returns (uint[] memory) {
        return _storage.categoryProjects[categoryId];
    }

    function getBatchIdsByProject(uint projectId) external view returns (uint[] memory) {
        return _storage.projectBatches[projectId];
    }
}
