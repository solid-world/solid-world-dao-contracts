// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Permissionless view actions
/// @notice Contains view functions that can be called by anyone
/// @author Solid World DAO
interface ISolidStakingViewActions {
    /// @dev Computes the amount of tokens that the `account` has staked
    /// @param token the token to check
    /// @param account the account to check
    /// @return the amount of `token` tokens that the `account` has staked
    function balanceOf(address token, address account) external view returns (uint);

    /// @dev Computes the total amount of tokens that have been staked
    /// @param token the token to check
    /// @return the total amount of `token` tokens that have been staked
    function totalStaked(address token) external view returns (uint);

    /// @dev Returns the list of tokens that can be staked
    /// @return the list of tokens that can be staked
    function getTokens() external view returns (address[] memory);

    /// @return whether the specified token requires msg.sender to be KYCed before staking
    function isKYCRequired(address token) external view returns (bool);

    /// @return The address controlling timelocked functions (e.g. KYC requirement changes)
    function getTimelockController() external view returns (address);
}
