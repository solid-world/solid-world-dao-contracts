// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World
interface ILiquidityDeployer {
    error InvalidInput();
    error InsufficientTokenBalance(address token, address account, uint balance, uint withdrawAmount);
    error NotEnoughAvailableLiquidity(uint token0Liquidity, uint token1Liquidity);
    error InsufficientLpTokenBalance(address account, uint balance, uint withdrawAmount);

    event TokenDeposited(address indexed token, address indexed depositor, uint indexed amount);
    event TokenWithdrawn(address indexed token, address indexed withdrawer, uint indexed amount);
    event LpTokenWithdrawn(address indexed withdrawer, uint indexed amount);

    /// @notice The caller must approve the contract to spend `amount` of token0
    function depositToken0(uint amount) external;

    /// @notice The caller must approve the contract to spend `amount` of token1
    function depositToken1(uint amount) external;

    function withdrawToken0(uint amount) external;

    function withdrawToken1(uint amount) external;

    /// @notice Looks at the current configuration and state of the contract, deploys
    /// the available liquidity to the Gamma Vault, and distributes the LP tokens to
    /// the depositors proportionally
    function deployLiquidity() external;

    function withdrawLpTokens(uint amount) external;

    function withdrawLpTokens() external;

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

    /// @dev Returns the minimum amount of token0 that can be converted to token1
    function getMinConvertibleToken0Amount() external view returns (uint);

    function token0BalanceOf(address account) external view returns (uint);

    function token1BalanceOf(address account) external view returns (uint);

    function getTotalDeposits() external view returns (uint token0Amount, uint token1Amount);

    function getTokenDepositors() external view returns (address[] memory);

    /// @dev returns the total amount of token0 that was available to be deployed (excludes deposits not convertible to token1)
    function getLastToken0AvailableLiquidity() external view returns (uint);

    /// @dev returns the total amount of token1 that was available to be deployed
    function getLastToken1AvailableLiquidity() external view returns (uint);

    /// @param liquidityProvider account that contributed liquidity
    /// @return lastDeployedAmount amount of token0 liquidity that was
    /// deployed by the liquidity provider during the last deployment
    function getLastToken0LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount);

    /// @param liquidityProvider account that contributed liquidity
    /// @return lastDeployedAmount amount of token1 liquidity that was
    /// last deployed by the liquidity provider during the last deployment
    function getLastToken1LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount);

    function getLastTotalDeployedLiquidity() external view returns (uint, uint);

    function getLPTokensOwed(address liquidityProvider) external view returns (uint);
}
