// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/liquidity-deployer/ILiquidityDeployer.sol";
import "./interfaces/liquidity-deployer/IUniProxy.sol";
import "./libraries/liquidity-deployer/LiquidityDeployerDataTypes.sol";
import "./libraries/liquidity-deployer/LiquidityDeployerMath.sol";
import "./libraries/GPv2SafeERC20.sol";

/// @author Solid World
contract LiquidityDeployer is ILiquidityDeployer, ReentrancyGuard {
    using GPv2SafeERC20 for IERC20;

    LiquidityDeployerDataTypes.Config internal config;
    LiquidityDeployerDataTypes.Depositors internal depositors;

    /// @dev Account => Token => Balance
    mapping(address => mapping(address => uint)) internal userTokenBalance;

    /// @dev Token => Account => Amount
    mapping(address => mapping(address => uint)) internal lastDeployedLiquidity;
    /// @dev Token => Amount
    mapping(address => uint) internal lastTotalDeployedLiquidity;
    /// @dev Token => Amount
    mapping(address => uint) internal lastAvailableLiquidity;
    /// @dev Account => Amount
    mapping(address => uint) internal lastLPTokensOwed;
    /// @dev Token => Amount
    mapping(address => uint) internal totalDeposits;

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
        config.token0 = token0;
        config.token1 = token1;
        config.gammaVault = gammaVault;
        config.uniProxy = uniProxy;
        config.conversionRate = conversionRate;
        config.conversionRateDecimals = conversionRateDecimals;
        config.token0Decimals = IERC20Metadata(token0).decimals();
        config.token1Decimals = IERC20Metadata(token1).decimals();
        config.minConvertibleToken0Amount = LiquidityDeployerMath.minConvertibleToken0Amount(
            config.token0Decimals,
            config.token1Decimals,
            conversionRate,
            conversionRateDecimals
        );
    }

    /// @inheritdoc ILiquidityDeployer
    function depositToken0(uint amount) external nonReentrant validTokenAmount(amount) {
        _depositToken(config.token0, amount);
    }

    /// @inheritdoc ILiquidityDeployer
    function depositToken1(uint amount) external nonReentrant validTokenAmount(amount) {
        _depositToken(config.token1, amount);
    }

    function withdrawToken0(uint amount) external nonReentrant validTokenAmount(amount) {
        _withdrawToken(config.token0, amount);
    }

    function withdrawToken1(uint amount) external nonReentrant validTokenAmount(amount) {
        _withdrawToken(config.token1, amount);
    }

    /// @inheritdoc ILiquidityDeployer
    function deployLiquidity() external nonReentrant {
        (
            lastAvailableLiquidity[config.token0],
            lastAvailableLiquidity[config.token1]
        ) = _computeAvailableLiquidity();

        (
            lastTotalDeployedLiquidity[config.token0],
            lastTotalDeployedLiquidity[config.token1]
        ) = _prepareDeployableLiquidity();

        _allowUniProxyToSpendDeployableLiquidity();
        uint lpTokens = _depositToUniProxy();

        _prepareLPTokensOwed(lpTokens);
    }

    function getToken0() external view returns (address) {
        return config.token0;
    }

    function getToken1() external view returns (address) {
        return config.token1;
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

    /// @inheritdoc ILiquidityDeployer
    function getMinConvertibleToken0Amount() external view returns (uint) {
        return config.minConvertibleToken0Amount;
    }

    function token0BalanceOf(address account) external view returns (uint) {
        return userTokenBalance[account][config.token0];
    }

    function token1BalanceOf(address account) external view returns (uint) {
        return userTokenBalance[account][config.token1];
    }

    function getTotalDeposits() external view returns (uint token0Amount, uint token1Amount) {
        token0Amount = totalDeposits[config.token0];
        token1Amount = totalDeposits[config.token1];
    }

    function getTokenDepositors() external view returns (address[] memory tokenDepositors) {
        tokenDepositors = new address[](depositors.tokenDepositors.length);
        for (uint i; i < depositors.tokenDepositors.length; i++) {
            tokenDepositors[i] = depositors.tokenDepositors[i];
        }
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken0AvailableLiquidity() external view returns (uint) {
        return lastAvailableLiquidity[config.token0];
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken1AvailableLiquidity() external view returns (uint) {
        return lastAvailableLiquidity[config.token1];
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken0LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount)
    {
        lastDeployedAmount = lastDeployedLiquidity[config.token0][liquidityProvider];
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken1LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount)
    {
        lastDeployedAmount = lastDeployedLiquidity[config.token1][liquidityProvider];
    }

    function getLastTotalDeployedLiquidity() external view returns (uint, uint) {
        return (lastTotalDeployedLiquidity[config.token0], lastTotalDeployedLiquidity[config.token1]);
    }

    function getLastLPTokensOwed(address liquidityProvider) external view returns (uint) {
        return lastLPTokensOwed[liquidityProvider];
    }

    function _computeAvailableLiquidity()
        internal
        view
        returns (uint token0AvailableLiquidity, uint token1AvailableLiquidity)
    {
        for (uint i; i < depositors.tokenDepositors.length; i++) {
            address depositor = depositors.tokenDepositors[i];
            uint token0Balance = userTokenBalance[depositor][config.token0];
            uint token1Balance = userTokenBalance[depositor][config.token1];

            if (token0Balance >= config.minConvertibleToken0Amount) {
                token0AvailableLiquidity += token0Balance;
            }
            if (token1Balance > 0) {
                token1AvailableLiquidity += token1Balance;
            }
        }
    }

    function _prepareDeployableLiquidity()
        internal
        returns (uint token0TotalDeployableLiquidity, uint token1TotalDeployableLiquidity)
    {
        uint lastAvailableLiquidityToken0ValueInToken1 = _convertToken0ToToken1(
            lastAvailableLiquidity[config.token0]
        );
        if (lastAvailableLiquidityToken0ValueInToken1 == 0 || lastAvailableLiquidity[config.token1] == 0) {
            revert NotEnoughAvailableLiquidity(
                lastAvailableLiquidity[config.token0],
                lastAvailableLiquidity[config.token1]
            );
        }

        if (lastAvailableLiquidityToken0ValueInToken1 > lastAvailableLiquidity[config.token1]) {
            LiquidityDeployerDataTypes.Fraction memory adjustmentFactor = LiquidityDeployerDataTypes.Fraction(
                lastAvailableLiquidity[config.token1],
                lastAvailableLiquidityToken0ValueInToken1
            );
            (token0TotalDeployableLiquidity, token1TotalDeployableLiquidity) = _prepareDeployableLiquidity(
                adjustmentFactor,
                LiquidityDeployerMath.neutralFraction()
            );
        } else {
            LiquidityDeployerDataTypes.Fraction memory adjustmentFactor = LiquidityDeployerDataTypes.Fraction(
                lastAvailableLiquidityToken0ValueInToken1,
                lastAvailableLiquidity[config.token1]
            );
            (token0TotalDeployableLiquidity, token1TotalDeployableLiquidity) = _prepareDeployableLiquidity(
                LiquidityDeployerMath.neutralFraction(),
                adjustmentFactor
            );
        }
    }

    function _prepareDeployableLiquidity(
        LiquidityDeployerDataTypes.Fraction memory token0AdjustmentFactor,
        LiquidityDeployerDataTypes.Fraction memory token1AdjustmentFactor
    ) internal returns (uint token0TotalDeployableLiquidity, uint token1TotalDeployableLiquidity) {
        for (uint i; i < depositors.tokenDepositors.length; i++) {
            address tokenDepositor = depositors.tokenDepositors[i];
            uint token0DeployableLiquidity = _computeDeployableLiquidity(
                config.token0,
                tokenDepositor,
                token0AdjustmentFactor
            );
            token0DeployableLiquidity = token0DeployableLiquidity < config.minConvertibleToken0Amount
                ? 0
                : token0DeployableLiquidity;
            lastDeployedLiquidity[config.token0][tokenDepositor] = token0DeployableLiquidity;
            if (token0DeployableLiquidity > 0) {
                userTokenBalance[tokenDepositor][config.token0] -= token0DeployableLiquidity;
                totalDeposits[config.token0] -= token0DeployableLiquidity;
                token0TotalDeployableLiquidity += token0DeployableLiquidity;
            }

            uint token1DeployableLiquidity = _computeDeployableLiquidity(
                config.token1,
                tokenDepositor,
                token1AdjustmentFactor
            );
            lastDeployedLiquidity[config.token1][tokenDepositor] = token1DeployableLiquidity;
            if (token1DeployableLiquidity > 0) {
                userTokenBalance[tokenDepositor][config.token1] -= token1DeployableLiquidity;
                totalDeposits[config.token1] -= token1DeployableLiquidity;
                token1TotalDeployableLiquidity += token1DeployableLiquidity;
            }
        }
    }

    function _computeDeployableLiquidity(
        address token,
        address depositor,
        LiquidityDeployerDataTypes.Fraction memory adjustmentFactor
    ) internal view returns (uint) {
        uint tokenDepositorBalance = userTokenBalance[depositor][token];

        if (tokenDepositorBalance == 0) {
            return 0;
        }

        return LiquidityDeployerMath.adjustTokenAmount(tokenDepositorBalance, adjustmentFactor);
    }

    function _depositToken(address token, uint amount) internal {
        userTokenBalance[msg.sender][token] += amount;
        totalDeposits[token] += amount;

        if (!depositors.isDepositor[msg.sender]) {
            depositors.isDepositor[msg.sender] = true;
            depositors.tokenDepositors.push(msg.sender);
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit TokenDeposited(token, msg.sender, amount);
    }

    function _withdrawToken(address token, uint amount) internal {
        if (userTokenBalance[msg.sender][token] < amount) {
            revert InsufficientTokenBalance(token, msg.sender, userTokenBalance[msg.sender][token], amount);
        }

        userTokenBalance[msg.sender][token] -= amount;
        totalDeposits[token] -= amount;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit TokenWithdrawn(token, msg.sender, amount);
    }

    function _allowUniProxyToSpendDeployableLiquidity() internal {
        IERC20(config.token0).approve(config.uniProxy, lastTotalDeployedLiquidity[config.token0]);
        IERC20(config.token1).approve(config.uniProxy, lastTotalDeployedLiquidity[config.token1]);
    }

    function _depositToUniProxy() internal returns (uint lpTokens) {
        return
            IUniProxy(config.uniProxy).deposit(
                lastTotalDeployedLiquidity[config.token0],
                lastTotalDeployedLiquidity[config.token1],
                address(this),
                config.gammaVault,
                _uniProxyMinIn()
            );
    }

    function _prepareLPTokensOwed(uint lpTokens) internal {
        uint remainingLpTokens = lpTokens;
        uint totalLiquidityInToken1 = _totalToken0DeployedLiquidityInToken1() +
            lastTotalDeployedLiquidity[config.token1];

        for (uint i; i < depositors.tokenDepositors.length; i++) {
            address tokenDepositor = depositors.tokenDepositors[i];
            uint totalLiquidityInToken1ForDepositor = _totalDeployableLiquidityInToken1ForDepositor(
                tokenDepositor
            );

            if (totalLiquidityInToken1ForDepositor == 0) {
                continue;
            }

            uint lpTokensOwed = Math.mulDiv(
                lpTokens,
                totalLiquidityInToken1ForDepositor,
                totalLiquidityInToken1
            );

            lastLPTokensOwed[tokenDepositor] = lpTokensOwed;
            remainingLpTokens -= lpTokensOwed;
        }

        if (remainingLpTokens > 0) {
            // distribute dust to first depositor
            lastLPTokensOwed[depositors.tokenDepositors[0]] += remainingLpTokens;
        }
    }

    function _totalDeployableLiquidityInToken1ForDepositor(address depositor) internal view returns (uint) {
        uint token0DeployableLiquidity = lastDeployedLiquidity[config.token0][depositor];
        uint token1DeployableLiquidity = lastDeployedLiquidity[config.token1][depositor];
        uint token0DeployableLiquidityInToken1 = _convertToken0ToToken1(token0DeployableLiquidity);

        return token0DeployableLiquidityInToken1 + token1DeployableLiquidity;
    }

    function _totalToken0DeployedLiquidityInToken1() internal view returns (uint) {
        return _convertToken0ToToken1(lastTotalDeployedLiquidity[config.token0]);
    }

    function _convertToken0ToToken1(uint token0Amount) internal view returns (uint) {
        if (token0Amount < config.minConvertibleToken0Amount) {
            return 0;
        }

        return
            LiquidityDeployerMath.convertTokenValue(
                config.token0Decimals,
                config.token1Decimals,
                config.conversionRate,
                config.conversionRateDecimals,
                token0Amount
            );
    }

    function _uniProxyMinIn() internal pure returns (uint[4] memory) {
        return [uint(0), uint(0), uint(0), uint(0)];
    }
}
