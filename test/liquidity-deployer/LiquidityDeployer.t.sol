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

    function testDepositToken0_addsDepositorToDepositorsOnlyOnce() public {
        uint amount = 100;

        liquidityDeployer.depositToken0(amount);
        address[] memory tokenDepositors = liquidityDeployer.getTokenDepositors();
        assertEq(tokenDepositors.length, 1);
        assertEq(tokenDepositors[0], address(this));

        liquidityDeployer.depositToken0(amount);
        tokenDepositors = liquidityDeployer.getTokenDepositors();
        assertEq(tokenDepositors.length, 1);
        assertEq(tokenDepositors[0], address(this));
    }

    function testDepositToken1_addsDepositorToDepositorsOnlyOnce() public {
        uint amount = 100;

        liquidityDeployer.depositToken1(amount);
        address[] memory tokenDepositors = liquidityDeployer.getTokenDepositors();
        assertEq(tokenDepositors.length, 1);
        assertEq(tokenDepositors[0], address(this));

        liquidityDeployer.depositToken1(amount);
        tokenDepositors = liquidityDeployer.getTokenDepositors();
        assertEq(tokenDepositors.length, 1);
        assertEq(tokenDepositors[0], address(this));
    }

    function testDepositBothTokens_addsDepositorToDepositorsOnlyOnce() public {
        uint amount = 100;

        liquidityDeployer.depositToken0(amount);
        address[] memory tokenDepositors = liquidityDeployer.getTokenDepositors();
        assertEq(tokenDepositors.length, 1);
        assertEq(tokenDepositors[0], address(this));

        liquidityDeployer.depositToken1(amount);
        tokenDepositors = liquidityDeployer.getTokenDepositors();
        assertEq(tokenDepositors.length, 1);
        assertEq(tokenDepositors[0], address(this));
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

        _expectEmit_TokenDeposited(token0, address(this), amount);
        liquidityDeployer.depositToken0(amount);
    }

    function testDepositToken1_emitsDepositEvent() public {
        uint amount = 100;

        _expectEmit_TokenDeposited(token1, address(this), amount);
        liquidityDeployer.depositToken1(amount);
    }

    function testWithdrawToken0_revertsIfAmountIs0() public {
        _expectRevert_InvalidInput();
        liquidityDeployer.withdrawToken0(0);
    }

    function testWithdrawToken1_revertsIfAmountIs0() public {
        _expectRevert_InvalidInput();
        liquidityDeployer.withdrawToken1(0);
    }

    function testWithdrawToken0_revertsIfAmountIsGreaterThanBalance() public {
        uint withdrawAmount = 10_001;

        _expectRevert_InsufficientTokenBalance(token0, address(this), 0, withdrawAmount);
        liquidityDeployer.withdrawToken0(withdrawAmount);
    }

    function testWithdrawToken1_revertsIfAmountIsGreaterThanBalance() public {
        uint withdrawAmount = 10_001;

        _expectRevert_InsufficientTokenBalance(token1, address(this), 0, withdrawAmount);
        liquidityDeployer.withdrawToken1(withdrawAmount);
    }

    function testWithdrawToken0_decreasesBalanceOfToken0() public {
        uint amount = 100;

        liquidityDeployer.depositToken0(3 * amount);

        liquidityDeployer.withdrawToken0(amount);
        assertEq(liquidityDeployer.token0BalanceOf(address(this)), amount * 2);

        liquidityDeployer.withdrawToken0(amount * 2);
        assertEq(liquidityDeployer.token0BalanceOf(address(this)), 0);
    }

    function testWithdrawToken1_decreasesBalanceOfToken1() public {
        uint amount = 100;

        liquidityDeployer.depositToken1(3 * amount);

        liquidityDeployer.withdrawToken1(amount);
        assertEq(liquidityDeployer.token1BalanceOf(address(this)), amount * 2);

        liquidityDeployer.withdrawToken1(amount * 2);
        assertEq(liquidityDeployer.token1BalanceOf(address(this)), 0);
    }

    function testWithdrawToken0_decreasesTotalDepositOfToken0() public {
        uint amount = 100;

        liquidityDeployer.depositToken0(3 * amount);

        liquidityDeployer.withdrawToken0(amount);
        (uint token0Amount, ) = liquidityDeployer.getTotalDeposits();
        assertEq(token0Amount, amount * 2);

        liquidityDeployer.withdrawToken0(amount * 2);
        (token0Amount, ) = liquidityDeployer.getTotalDeposits();
        assertEq(token0Amount, 0);
    }

    function testWithdrawToken1_decreasesTotalDepositOfToken1() public {
        uint amount = 100;

        liquidityDeployer.depositToken1(3 * amount);

        liquidityDeployer.withdrawToken1(amount);
        (, uint token1Amount) = liquidityDeployer.getTotalDeposits();
        assertEq(token1Amount, amount * 2);

        liquidityDeployer.withdrawToken1(amount * 2);
        (, token1Amount) = liquidityDeployer.getTotalDeposits();
        assertEq(token1Amount, 0);
    }

    function testWithdrawToken0_token0BalanceOfLiquidityDeployerDecreasesWithWithdrawAmount() public {
        uint amount = 100;

        liquidityDeployer.depositToken0(3 * amount);

        uint token0BalanceBefore = IERC20(token0).balanceOf(address(liquidityDeployer));
        liquidityDeployer.withdrawToken0(amount);
        uint token0BalanceAfter = IERC20(token0).balanceOf(address(liquidityDeployer));

        assertEq(token0BalanceAfter, token0BalanceBefore - amount);
    }

    function testWithdrawToken1_token1BalanceOfLiquidityDeployerDecreasesWithWithdrawAmount() public {
        uint amount = 100;

        liquidityDeployer.depositToken1(3 * amount);

        uint token1BalanceBefore = IERC20(token1).balanceOf(address(liquidityDeployer));
        liquidityDeployer.withdrawToken1(amount);
        uint token1BalanceAfter = IERC20(token1).balanceOf(address(liquidityDeployer));

        assertEq(token1BalanceAfter, token1BalanceBefore - amount);
    }

    function testWithdrawToken0_emitsWithdrawEvent() public {
        uint amount = 100;

        liquidityDeployer.depositToken0(amount);

        _expectEmit_TokenWithdrawn(token0, address(this), amount);
        liquidityDeployer.withdrawToken0(amount);
    }

    function testWithdrawToken1_emitsWithdrawEvent() public {
        uint amount = 100;

        liquidityDeployer.depositToken1(amount);

        _expectEmit_TokenWithdrawn(token1, address(this), amount);
        liquidityDeployer.withdrawToken1(amount);
    }

    function testDeployLiquidity_revertsIfNotEnoughDeposits() public {
        _expectRevert_NotEnoughDeposits(0, 0);
        liquidityDeployer.deployLiquidity();

        liquidityDeployer.depositToken0(1);
        _expectRevert_NotEnoughDeposits(1, 0);
        liquidityDeployer.deployLiquidity();

        liquidityDeployer.depositToken1(1);
        liquidityDeployer.withdrawToken0(1);
        _expectRevert_NotEnoughDeposits(0, 1);
        liquidityDeployer.deployLiquidity();
    }

    function testDeployLiquidity_lastDeployableLiquidity_totalDepositOfToken0IsBigger_bothAccountsDepositBothTokens()
        public
    {
        _doDeposits(5e18, 50e6, 3e18, 100e6);

        // totalToken0 = 204e6 (converted to token1)
        // adjustmentFactor = 150e6/204e6 = 0.735294117647058823529411764705

        uint account0Token0Deployable = 3.676470588235294117e18; // account0Token0Deposit * adjustmentFactor
        uint account1Token0Deployable = 2.205882352941176470e18; // account1Token0Deposit * adjustmentFactor
        uint account0Token1Deployable = 50e6;
        uint account1Token1Deployable = 100e6;

        liquidityDeployer.deployLiquidity();

        assertEq(liquidityDeployer.getLastToken0LiquidityDeployed(testAccount0), account0Token0Deployable);
        assertEq(liquidityDeployer.getLastToken0LiquidityDeployed(testAccount1), account1Token0Deployable);
        assertEq(liquidityDeployer.getLastToken1LiquidityDeployed(testAccount0), account0Token1Deployable);
        assertEq(liquidityDeployer.getLastToken1LiquidityDeployed(testAccount1), account1Token1Deployable);
    }

    function testDeployLiquidity_lastDeployableLiquidity_totalDepositOfToken1IsBigger_bothAccountsDepositBothTokens()
        public
    {
        _doDeposits(5e18, 250e6, 3e18, 100e6);

        // totalToken0 = 204e6 (converted to token1)
        // adjustmentFactor = 204e6/350e6 = 0.582857142857142857142857142857

        uint account0Token0Deployable = 5e18;
        uint account1Token0Deployable = 3e18;
        uint account0Token1Deployable = 145.714285e6; // account0Token1Deposit * adjustmentFactor
        uint account1Token1Deployable = 58.285714e6; // account1Token1Deposit * adjustmentFactor

        liquidityDeployer.deployLiquidity();

        assertEq(liquidityDeployer.getLastToken0LiquidityDeployed(testAccount0), account0Token0Deployable);
        assertEq(liquidityDeployer.getLastToken0LiquidityDeployed(testAccount1), account1Token0Deployable);
        assertEq(liquidityDeployer.getLastToken1LiquidityDeployed(testAccount0), account0Token1Deployable);
        assertEq(liquidityDeployer.getLastToken1LiquidityDeployed(testAccount1), account1Token1Deployable);
    }

    function testDeployLiquidity_lastDeployableLiquidity_totalDepositOfToken0IsBigger_account0DepositsBothTokens_account1DepositsToken0()
        public
    {
        _doDeposits(5e18, 50e6, 3e18, 0);

        // totalToken0 = 204e6 (converted to token1)
        // adjustmentFactor = 50e6/204e6 = 0.245098039215686274509803921568

        uint account0Token0Deployable = 1.225490196078431372e18; // account0Token0Deposit * adjustmentFactor
        uint account1Token0Deployable = 0.735294117647058823e18; // account1Token0Deposit * adjustmentFactor
        uint account0Token1Deployable = 50e6;
        uint account1Token1Deployable = 0;

        liquidityDeployer.deployLiquidity();

        assertEq(liquidityDeployer.getLastToken0LiquidityDeployed(testAccount0), account0Token0Deployable);
        assertEq(liquidityDeployer.getLastToken0LiquidityDeployed(testAccount1), account1Token0Deployable);
        assertEq(liquidityDeployer.getLastToken1LiquidityDeployed(testAccount0), account0Token1Deployable);
        assertEq(liquidityDeployer.getLastToken1LiquidityDeployed(testAccount1), account1Token1Deployable);
    }

    function testDeployLiquidity_lastTotalDeployedLiquidity() public {
        _doDeposits(5e18, 50e6, 3e18, 100e6);

        uint account0Token0Deployable = 3.676470588235294117e18;
        uint account1Token0Deployable = 2.205882352941176470e18;
        uint account0Token1Deployable = 50e6;
        uint account1Token1Deployable = 100e6;

        liquidityDeployer.deployLiquidity();

        (uint lastToken0DeployedLiquidity, uint lastToken1DeployedLiquidity) = liquidityDeployer
            .getLastTotalDeployedLiquidity();

        assertEq(lastToken0DeployedLiquidity, account0Token0Deployable + account1Token0Deployable);
        assertEq(lastToken1DeployedLiquidity, account0Token1Deployable + account1Token1Deployable);
    }

    function testDeployLiquidity_approvesUniProxyToSpendDeployableTokens() public {
        _doDeposits(5e18, 50e6, 3e18, 100e6);

        uint account0Token0Deployable = 3.676470588235294117e18;
        uint account1Token0Deployable = 2.205882352941176470e18;
        uint account0Token1Deployable = 50e6;
        uint account1Token1Deployable = 100e6;

        liquidityDeployer.deployLiquidity();

        assertEq(
            IERC20(token0).allowance(address(liquidityDeployer), address(uniProxy)),
            account0Token0Deployable + account1Token0Deployable
        );
        assertEq(
            IERC20(token1).allowance(address(liquidityDeployer), address(uniProxy)),
            account0Token1Deployable + account1Token1Deployable
        );
    }

    function testDeployLiquidity_calls_UniProxy_deposit() public {
        _doDeposits(5e18, 50e6, 3e18, 100e6);

        uint account0Token0Deployable = 3.676470588235294117e18;
        uint account1Token0Deployable = 2.205882352941176470e18;
        uint account0Token1Deployable = 50e6;
        uint account1Token1Deployable = 100e6;

        _expectDepositIsCalledOnUniProxy(
            account0Token0Deployable + account1Token0Deployable,
            account0Token1Deployable + account1Token1Deployable,
            address(liquidityDeployer),
            gammaVault
        );
        liquidityDeployer.deployLiquidity();
    }
}
