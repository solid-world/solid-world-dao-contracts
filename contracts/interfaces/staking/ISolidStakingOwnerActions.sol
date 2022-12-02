// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Permissioned staking actions
/// @notice Contains staking methods may only be called by the owner
/// @author Solid World DAO
interface ISolidStakingOwnerActions {
    /// @dev Adds a new token to the staking contract
    /// @param token the token to add
    function addToken(address token) external;
}