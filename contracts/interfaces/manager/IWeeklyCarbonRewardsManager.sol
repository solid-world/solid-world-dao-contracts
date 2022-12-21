// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title The interface for weekly carbon rewards processing
/// @notice Computes and mints weekly carbon rewards
/// @author Solid World DAO
interface IWeeklyCarbonRewardsManager {
    event WeeklyRewardMinted(address indexed rewardToken, uint indexed rewardAmount);
    event RewardsFeeUpdated(uint indexed rewardsFee);
    event RewardsMinterUpdated(address indexed rewardsMinter);

    /// @dev Thrown if minting weekly rewards is called by an unauthorized account
    error UnauthorizedRewardMinting(address account);

    /// @param _weeklyRewardsMinter The only account allowed to mint weekly carbon rewards
    function setWeeklyRewardsMinter(address _weeklyRewardsMinter) external;

    function weeklyRewardsMinter() external view returns (address);

    /// @param _rewardsFee The new rewards fee charged on weekly rewards
    function setRewardsFee(uint16 _rewardsFee) external;

    function rewardsFee() external view returns (uint16);

    /// @param assets The incentivized assets (LP tokens)
    /// @param _categoryIds The categories to which the incentivized assets belong
    /// @return carbonRewards List of carbon rewards getting distributed.
    /// @return rewardAmounts List of carbon reward amounts getting distributed
    function computeWeeklyCarbonRewards(address[] calldata assets, uint[] calldata _categoryIds)
        external
        view
        returns (address[] memory carbonRewards, uint[] memory rewardAmounts);

    /// @param _categoryIds The categories to which the incentivized assets belong
    /// @param carbonRewards List of carbon rewards to mint
    /// @param rewardAmounts List of carbon reward amounts to mint
    /// @param rewardsVault Account that secures ERC20 rewards
    function mintWeeklyCarbonRewards(
        uint[] calldata _categoryIds,
        address[] calldata carbonRewards,
        uint[] calldata rewardAmounts,
        address rewardsVault
    ) external;
}
