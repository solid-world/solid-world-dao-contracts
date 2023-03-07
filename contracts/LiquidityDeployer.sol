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

    constructor(
        address _token0,
        address _token1,
        address _gammaVault,
        address _uniProxy,
        uint _conversionRate
    ) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        gammaVault = _gammaVault;
        uniProxy = IUniProxy(_uniProxy);
        conversionRate = _conversionRate;
    }

    function getToken0() external view returns (address) {
        return address(token0);
    }

    function getToken1() external view returns (address) {
        return address(token1);
    }

    function getGammaVault() external view returns (address) {
        return gammaVault;
    }

    function getUniProxy() external view returns (address) {
        return address(uniProxy);
    }

    function getConversionRate() external view returns (uint) {
        return conversionRate;
    }
}
