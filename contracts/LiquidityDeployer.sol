// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/liquidity-deployer/ILiquidityDeployer.sol";
import "./interfaces/liquidity-deployer/IUniProxy.sol";

/// @author Solid World
contract LiquidityDeployer is ILiquidityDeployer {
    IERC20 internal immutable token0;
    IERC20 internal immutable token1;
    address internal immutable gammaVault;
    IUniProxy internal immutable uniProxy;
    uint internal immutable conversionRate;
    uint8 internal immutable conversionRateDecimals;

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
}
