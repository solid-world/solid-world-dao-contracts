// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Permissionless staking actions
 * @notice Contains staking methods that can be called by anyone
 * @author Solid World DAO
 */
interface ISolidStakingActions {
    /**
     * @dev Stakes tokens for the caller into the staking contract
     * @param token the token to stake
     * @param amount the amount to stake
     */
    function stake(address token, uint amount) external;

    /**
     * @dev Withdraws tokens for the caller from the staking contract
     * @param token the token to withdraw
     * @param amount the amount to withdraw
     */
    function withdraw(address token, uint amount) external;

    /**
     * @dev Computes the amount of tokens that the `account` has staked
     * @param account the account to check
     * @param token the token to check
     * @return the amount of `token` tokens that the `account` has staked
     */
    function balanceOf(address token, address account) external view returns (uint);

    /**
     * @dev Returns the list of tokens that can be staked
     * @return the list of tokens that can be staked
     */
    function getTokens() external view returns (address[] memory);
}
