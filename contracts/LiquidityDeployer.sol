// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/liquidity-deployer/ILiquidityDeployer.sol";
import "./libraries/liquidity-deployer/LiquidityDeployerDataTypes.sol";
import "./libraries/liquidity-deployer/LiquidityDeployerMath.sol";
import "./libraries/GPv2SafeERC20.sol";

/// @author Solid World
contract LiquidityDeployer is ILiquidityDeployer, ReentrancyGuard {
    using GPv2SafeERC20 for IERC20;

    LiquidityDeployerDataTypes.Config internal config;
    LiquidityDeployerDataTypes.TotalDeposits internal totalDeposits;
    LiquidityDeployerDataTypes.Depositors internal depositors;
    LiquidityDeployerDataTypes.DeployedLiquidity internal lastDeployedLiquidity;

    /// @dev Account => token0 balance
    mapping(address => uint) internal token0Balance;
    /// @dev Account => token1 balance
    mapping(address => uint) internal token1Balance;

    modifier validTokenAmount(uint amount) {
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
    function depositToken0(uint amount) external nonReentrant validTokenAmount(amount) {
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
    function depositToken1(uint amount) external nonReentrant validTokenAmount(amount) {
        token1Balance[msg.sender] += amount;
        totalDeposits.token1Amount += amount;

        if (!_isToken1Depositor(msg.sender)) {
            depositors.isToken1Depositor[msg.sender] = true;
            depositors.token1Depositors.push(msg.sender);
        }

        config.token1.safeTransferFrom(msg.sender, address(this), amount);

        emit Token1Deposited(msg.sender, amount);
    }

    function withdrawToken0(uint amount) external nonReentrant validTokenAmount(amount) {
        if (token0Balance[msg.sender] < amount) {
            revert InsufficientToken0Balance(msg.sender, token0Balance[msg.sender], amount);
        }

        token0Balance[msg.sender] -= amount;
        totalDeposits.token0Amount -= amount;

        config.token0.safeTransfer(msg.sender, amount);

        emit Token0Withdrawn(msg.sender, amount);
    }

    function withdrawToken1(uint amount) external nonReentrant validTokenAmount(amount) {
        if (token1Balance[msg.sender] < amount) {
            revert InsufficientToken1Balance(msg.sender, token1Balance[msg.sender], amount);
        }

        token1Balance[msg.sender] -= amount;
        totalDeposits.token1Amount -= amount;

        config.token1.safeTransfer(msg.sender, amount);

        emit Token1Withdrawn(msg.sender, amount);
    }

    /// @inheritdoc ILiquidityDeployer
    function deployLiquidity() external nonReentrant {
        _computeDeployableLiquidity();
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
    function getLastToken0LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount)
    {
        lastDeployedAmount = lastDeployedLiquidity.token0[liquidityProvider];
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken1LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount)
    {
        lastDeployedAmount = lastDeployedLiquidity.token1[liquidityProvider];
    }

    function _computeDeployableLiquidity() internal {
        uint totalToken0ValueInToken1 = LiquidityDeployerMath.convertToken0ValueToToken1(
            _token0Decimals(),
            _token1Decimals(),
            config.conversionRate,
            config.conversionRateDecimals,
            totalDeposits.token0Amount
        );

        if (totalToken0ValueInToken1 > totalDeposits.token1Amount) {
            LiquidityDeployerDataTypes.AdjustmentFactor memory adjustmentFactor = LiquidityDeployerDataTypes
                .AdjustmentFactor(totalDeposits.token1Amount, totalToken0ValueInToken1);
            _computeToken0DeployableLiquidity(adjustmentFactor);
            _computeToken1DeployableLiquidity(LiquidityDeployerMath.neutralAdjustmentFactor());
        } else {
            LiquidityDeployerDataTypes.AdjustmentFactor memory adjustmentFactor = LiquidityDeployerDataTypes
                .AdjustmentFactor(totalToken0ValueInToken1, totalDeposits.token1Amount);
            _computeToken0DeployableLiquidity(LiquidityDeployerMath.neutralAdjustmentFactor());
            _computeToken1DeployableLiquidity(adjustmentFactor);
        }
    }

    function _computeToken0DeployableLiquidity(
        LiquidityDeployerDataTypes.AdjustmentFactor memory adjustmentFactor
    ) internal {
        for (uint i; i < depositors.token0Depositors.length; i++) {
            address token0Depositor = depositors.token0Depositors[i];
            uint token0DepositorBalance = token0Balance[token0Depositor];

            if (token0DepositorBalance == 0) {
                lastDeployedLiquidity.token0[token0Depositor] = 0;
                continue;
            }

            lastDeployedLiquidity.token0[token0Depositor] = LiquidityDeployerMath.adjustTokenAmount(
                token0DepositorBalance,
                adjustmentFactor
            );
        }
    }

    function _computeToken1DeployableLiquidity(
        LiquidityDeployerDataTypes.AdjustmentFactor memory adjustmentFactor
    ) internal {
        for (uint i; i < depositors.token1Depositors.length; i++) {
            address token1Depositor = depositors.token1Depositors[i];
            uint token1DepositorBalance = token1Balance[token1Depositor];

            if (token1DepositorBalance == 0) {
                lastDeployedLiquidity.token1[token1Depositor] = 0;
                continue;
            }

            lastDeployedLiquidity.token1[token1Depositor] = LiquidityDeployerMath.adjustTokenAmount(
                token1DepositorBalance,
                adjustmentFactor
            );
        }
    }

    function _isToken0Depositor(address account) internal view returns (bool) {
        return depositors.isToken0Depositor[account];
    }

    function _isToken1Depositor(address account) internal view returns (bool) {
        return depositors.isToken1Depositor[account];
    }

    function _token0Decimals() internal view returns (uint8) {
        return IERC20Metadata(address(config.token0)).decimals();
    }

    function _token1Decimals() internal view returns (uint8) {
        return IERC20Metadata(address(config.token1)).decimals();
    }
}
