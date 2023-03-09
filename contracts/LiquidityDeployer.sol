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
    LiquidityDeployerDataTypes.Depositors internal depositors;

    /// @dev Token => Account => Amount
    mapping(address => mapping(address => uint)) internal lastDeployedLiquidity;
    /// @dev Token => Amount
    mapping(address => uint) internal lastTotalDeployedLiquidity;
    /// @dev Token => Amount
    mapping(address => uint) internal totalDeposits;
    /// @dev Account => Token => Balance
    mapping(address => mapping(address => uint)) internal userTokenBalance;

    modifier validTokenAmount(uint amount) {
        if (amount == 0) {
            revert InvalidInput();
        }
        _;
    }

    modifier sufficientDeposits() {
        uint token0Deposits = totalDeposits[_token0Address()];
        uint token1Deposits = totalDeposits[_token1Address()];

        if (token0Deposits == 0 || token1Deposits == 0) {
            revert NotEnoughDeposits(token0Deposits, token1Deposits);
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
        _depositToken(_token0Address(), amount);
    }

    /// @inheritdoc ILiquidityDeployer
    function depositToken1(uint amount) external nonReentrant validTokenAmount(amount) {
        _depositToken(_token1Address(), amount);
    }

    function withdrawToken0(uint amount) external nonReentrant validTokenAmount(amount) {
        _withdrawToken(_token0Address(), amount);
    }

    function withdrawToken1(uint amount) external nonReentrant validTokenAmount(amount) {
        _withdrawToken(_token1Address(), amount);
    }

    /// @inheritdoc ILiquidityDeployer
    function deployLiquidity() external nonReentrant sufficientDeposits {
        (
            lastTotalDeployedLiquidity[_token0Address()],
            lastTotalDeployedLiquidity[_token1Address()]
        ) = _computeDeployableLiquidity();

        _allowUniProxyToSpendDeployableLiquidity();
        _depositToUniProxy();
    }

    function getToken0() external view returns (address) {
        return _token0Address();
    }

    function getToken1() external view returns (address) {
        return _token1Address();
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
        return userTokenBalance[account][_token0Address()];
    }

    function token1BalanceOf(address account) external view returns (uint) {
        return userTokenBalance[account][_token1Address()];
    }

    function getTotalDeposits() external view returns (uint token0Amount, uint token1Amount) {
        token0Amount = totalDeposits[_token0Address()];
        token1Amount = totalDeposits[_token1Address()];
    }

    function getTokenDepositors() external view returns (address[] memory tokenDepositors) {
        tokenDepositors = new address[](depositors.tokenDepositors.length);
        for (uint i; i < depositors.tokenDepositors.length; i++) {
            tokenDepositors[i] = depositors.tokenDepositors[i];
        }
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken0LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount)
    {
        lastDeployedAmount = lastDeployedLiquidity[_token0Address()][liquidityProvider];
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken1LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount)
    {
        lastDeployedAmount = lastDeployedLiquidity[_token1Address()][liquidityProvider];
    }

    function getLastTotalDeployedLiquidity() external view returns (uint, uint) {
        return (lastTotalDeployedLiquidity[_token0Address()], lastTotalDeployedLiquidity[_token1Address()]);
    }

    function _computeDeployableLiquidity()
        internal
        returns (uint token0TotalDeployableLiquidity, uint token1TotalDeployableLiquidity)
    {
        uint totalToken0ValueInToken1 = LiquidityDeployerMath.convertTokenValue(
            _token0Decimals(),
            _token1Decimals(),
            config.conversionRate,
            config.conversionRateDecimals,
            totalDeposits[_token0Address()]
        );

        if (totalToken0ValueInToken1 > totalDeposits[_token1Address()]) {
            LiquidityDeployerDataTypes.Fraction memory fraction = LiquidityDeployerDataTypes.Fraction(
                totalDeposits[_token1Address()],
                totalToken0ValueInToken1
            );
            token0TotalDeployableLiquidity = _computeTokenDeployableLiquidity(_token0Address(), fraction);
            token1TotalDeployableLiquidity = _computeTokenDeployableLiquidity(
                _token1Address(),
                LiquidityDeployerMath.neutralFraction()
            );
        } else {
            LiquidityDeployerDataTypes.Fraction memory adjustmentFactor = LiquidityDeployerDataTypes.Fraction(
                totalToken0ValueInToken1,
                totalDeposits[_token1Address()]
            );
            token0TotalDeployableLiquidity = _computeTokenDeployableLiquidity(
                _token0Address(),
                LiquidityDeployerMath.neutralFraction()
            );
            token1TotalDeployableLiquidity = _computeTokenDeployableLiquidity(
                _token1Address(),
                adjustmentFactor
            );
        }
    }

    function _computeTokenDeployableLiquidity(
        address token,
        LiquidityDeployerDataTypes.Fraction memory adjustmentFactor
    ) internal returns (uint totalDeployableLiquidity) {
        for (uint i; i < depositors.tokenDepositors.length; i++) {
            address tokenDepositor = depositors.tokenDepositors[i];
            uint tokenDepositorBalance = userTokenBalance[tokenDepositor][token];

            if (tokenDepositorBalance == 0) {
                lastDeployedLiquidity[token][tokenDepositor] = 0;
                continue;
            }

            lastDeployedLiquidity[token][tokenDepositor] = LiquidityDeployerMath.adjustTokenAmount(
                tokenDepositorBalance,
                adjustmentFactor
            );
            totalDeployableLiquidity += lastDeployedLiquidity[token][tokenDepositor];
        }
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
        config.token0.approve(address(config.uniProxy), lastTotalDeployedLiquidity[_token0Address()]);
        config.token1.approve(address(config.uniProxy), lastTotalDeployedLiquidity[_token1Address()]);
    }

    function _depositToUniProxy() internal returns (uint lpTokens) {
        return
            config.uniProxy.deposit(
                lastTotalDeployedLiquidity[_token0Address()],
                lastTotalDeployedLiquidity[_token1Address()],
                address(this),
                config.gammaVault,
                _uniProxyMinIn()
            );
    }

    function _token0Decimals() internal view returns (uint8) {
        return IERC20Metadata(address(config.token0)).decimals();
    }

    function _token1Decimals() internal view returns (uint8) {
        return IERC20Metadata(address(config.token1)).decimals();
    }

    function _token0Address() internal view returns (address) {
        return address(config.token0);
    }

    function _token1Address() internal view returns (address) {
        return address(config.token1);
    }

    function _uniProxyMinIn() internal pure returns (uint[4] memory) {
        return [uint(0), uint(0), uint(0), uint(0)];
    }
}
