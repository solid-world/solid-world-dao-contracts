// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BaseTest.sol";
import "../contracts/interfaces/liquidity-deployer/IUniProxy.sol";
import "../contracts/interfaces/liquidity-deployer/ILiquidityDeployer.sol";
import "../contracts/LiquidityDeployer.sol";

contract LiquidityDeployerTest is BaseTest {
    function testInitializesWithSpecifiedValues() public {
        address token0 = vm.addr(1);
        address token1 = vm.addr(2);
        address gammaVault = vm.addr(3);
        address uniProxy = vm.addr(4);
        uint conversionRate = 1;
        uint8 conversionRateDecimals = 6;

        ILiquidityDeployer liquidityDeployer = new LiquidityDeployer(
            token0,
            token1,
            gammaVault,
            uniProxy,
            conversionRate,
            conversionRateDecimals
        );

        assertEq(liquidityDeployer.getToken0(), token0);
        assertEq(liquidityDeployer.getToken1(), token1);
        assertEq(liquidityDeployer.getGammaVault(), gammaVault);
        assertEq(liquidityDeployer.getUniProxy(), uniProxy);
        assertEq(liquidityDeployer.getConversionRate(), conversionRate);
        assertEq(liquidityDeployer.getConversionRateDecimals(), conversionRateDecimals);
    }
}
