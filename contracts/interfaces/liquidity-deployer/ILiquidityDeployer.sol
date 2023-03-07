// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World
interface ILiquidityDeployer {
    error InvalidInput();

    function depositToken0(uint amount) external;

    function depositToken1(uint amount) external;

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

    function token0BalanceOf(address account) external view returns (uint);

    function token1BalanceOf(address account) external view returns (uint);

    function getTotalDeposits() external view returns (uint token0Amount, uint token1Amount);

    function getToken0Depositors() external view returns (address[] memory);

    function getToken1Depositors() external view returns (address[] memory);
}
