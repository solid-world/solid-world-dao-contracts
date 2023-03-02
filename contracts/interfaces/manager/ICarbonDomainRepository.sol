// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../libraries/DomainDataTypes.sol";

/// @notice Handles all CRUD operations for categories, projects, batches
/// @author Solid World DAO
interface ICarbonDomainRepository {
    event CategoryCreated(uint indexed categoryId);
    event CategoryUpdated(
        uint indexed categoryId,
        uint indexed volumeCoefficient,
        uint indexed decayPerSecond,
        uint maxDepreciation
    );
    event ProjectCreated(uint indexed projectId);
    event BatchCreated(uint indexed batchId);

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
    /// @param maxDepreciation The new max depreciation for the category. Quantified per year.
    function updateCategory(
        uint categoryId,
        uint volumeCoefficient,
        uint40 decayPerSecond,
        uint16 maxDepreciation
    ) external;

    /// @param categoryId The category ID to which the project belongs
    /// @param projectId The project ID
    function addProject(uint categoryId, uint projectId) external;

    /// @param batch Struct containing all the data for the batch
    /// @param mintableAmount The amount of ERC1155 tokens to be minted to the batch supplier
    function addBatch(DomainDataTypes.Batch calldata batch, uint mintableAmount) external;

    /// @param batchId The batch ID
    /// @param isAccumulating The new isAccumulating value for the batch
    function setBatchAccumulating(uint batchId, bool isAccumulating) external;

    /// @notice The certification date can only be set sooner than the current certification date
    /// @param batchId The batch ID to be updated
    /// @param certificationDate The new certification date for the batch
    function setBatchCertificationDate(uint batchId, uint32 certificationDate) external;
}
