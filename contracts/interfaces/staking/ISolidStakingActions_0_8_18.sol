// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @title Permissionless state-mutating actions
/// @notice Contains state-mutating functions that can be called by anyone
/// @author Solid World DAO
interface ISolidStakingActions {
    /// @dev Stakes tokens for the caller into the staking contract
    /// @param token the token to stake
    /// @param amount the amount to stake
    function stake(address token, uint amount) external;

    /// @notice msg.sender stakes tokens for the recipient into the staking contract
    /// @dev funds are subtracted from msg.sender, stake is credited to recipient
    /// @param token the token to stake
    /// @param amount the amount to stake
    /// @param recipient the recipient of the stake
    function stake(
        address token,
        uint amount,
        address recipient
    ) external;

    /// @dev Withdraws tokens for the caller from the staking contract
    /// @param token the token to withdraw
    /// @param amount the amount to withdraw
    function withdraw(address token, uint amount) external;

    /// @dev Withdraws tokens for the caller from the staking contract
    /// @dev Claims all rewards of the incentivized `token` for the caller
    /// @param token the token to withdraw
    /// @param amount the amount to withdraw
    function withdrawStakeAndClaimRewards(address token, uint amount) external;
}
