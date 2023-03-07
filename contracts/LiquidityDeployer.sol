// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/liquidity-deployer/ILiquidityDeployer.sol";
import "./interfaces/liquidity-deployer/IUniProxy.sol";
import "./libraries/liquidity-deployer/LiquidityDeployerDataTypes.sol";

/// @author Solid World
contract LiquidityDeployer is ILiquidityDeployer, ReentrancyGuard {
    IERC20 internal immutable token0;
    IERC20 internal immutable token1;
    address internal immutable gammaVault;
    IUniProxy internal immutable uniProxy;
    uint internal immutable conversionRate;
    uint8 internal immutable conversionRateDecimals;

    /// @dev Account => token0 balance
    mapping(address => uint) internal token0Balance;

    /// @dev Account => token1 balance
    mapping(address => uint) internal token1Balance;

    LiquidityDeployerDataTypes.TotalDeposits internal totalDeposits;

    modifier validDepositAmount(uint amount) {
        if (amount == 0) {
            revert InvalidInput();
        }
        _;
    }

    constructor(
        address _token0,
        address _token1,
        address _gammaVault,
        address _uniProxy,
        uint _conversionRate,
        uint8 _conversionRateDecimals
    ) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        gammaVault = _gammaVault;
        uniProxy = IUniProxy(_uniProxy);
        conversionRate = _conversionRate;
        conversionRateDecimals = _conversionRateDecimals;
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
        return address(token0);
    }

    function getToken1() external view returns (address) {
        return address(token1);
    }

    /// @inheritdoc ILiquidityDeployer
    function getGammaVault() external view returns (address) {
        return gammaVault;
    }

    /// @inheritdoc ILiquidityDeployer
    function getUniProxy() external view returns (address) {
        return address(uniProxy);
    }

    /// @inheritdoc ILiquidityDeployer
    function getConversionRate() external view returns (uint) {
        return conversionRate;
    }

    /// @inheritdoc ILiquidityDeployer
    function getConversionRateDecimals() external view returns (uint8) {
        return conversionRateDecimals;
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
