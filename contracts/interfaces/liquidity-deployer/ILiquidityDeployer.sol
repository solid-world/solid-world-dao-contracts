// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World
interface ILiquidityDeployer {
    function getToken0() external view returns (address);

    function getToken1() external view returns (address);

    /// @return Gamma Vault address the UniProxy contract will deposit tokens to
    function getGammaVault() external view returns (address);

    /// @return UniProxy contract takes amounts of token0 and token1, deposits them to Gamma Vault,
    /// and returns LP tokens
    function getUniProxy() external view returns (address);

    /// @return 1 token0 = ? token1
    function getConversionRate() external view returns (uint);

    /// @return Number of decimals of the conversion rate
    /// e.g. to express 1 token0 = 0.000001 token1, conversion rate is 1 and decimals is 6
    function getConversionRateDecimals() external view returns (uint8);
}
