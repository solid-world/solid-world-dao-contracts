// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @author Gamma Strategies
interface IUniProxy {
    /// @notice Deposit into the given position
    /// @param deposit0 Amount of token0 to deposit
    /// @param deposit1 Amount of token1 to deposit
    /// @param to Address to receive liquidity tokens
    /// @param pos Hypervisor Address
    /// @param minIn Minimum amount of tokens that should be paid
    /// @return shares Amount of liquidity tokens received
    function deposit(
        uint deposit0,
        uint deposit1,
        address to,
        address pos,
        uint[4] memory minIn
    ) external returns (uint shares);

    /// @notice Get the amount of token to deposit for the given amount of pair token
    /// @param pos Hypervisor Address
    /// @param token Address of token to deposit
    /// @param depositAmount Amount of token to deposit
    /// @return amountStart Minimum amounts of the pair token to deposit
    /// @return amountEnd Maximum amounts of the pair token to deposit
    function getDepositAmount(
        address pos,
        address token,
        uint depositAmount
    ) external view returns (uint amountStart, uint amountEnd);
}
