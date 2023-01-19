// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../../SolidWorldManagerStorage.sol";
import "../SolidMath.sol";

/// @notice Computes and mints weekly carbon rewards
/// @author Solid World DAO
library WeeklyCarbonRewards {
    event WeeklyRewardMinted(address indexed rewardToken, uint indexed rewardAmount);
    event RewardsFeeUpdated(uint indexed rewardsFee);
    event RewardsMinterUpdated(address indexed rewardsMinter);
    event CategoryRebalanced(
        uint indexed categoryId,
        uint indexed averageTA,
        uint indexed totalCollateralized
    );

    /// @dev Thrown if minting weekly rewards is called by an unauthorized account
    error UnauthorizedRewardMinting(address account);
    error InvalidCategoryId(uint categoryId);
    error InvalidInput();

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param _weeklyRewardsMinter The only account allowed to mint weekly carbon rewards
    function setWeeklyRewardsMinter(
        SolidWorldManagerStorage.Storage storage _storage,
        address _weeklyRewardsMinter
    ) external {
        _storage.weeklyRewardsMinter = _weeklyRewardsMinter;

        emit RewardsMinterUpdated(_weeklyRewardsMinter);
    }

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param _rewardsFee The new rewards fee charged on weekly rewards
    function setRewardsFee(SolidWorldManagerStorage.Storage storage _storage, uint16 _rewardsFee)
        external
    {
        _storage.rewardsFee = _rewardsFee;

        emit RewardsFeeUpdated(_rewardsFee);
    }

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param categoryIds The categories to which the incentivized assets belong
    /// @return carbonRewards List of carbon rewards getting distributed.
    /// @return rewardAmounts List of carbon reward amounts getting distributed
    /// @return rewardFeeAmounts List of fee amounts charged by the DAO on carbon rewards
    function computeWeeklyCarbonRewards(
        SolidWorldManagerStorage.Storage storage _storage,
        uint[] calldata categoryIds
    )
        external
        view
        returns (
            address[] memory carbonRewards,
            uint[] memory rewardAmounts,
            uint[] memory rewardFeeAmounts
        )
    {
        carbonRewards = new address[](categoryIds.length);
        rewardAmounts = new uint[](categoryIds.length);
        rewardFeeAmounts = new uint[](categoryIds.length);

        uint rewardsFee = _storage.rewardsFee;
        for (uint i; i < categoryIds.length; i++) {
            uint categoryId = categoryIds[i];
            if (!_storage.categoryCreated[categoryId]) {
                revert InvalidCategoryId(categoryId);
            }

            CollateralizedBasketToken rewardToken = _storage.categoryToken[categoryId];
            (uint rewardAmount, uint rewardFeeAmount) = _computeWeeklyCategoryReward(
                _storage,
                categoryId,
                rewardsFee,
                rewardToken.decimals()
            );

            carbonRewards[i] = address(rewardToken);
            rewardAmounts[i] = rewardAmount;
            rewardFeeAmounts[i] = rewardFeeAmount;
        }
    }

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param categoryIds The categories to which the incentivized assets belong
    /// @param carbonRewards List of carbon rewards to mint
    /// @param rewardAmounts List of carbon reward amounts to mint
    /// @param rewardFees List of fee amounts charged by the DAO on carbon rewards
    /// @param rewardsVault Account that secures ERC20 rewards
    function mintWeeklyCarbonRewards(
        SolidWorldManagerStorage.Storage storage _storage,
        uint[] calldata categoryIds,
        address[] calldata carbonRewards,
        uint[] calldata rewardAmounts,
        uint[] calldata rewardFees,
        address rewardsVault
    ) external {
        if (
            categoryIds.length != carbonRewards.length ||
            carbonRewards.length != rewardAmounts.length ||
            rewardAmounts.length != rewardFees.length
        ) {
            revert InvalidInput();
        }

        if (msg.sender != _storage.weeklyRewardsMinter) {
            revert UnauthorizedRewardMinting(msg.sender);
        }

        for (uint i; i < carbonRewards.length; i++) {
            address carbonReward = carbonRewards[i];
            CollateralizedBasketToken rewardToken = CollateralizedBasketToken(carbonReward);
            uint rewardAmount = rewardAmounts[i];
            rewardToken.mint(rewardsVault, rewardAmount);
            emit WeeklyRewardMinted(carbonReward, rewardAmount);

            rewardToken.mint(_storage.feeReceiver, rewardFees[i]);

            _rebalanceCategory(_storage, categoryIds[i]);
        }
    }

    function _rebalanceCategory(SolidWorldManagerStorage.Storage storage _storage, uint categoryId)
        internal
    {
        uint totalQuantifiedForwardCredits;
        uint totalCollateralizedForwardCredits;

        uint[] storage projects = _storage.categoryProjects[categoryId];
        for (uint i; i < projects.length; i++) {
            uint projectId = projects[i];
            uint[] storage _batches = _storage.projectBatches[projectId];
            for (uint j; j < _batches.length; j++) {
                uint batchId = _batches[j];
                uint collateralizedForwardCredits = _storage._forwardContractBatch.balanceOf(
                    address(this),
                    batchId
                );
                if (
                    collateralizedForwardCredits == 0 ||
                    _isBatchCertified(_storage, batchId) ||
                    !_storage.batches[batchId].isAccumulating
                ) {
                    continue;
                }

                totalQuantifiedForwardCredits +=
                    _storage.batches[batchId].batchTA *
                    collateralizedForwardCredits;
                totalCollateralizedForwardCredits += collateralizedForwardCredits;
            }
        }

        if (totalCollateralizedForwardCredits == 0) {
            _storage.categories[categoryId].totalCollateralized = 0;
            emit CategoryRebalanced(categoryId, _storage.categories[categoryId].averageTA, 0);
            return;
        }

        uint latestAverageTA = totalQuantifiedForwardCredits / totalCollateralizedForwardCredits;
        _storage.categories[categoryId].averageTA = uint24(latestAverageTA);
        _storage.categories[categoryId].totalCollateralized = totalCollateralizedForwardCredits;

        emit CategoryRebalanced(categoryId, latestAverageTA, totalCollateralizedForwardCredits);
    }

    /// @dev Computes the amount of ERC20 tokens to be rewarded over the next 7 days
    /// @param _storage Struct containing the current state used or modified by this function
    /// @param categoryId The source category for the ERC20 rewards
    /// @param rewardsFee The fee charged by the DAO on ERC20 rewards
    /// @param rewardDecimals The number of decimals of the ERC20 reward
    /// @return rewardAmount carbon reward amount to mint
    /// @return rewardFeeAmount fee amount charged by the DAO
    function _computeWeeklyCategoryReward(
        SolidWorldManagerStorage.Storage storage _storage,
        uint categoryId,
        uint rewardsFee,
        uint rewardDecimals
    ) internal view returns (uint rewardAmount, uint rewardFeeAmount) {
        uint[] storage projects = _storage.categoryProjects[categoryId];
        for (uint i; i < projects.length; i++) {
            uint[] storage batches = _storage.projectBatches[projects[i]];
            for (uint j; j < batches.length; ) {
                uint batchId = batches[j];
                (uint netRewardAmount, uint feeAmount) = _computeWeeklyBatchReward(
                    _storage,
                    batchId,
                    _storage._forwardContractBatch.balanceOf(address(this), batchId),
                    rewardsFee,
                    rewardDecimals
                );
                rewardAmount += netRewardAmount;
                rewardFeeAmount += feeAmount;
                unchecked {
                    j++;
                }
            }
        }
    }

    function _computeWeeklyBatchReward(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint availableCredits,
        uint rewardsFee,
        uint rewardDecimals
    ) internal view returns (uint netRewardAmount, uint feeAmount) {
        if (
            availableCredits == 0 ||
            _isBatchCertified(_storage, batchId) ||
            !_storage.batches[batchId].isAccumulating
        ) {
            return (0, 0);
        }

        (netRewardAmount, feeAmount) = SolidMath.computeWeeklyBatchReward(
            _storage.batches[batchId].certificationDate,
            availableCredits,
            _storage.batches[batchId].batchTA,
            rewardsFee,
            rewardDecimals
        );
    }

    function _isBatchCertified(SolidWorldManagerStorage.Storage storage _storage, uint batchId)
        internal
        view
        returns (bool)
    {
        return _storage.batches[batchId].certificationDate <= block.timestamp;
    }
}
