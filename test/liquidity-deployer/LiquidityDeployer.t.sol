// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseLiquidityDeployer.t.sol";

contract LiquidityDeployerTest is BaseLiquidityDeployerTest {
    function testInitializesWithSpecifiedValues() public {
        assertEq(liquidityDeployer.getToken0(), token0);
        assertEq(liquidityDeployer.getToken1(), token1);
        assertEq(liquidityDeployer.getGammaVault(), gammaVault);
        assertEq(liquidityDeployer.getUniProxy(), uniProxy);
        assertEq(liquidityDeployer.getConversionRate(), conversionRate);
        assertEq(liquidityDeployer.getConversionRateDecimals(), conversionRateDecimals);
    }

    function testDepositMustBeGreaterThan0ForToken0() public {
        _expectRevert_InvalidInput();
        liquidityDeployer.depositToken0(0);
    }

    function testDepositMustBeGreaterThan0ForToken1() public {
        _expectRevert_InvalidInput();
        liquidityDeployer.depositToken1(0);
    }

    function testDepositToken0_increasesBalanceOfToken0() public {
        uint amount = 100;

        liquidityDeployer.depositToken0(amount);
        assertEq(liquidityDeployer.token0BalanceOf(address(this)), amount);

        liquidityDeployer.depositToken0(amount);
        assertEq(liquidityDeployer.token0BalanceOf(address(this)), amount * 2);
    }

    function testDepositToken1_increasesBalanceOfToken1() public {
        uint amount = 100;

        liquidityDeployer.depositToken1(amount);
        assertEq(liquidityDeployer.token1BalanceOf(address(this)), amount);

        liquidityDeployer.depositToken1(amount);
        assertEq(liquidityDeployer.token1BalanceOf(address(this)), amount * 2);
    }
}
