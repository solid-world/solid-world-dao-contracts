// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Events emitted by the staking contract
/// @notice Contains all events emitted by the staking contract
/// @author Solid World DAO
interface ISolidStakingEvents {
    /// @dev Emitted when an account stakes tokens
    /// @param account the account that staked tokens
    /// @param token the token that was staked
    /// @param amount the amount of tokens that were staked
    event Stake(address indexed account, address indexed token, uint indexed amount);

    /// @dev Emitted when an account un-stakes tokens
    /// @param account the account that withdrew tokens
    /// @param token the token that was withdrawn
    /// @param amount the amount of tokens that were withdrawn
    event Withdraw(address indexed account, address indexed token, uint indexed amount);

    /// @dev Emitted when a new token is added to the staking contract
    /// @param token the token that was added
    event TokenAdded(address indexed token);
}
