// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../../libraries/DomainDataTypes.sol";

/// @notice Handles all CRUD operations for categories, projects, batches
/// @author Solid World DAO
interface ICarbonDomainRepository {
    /// @param categoryId The category ID
    /// @param tokenName The name of the ERC20 token that will be created for the category
    /// @param tokenSymbol The symbol of the ERC20 token that will be created for the category
    /// @param initialTA The initial time appreciation for the category. Category's averageTA will be set to this value.
    function addCategory(
        uint categoryId,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint24 initialTA
    ) external;

    /// @param categoryId The category ID to be updated
    /// @param volumeCoefficient The new volume coefficient for the category
    /// @param decayPerSecond The new decay per second for the category
    /// @param maxDepreciationPerYear The new max depreciation per year for the category
    /// @param maxDepreciation The new max depreciation per week for the category
    function updateCategory(
        uint categoryId,
        uint volumeCoefficient,
        uint40 decayPerSecond,
        uint16 maxDepreciationPerYear,
        uint24 maxDepreciation
    ) external;

    /// @param categoryId The category ID to which the project belongs
    /// @param projectId The project ID
    function addProject(uint categoryId, uint projectId) external;

    /// @param batch Struct containing all the data for the batch
    /// @param mintableAmount The amount of ERC1155 tokens to be minted to the batch supplier
    function addBatch(DomainDataTypes.Batch calldata batch, uint mintableAmount) external;
}