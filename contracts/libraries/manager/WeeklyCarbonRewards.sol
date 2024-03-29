// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./CategoryRebalancer.sol";
import "../SolidMath.sol";
import "../../SolidWorldManagerStorage.sol";

/// @notice Computes and mints weekly carbon rewards
/// @author Solid World DAO
library WeeklyCarbonRewards {
    using CategoryRebalancer for SolidWorldManagerStorage.Storage;

    event WeeklyRewardMinted(address indexed rewardToken, uint indexed rewardAmount);
    event RewardsFeeUpdated(uint indexed rewardsFee);
    event RewardsMinterUpdated(address indexed rewardsMinter);

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
    function setRewardsFee(SolidWorldManagerStorage.Storage storage _storage, uint16 _rewardsFee) external {
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

            _storage.rebalanceCategory(categoryIds[i]);
        }
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
            uint[] storage batchIds = _storage.projectBatches[projects[i]];
            (uint batchesRewardAmount, uint batchesRewardFeeAmount) = _computeWeeklyBatchesReward(
                _storage,
                batchIds,
                rewardsFee,
                rewardDecimals
            );

            rewardAmount += batchesRewardAmount;
            rewardFeeAmount += batchesRewardFeeAmount;
        }
    }

    function _computeWeeklyBatchesReward(
        SolidWorldManagerStorage.Storage storage _storage,
        uint[] storage batchIds,
        uint rewardsFee,
        uint rewardDecimals
    ) internal view returns (uint rewardAmount, uint rewardFeeAmount) {
        uint numOfBatches = batchIds.length;
        for (uint i; i < numOfBatches; ) {
            uint batchId = batchIds[i];
            (uint netRewardAmount, uint feeAmount) = _computeWeeklyBatchReward(
                _storage,
                batchId,
                _storage.batches[batchId].collateralizedCredits,
                rewardsFee,
                rewardDecimals
            );
            rewardAmount += netRewardAmount;
            rewardFeeAmount += feeAmount;
            unchecked {
                i++;
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
        private
        view
        returns (bool)
    {
        return _storage.batches[batchId].certificationDate <= block.timestamp;
    }
}
