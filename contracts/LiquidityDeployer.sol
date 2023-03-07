// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/liquidity-deployer/ILiquidityDeployer.sol";
import "./libraries/liquidity-deployer/LiquidityDeployerDataTypes.sol";

/// @author Solid World
contract LiquidityDeployer is ILiquidityDeployer, ReentrancyGuard {
    LiquidityDeployerDataTypes.Config internal config;
    LiquidityDeployerDataTypes.TotalDeposits internal totalDeposits;

    /// @dev Account => token0 balance
    mapping(address => uint) internal token0Balance;
    /// @dev Account => token1 balance
    mapping(address => uint) internal token1Balance;

    modifier validDepositAmount(uint amount) {
        if (amount == 0) {
            revert InvalidInput();
        }
        _;
    }

    constructor(
        address token0,
        address token1,
        address gammaVault,
        address uniProxy,
        uint conversionRate,
        uint8 conversionRateDecimals
    ) {
        config.token0 = IERC20(token0);
        config.token1 = IERC20(token1);
        config.gammaVault = gammaVault;
        config.uniProxy = IUniProxy(uniProxy);
        config.conversionRate = conversionRate;
        config.conversionRateDecimals = conversionRateDecimals;
    }

    function depositToken0(uint amount) external nonReentrant validDepositAmount(amount) {
        token0Balance[msg.sender] += amount;
        totalDeposits.token0Amount += amount;
    }

    function depositToken1(uint amount) external nonReentrant validDepositAmount(amount) {
        token1Balance[msg.sender] += amount;
        totalDeposits.token1Amount += amount;
    }

    function getToken0() external view returns (address) {
        return address(config.token0);
    }

    function getToken1() external view returns (address) {
        return address(config.token1);
    }

    /// @inheritdoc ILiquidityDeployer
    function getGammaVault() external view returns (address) {
        return config.gammaVault;
    }

    /// @inheritdoc ILiquidityDeployer
    function getUniProxy() external view returns (address) {
        return address(config.uniProxy);
    }

    /// @inheritdoc ILiquidityDeployer
    function getConversionRate() external view returns (uint) {
        return config.conversionRate;
    }

    /// @inheritdoc ILiquidityDeployer
    function getConversionRateDecimals() external view returns (uint8) {
        return config.conversionRateDecimals;
    }

    function token0BalanceOf(address account) external view returns (uint) {
        return token0Balance[account];
    }

    function token1BalanceOf(address account) external view returns (uint) {
        return token1Balance[account];
    }

    function getTotalDeposits() external view returns (uint token0Amount, uint token1Amount) {
        token0Amount = totalDeposits.token0Amount;
        token1Amount = totalDeposits.token1Amount;
    }
}
