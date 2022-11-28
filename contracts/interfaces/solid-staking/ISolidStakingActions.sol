// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Permissionless state-mutating actions
/// @notice Contains state-mutating functions that can be called by anyone
/// @author Solid World DAO
interface ISolidStakingActions {
    /// @dev Stakes tokens for the caller into the staking contract
    /// @param token the token to stake
    /// @param amount the amount to stake
    function stake(address token, uint amount) external;

    /// @dev Withdraws tokens for the caller from the staking contract
    /// @param token the token to withdraw
    /// @param amount the amount to withdraw
    function withdraw(address token, uint amount) external;
}
