// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Permissionless view actions
 * @notice Contains view functions that can be called by anyone
 * @author Solid World DAO
 */
interface ISolidStakingViewActions {
    /**
     * @dev Computes the amount of tokens that the `account` has staked
     * @param token the token to check
     * @param account the account to check
     * @return the amount of `token` tokens that the `account` has staked
     */
    function balanceOf(address token, address account) external view returns (uint);

    /**
     * @dev Computes the total amount of tokens that have been staked
     * @param token the token to check
     * @return the total amount of `token` tokens that have been staked
     */
    function totalStaked(address token) external view returns (uint);

    /**
     * @dev Returns the list of tokens that can be staked
     * @return the list of tokens that can be staked
     */
    function getTokens() external view returns (address[] memory);
}
