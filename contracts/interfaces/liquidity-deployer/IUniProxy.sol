// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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
}
