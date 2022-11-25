// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title The interface weekly carbon rewards processing
/// @notice Computes and mints weekly carbon rewards
/// @author Solid World DAO
interface IWeeklyCarbonRewardsManager {
    event WeeklyRewardMinted(address rewardToken, uint rewardAmount);
    event WeeklyRewardRecalculationSkipped(address rewardToken);

    /// @param assets The incentivized assets (LP tokens)
    /// @param _categoryIds The categories to which the incentivized assets belong
    /// @param rewardsVault Account that secures ERC20 rewards
    /// @return carbonRewards List of carbon rewards getting distributed. 0x0 values where no new rewards are distributed
    /// @return rewardAmounts List of carbon reward amounts getting distributed
    function computeAndMintWeeklyCarbonRewards(
        address[] calldata assets,
        uint[] calldata _categoryIds,
        address rewardsVault
    ) external returns (address[] memory carbonRewards, uint[] memory rewardAmounts);
}
