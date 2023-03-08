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

    function testDepositToken0_increasesTotalDepositOfToken0() public {
        uint amount = 100;

        liquidityDeployer.depositToken0(amount);
        (uint token0Amount, ) = liquidityDeployer.getTotalDeposits();
        assertEq(token0Amount, amount);

        liquidityDeployer.depositToken0(amount);
        (token0Amount, ) = liquidityDeployer.getTotalDeposits();
        assertEq(token0Amount, amount * 2);
    }

    function testDepositToken1_increasesTotalDepositOfToken1() public {
        uint amount = 100;

        liquidityDeployer.depositToken1(amount);
        (, uint token1Amount) = liquidityDeployer.getTotalDeposits();
        assertEq(token1Amount, amount);

        liquidityDeployer.depositToken1(amount);
        (, token1Amount) = liquidityDeployer.getTotalDeposits();
        assertEq(token1Amount, amount * 2);
    }

    function testDepositToken0_addsDepositorToToken0DepositorsOnlyOnce() public {
        uint amount = 100;

        liquidityDeployer.depositToken0(amount);
        address[] memory token0Depositors = liquidityDeployer.getToken0Depositors();
        assertEq(token0Depositors.length, 1);
        assertEq(token0Depositors[0], address(this));

        liquidityDeployer.depositToken0(amount);
        token0Depositors = liquidityDeployer.getToken0Depositors();
        assertEq(token0Depositors.length, 1);
        assertEq(token0Depositors[0], address(this));
    }

    function testDepositToken1_addsDepositorToToken1DepositorsOnlyOnce() public {
        uint amount = 100;

        liquidityDeployer.depositToken1(amount);
        address[] memory token1Depositors = liquidityDeployer.getToken1Depositors();
        assertEq(token1Depositors.length, 1);
        assertEq(token1Depositors[0], address(this));

        liquidityDeployer.depositToken1(amount);
        token1Depositors = liquidityDeployer.getToken1Depositors();
        assertEq(token1Depositors.length, 1);
        assertEq(token1Depositors[0], address(this));
    }

    function testDepositToken0_token0BalanceOfLiquidityDeployerIncreasesWithDepositAmount() public {
        uint amount = 100;

        uint token0BalanceBefore = IERC20(token0).balanceOf(address(liquidityDeployer));
        liquidityDeployer.depositToken0(amount);
        liquidityDeployer.depositToken0(amount * 2);
        uint token0BalanceAfter = IERC20(token0).balanceOf(address(liquidityDeployer));

        assertEq(token0BalanceAfter, token0BalanceBefore + amount * 3);
    }

    function testDepositToken1_token1BalanceOfLiquidityDeployerIncreasesWithDepositAmount() public {
        uint amount = 100;

        uint token1BalanceBefore = IERC20(token1).balanceOf(address(liquidityDeployer));
        liquidityDeployer.depositToken1(amount);
        liquidityDeployer.depositToken1(amount * 2);
        uint token1BalanceAfter = IERC20(token1).balanceOf(address(liquidityDeployer));

        assertEq(token1BalanceAfter, token1BalanceBefore + amount * 3);
    }

    function testDepositToken0_emitsDepositEvent() public {
        uint amount = 100;

        _expectEmit_Token0Deposited(address(this), amount);
        liquidityDeployer.depositToken0(amount);
    }

    function testDepositToken1_emitsDepositEvent() public {
        uint amount = 100;

        _expectEmit_Token1Deposited(address(this), amount);
        liquidityDeployer.depositToken1(amount);
    }

    function testConvertToken0DecimalsToToken1_revertsIfConvertedValueIs0() public {
        uint token0Amount = 0.9999999e12; //1e12 is the minimum amount of token0 that can be converted to token1

        _expectRevert_Token0AmountTooSmall(token0Amount);
        liquidityDeployer.convertToken0DecimalsToToken1(token0Amount);
    }

    function testConvertToken0DecimalsToToken1() public {
        assertEq(liquidityDeployer.convertToken0DecimalsToToken1(1e12), 1);
        assertEq(liquidityDeployer.convertToken0DecimalsToToken1(100e18), 100e6);
    }

    function testConvertToken0ValueToToken1() public {
        assertEq(liquidityDeployer.convertToken0ValueToToken1(1e12), 25);
        assertEq(liquidityDeployer.convertToken0ValueToToken1(100e18), 2550e6);
    }
}
