// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

/// @title The interface for weekly carbon rewards processing
/// @notice Computes and mints weekly carbon rewards
/// @author Solid World DAO
interface IWeeklyCarbonRewardsManager {
    /// @param weeklyRewardsMinter The only account allowed to mint weekly carbon rewards
    function setWeeklyRewardsMinter(address weeklyRewardsMinter) external;

    /// @param rewardsFee The new rewards fee charged on weekly rewards
    function setRewardsFee(uint16 rewardsFee) external;

    /// @param categoryIds The categories to which the incentivized assets belong
    /// @return carbonRewards List of carbon rewards getting distributed.
    /// @return rewardAmounts List of carbon reward amounts getting distributed
    /// @return rewardFees List of fee amounts charged by the DAO on carbon rewards
    function computeWeeklyCarbonRewards(uint[] calldata categoryIds)
        external
        view
        returns (
            address[] memory carbonRewards,
            uint[] memory rewardAmounts,
            uint[] memory rewardFees
        );

    /// @param categoryIds The categories to which the incentivized assets belong
    /// @param carbonRewards List of carbon rewards to mint
    /// @param rewardAmounts List of carbon reward amounts to mint
    /// @param rewardFees List of fee amounts charged by the DAO on carbon rewards
    /// @param rewardsVault Account that secures ERC20 rewards
    function mintWeeklyCarbonRewards(
        uint[] calldata categoryIds,
        address[] calldata carbonRewards,
        uint[] calldata rewardAmounts,
        uint[] calldata rewardFees,
        address rewardsVault
    ) external;
}
