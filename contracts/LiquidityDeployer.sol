// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/liquidity-deployer/ILiquidityDeployer.sol";
import "./libraries/liquidity-deployer/LiquidityDeployerDataTypes.sol";
import "./libraries/GPv2SafeERC20.sol";

/// @author Solid World
contract LiquidityDeployer is ILiquidityDeployer, ReentrancyGuard {
    using GPv2SafeERC20 for IERC20;

    LiquidityDeployerDataTypes.Config internal config;
    LiquidityDeployerDataTypes.TotalDeposits internal totalDeposits;
    LiquidityDeployerDataTypes.Depositors internal depositors;

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

    /// @inheritdoc ILiquidityDeployer
    function depositToken0(uint amount) external nonReentrant validDepositAmount(amount) {
        token0Balance[msg.sender] += amount;
        totalDeposits.token0Amount += amount;

        if (!_isToken0Depositor(msg.sender)) {
            depositors.isToken0Depositor[msg.sender] = true;
            depositors.token0Depositors.push(msg.sender);
        }

        config.token0.safeTransferFrom(msg.sender, address(this), amount);

        emit Token0Deposited(msg.sender, amount);
    }

    /// @inheritdoc ILiquidityDeployer
    function depositToken1(uint amount) external nonReentrant validDepositAmount(amount) {
        token1Balance[msg.sender] += amount;
        totalDeposits.token1Amount += amount;

        if (!_isToken1Depositor(msg.sender)) {
            depositors.isToken1Depositor[msg.sender] = true;
            depositors.token1Depositors.push(msg.sender);
        }

        config.token1.safeTransferFrom(msg.sender, address(this), amount);

        emit Token1Deposited(msg.sender, amount);
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

    function getToken0Depositors() external view returns (address[] memory token0Depositors) {
        token0Depositors = new address[](depositors.token0Depositors.length);
        for (uint i; i < depositors.token0Depositors.length; i++) {
            token0Depositors[i] = depositors.token0Depositors[i];
        }
    }

    function getToken1Depositors() external view returns (address[] memory token1Depositors) {
        token1Depositors = new address[](depositors.token1Depositors.length);
        for (uint i; i < depositors.token1Depositors.length; i++) {
            token1Depositors[i] = depositors.token1Depositors[i];
        }
    }

    /// @inheritdoc ILiquidityDeployer
    function convertToken0DecimalsToToken1(uint token0Amount) public view returns (uint) {
        uint token0Decimals = IERC20Metadata(address(config.token0)).decimals();
        uint token1Decimals = IERC20Metadata(address(config.token1)).decimals();

        uint token0AmountConvertedDecimals = Math.mulDiv(
            token0Amount,
            10**token1Decimals,
            10**token0Decimals
        );

        if (token0AmountConvertedDecimals == 0) {
            revert Token0AmountTooSmall(token0Amount);
        }

        return token0AmountConvertedDecimals;
    }

    /// @inheritdoc ILiquidityDeployer
    function convertToken0ValueToToken1(uint token0Amount) public view returns (uint) {
        uint token0AmountConvertedDecimals = convertToken0DecimalsToToken1(token0Amount);

        uint token0Converted = Math.mulDiv(
            token0AmountConvertedDecimals,
            config.conversionRate,
            10**config.conversionRateDecimals
        );

        if (token0Converted == 0) {
            revert Token0AmountTooSmall(token0Amount);
        }

        return token0Converted;
    }

    function _isToken0Depositor(address account) internal view returns (bool) {
        return depositors.isToken0Depositor[account];
    }

    function _isToken1Depositor(address account) internal view returns (bool) {
        return depositors.isToken1Depositor[account];
    }
}
