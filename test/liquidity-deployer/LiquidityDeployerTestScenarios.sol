// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseLiquidityDeployer.sol";

contract LiquidityDeployerTestScenariosTest is BaseLiquidityDeployerTest {
    mapping(uint => TestDataTypes.TestScenario) testScenarios;
    uint testScenariosCount;

    function setUp() public override {
        super.setUp();

        _initializeTestScenarios();
    }

    function _initializeTestScenarios() private {
        _initializeTestScenario_accountsDepositBothTokens_token0ValueIsBigger();
        _initializeTestScenario_accountsDepositBothTokens_token1ValueIsBigger();
        _initializeTestScenario_account1DoesntDepositToken1_token0ValueIsBigger();
        _initializeTestScenario_account1DepositsLessThanMinimumToken0();
        _initializeTestScenario_accountsDepositBothTokens_minimumTokenValues();
        _initializeTestScenario_subunitConversionRate();
        _initializeTestScenario_switchToken0WithToken1();
        _initializeTestScenario_tokensWithEqualDecimals();
    }

    function _initializeTestScenario_accountsDepositBothTokens_token0ValueIsBigger() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.id = vm.toString(testScenariosCount);
        testScenario.account0Token0Deposit = 5e18;
        testScenario.account0Token1Deposit = 50e6;
        testScenario.account1Token0Deposit = 3e18;
        testScenario.account1Token1Deposit = 100e6;
        testScenario.account0Token0Deployable = 3.676470588235294117e18;
        testScenario.account1Token0Deployable = 2.205882352941176470e18;
        testScenario.account0Token1Deployable = 50e6;
        testScenario.account1Token1Deployable = 100e6;
        testScenario.lastToken0DeployedLiquidity = 5.882352941176470588e18;
        testScenario.lastToken1DeployedLiquidity = 150e6;
        testScenario.account0LPTokensOwed = 479166.664930555549768518e18;
        testScenario.account1LPTokensOwed = 520833.331736111105787037e18;
        testScenario.account0RemainingToken0Balance = 1.323529411764705883e18;
        testScenario.account1RemainingToken0Balance = 0.79411764705882353e18;
        testScenario.account0RemainingToken1Balance = 0;
        testScenario.account1RemainingToken1Balance = 0;
        testScenario.lastToken0AvailableLiquidity = 8e18;
        testScenario.lastToken1AvailableLiquidity = 150e6;
        testScenario.adjustmentFactorNumerator = 25.5e6;
        testScenario.adjustmentFactorDenominator = 1e18;
        testScenario.token0 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        testScenario.token1 = address(new TestToken("USD Coin", "USDC", 6));
        testScenario.conversionRate = 255;
        testScenario.conversionRateDecimals = 1;
        testScenario.subsequentValues.account0LPTokensOwed = 958333.329861111099537036e18;
        testScenario.subsequentValues.account1LPTokensOwed = 1041666.663472222211574074e18;
        testScenario.subsequentValues.account0RemainingToken0Balance = 2.647058823529411766e18;
        testScenario.subsequentValues.account1RemainingToken0Balance = 1.58823529411764706e18;
        testScenario.subsequentValues.account0RemainingToken1Balance = 0;
        testScenario.subsequentValues.account1RemainingToken1Balance = 0;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenario.subsequentValues.account0LPTokensOwed += _lpTokensDust_subsequent(testScenario);
        testScenariosCount++;
    }

    function _initializeTestScenario_accountsDepositBothTokens_token1ValueIsBigger() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.id = vm.toString(testScenariosCount);
        testScenario.account0Token0Deposit = 5e18;
        testScenario.account0Token1Deposit = 250e6;
        testScenario.account1Token0Deposit = 3e18;
        testScenario.account1Token1Deposit = 100e6;
        testScenario.account0Token0Deployable = 5e18;
        testScenario.account1Token0Deployable = 3e18;
        testScenario.account0Token1Deployable = 145.714285e6;
        testScenario.account1Token1Deployable = 58.285714e6;
        testScenario.lastToken0DeployedLiquidity = 8e18;
        testScenario.lastToken1DeployedLiquidity = 204e6;
        testScenario.account0LPTokensOwed = 669642.855392156862745098e18;
        testScenario.account1LPTokensOwed = 330357.142156862745098039e18;
        testScenario.account0RemainingToken0Balance = 0;
        testScenario.account1RemainingToken0Balance = 0;
        testScenario.account0RemainingToken1Balance = 104.285715e6;
        testScenario.account1RemainingToken1Balance = 41.714286e6;
        testScenario.lastToken0AvailableLiquidity = 8e18;
        testScenario.lastToken1AvailableLiquidity = 350e6;
        testScenario.adjustmentFactorNumerator = 25.5e6;
        testScenario.adjustmentFactorDenominator = 1e18;
        testScenario.token0 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        testScenario.token1 = address(new TestToken("USD Coin", "USDC", 6));
        testScenario.conversionRate = 255;
        testScenario.conversionRateDecimals = 1;
        testScenario.subsequentValues.account0LPTokensOwed = 1339285.710784313725490196e18;
        testScenario.subsequentValues.account1LPTokensOwed = 660714.284313725490196078e18;
        testScenario.subsequentValues.account0RemainingToken0Balance = 0;
        testScenario.subsequentValues.account1RemainingToken0Balance = 0;
        testScenario.subsequentValues.account0RemainingToken1Balance = 208.57143e6;
        testScenario.subsequentValues.account1RemainingToken1Balance = 83.428572e6;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenario.subsequentValues.account0LPTokensOwed += _lpTokensDust_subsequent(testScenario);
        testScenariosCount++;
    }

    function _initializeTestScenario_account1DoesntDepositToken1_token0ValueIsBigger() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.id = vm.toString(testScenariosCount);
        testScenario.account0Token0Deposit = 5e18;
        testScenario.account0Token1Deposit = 50e6;
        testScenario.account1Token0Deposit = 3e18;
        testScenario.account1Token1Deposit = 0;
        testScenario.account0Token0Deployable = 1.225490196078431372e18;
        testScenario.account1Token0Deployable = 0.735294117647058823e18;
        testScenario.account0Token1Deployable = 50e6;
        testScenario.account1Token1Deployable = 0;
        testScenario.lastToken0DeployedLiquidity = 1.960784313725490196e18;
        testScenario.lastToken1DeployedLiquidity = 50e6;
        testScenario.account0LPTokensOwed = 812500.008125000081250001e18;
        testScenario.account1LPTokensOwed = 187499.991874999918749999e18;
        testScenario.account0RemainingToken0Balance = 3.774509803921568628e18;
        testScenario.account1RemainingToken0Balance = 2.264705882352941177e18;
        testScenario.account0RemainingToken1Balance = 0;
        testScenario.account1RemainingToken1Balance = 0;
        testScenario.lastToken0AvailableLiquidity = 8e18;
        testScenario.lastToken1AvailableLiquidity = 50e6;
        testScenario.adjustmentFactorNumerator = 25.5e6;
        testScenario.adjustmentFactorDenominator = 1e18;
        testScenario.token0 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        testScenario.token1 = address(new TestToken("USD Coin", "USDC", 6));
        testScenario.conversionRate = 255;
        testScenario.conversionRateDecimals = 1;
        testScenario.subsequentValues.account0LPTokensOwed = 1625000.016250000162500002e18;
        testScenario.subsequentValues.account1LPTokensOwed = 374999.983749999837499998e18;
        testScenario.subsequentValues.account0RemainingToken0Balance = 7.549019607843137256e18;
        testScenario.subsequentValues.account1RemainingToken0Balance = 4.529411764705882354e18;
        testScenario.subsequentValues.account0RemainingToken1Balance = 0;
        testScenario.subsequentValues.account1RemainingToken1Balance = 0;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenario.subsequentValues.account0LPTokensOwed += _lpTokensDust_subsequent(testScenario);
        testScenariosCount++;
    }

    function _initializeTestScenario_account1DepositsLessThanMinimumToken0() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.id = vm.toString(testScenariosCount);
        testScenario.account0Token0Deposit = 1e12;
        testScenario.account0Token1Deposit = 50e6;
        testScenario.account1Token0Deposit = liquidityDeployer.getMinConvertibleToken0Amount() - 1;
        testScenario.account1Token1Deposit = 0;
        testScenario.account0Token0Deployable = 1e12;
        testScenario.account1Token0Deployable = 0;
        testScenario.account0Token1Deployable = 25;
        testScenario.account1Token1Deployable = 0;
        testScenario.lastToken0DeployedLiquidity = 1e12;
        testScenario.lastToken1DeployedLiquidity = 25;
        testScenario.account0LPTokensOwed = MINTED_LP_TOKENS;
        testScenario.account1LPTokensOwed = 0;
        testScenario.account0RemainingToken0Balance = 0;
        testScenario.account1RemainingToken0Balance = liquidityDeployer.getMinConvertibleToken0Amount() - 1;
        testScenario.account0RemainingToken1Balance = 49.999975e6;
        testScenario.account1RemainingToken1Balance = 0;
        testScenario.lastToken0AvailableLiquidity = 1e12;
        testScenario.lastToken1AvailableLiquidity = 50e6;
        testScenario.adjustmentFactorNumerator = 25.5e6;
        testScenario.adjustmentFactorDenominator = 1e18;
        testScenario.token0 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        testScenario.token1 = address(new TestToken("USD Coin", "USDC", 6));
        testScenario.conversionRate = 255;
        testScenario.conversionRateDecimals = 1;
        testScenario.subsequentValues.account0LPTokensOwed = 1962962.962962962962962962e18;
        testScenario.subsequentValues.account1LPTokensOwed = 18518.518518518518518518e18;
        testScenario.subsequentValues.account0RemainingToken0Balance = 0;
        testScenario.subsequentValues.account1RemainingToken0Balance = 0;
        testScenario.subsequentValues.account0RemainingToken1Balance = 99.999948e6;
        testScenario.subsequentValues.account1RemainingToken1Balance = 0;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenario.subsequentValues.account0LPTokensOwed += _lpTokensDust_subsequent(testScenario);
        testScenariosCount++;
    }

    function _initializeTestScenario_accountsDepositBothTokens_minimumTokenValues() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.id = vm.toString(testScenariosCount);
        testScenario.account0Token0Deposit = liquidityDeployer.getMinConvertibleToken0Amount();
        testScenario.account0Token1Deposit = 0;
        testScenario.account1Token0Deposit = 0;
        testScenario.account1Token1Deposit = 1;
        testScenario.account0Token0Deployable = liquidityDeployer.getMinConvertibleToken0Amount();
        testScenario.account1Token0Deployable = 0;
        testScenario.account0Token1Deployable = 0;
        testScenario.account1Token1Deployable = 1;
        testScenario.lastToken0DeployedLiquidity = liquidityDeployer.getMinConvertibleToken0Amount();
        testScenario.lastToken1DeployedLiquidity = 1;
        testScenario.account0LPTokensOwed = MINTED_LP_TOKENS / 2;
        testScenario.account1LPTokensOwed = MINTED_LP_TOKENS / 2;
        testScenario.account0RemainingToken0Balance = 0;
        testScenario.account1RemainingToken0Balance = 0;
        testScenario.account0RemainingToken1Balance = 0;
        testScenario.account1RemainingToken1Balance = 0;
        testScenario.lastToken0AvailableLiquidity = liquidityDeployer.getMinConvertibleToken0Amount();
        testScenario.lastToken1AvailableLiquidity = 1;
        testScenario.adjustmentFactorNumerator = 25.5e6;
        testScenario.adjustmentFactorDenominator = 1e18;
        testScenario.token0 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        testScenario.token1 = address(new TestToken("USD Coin", "USDC", 6));
        testScenario.conversionRate = 255;
        testScenario.conversionRateDecimals = 1;
        testScenario.subsequentValues.account0LPTokensOwed = MINTED_LP_TOKENS;
        testScenario.subsequentValues.account1LPTokensOwed = MINTED_LP_TOKENS;
        testScenario.subsequentValues.account0RemainingToken0Balance = 0;
        testScenario.subsequentValues.account1RemainingToken0Balance = 0;
        testScenario.subsequentValues.account0RemainingToken1Balance = 0;
        testScenario.subsequentValues.account1RemainingToken1Balance = 0;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenario.subsequentValues.account0LPTokensOwed += _lpTokensDust_subsequent(testScenario);
        testScenariosCount++;
    }

    function _initializeTestScenario_subunitConversionRate() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.id = vm.toString(testScenariosCount);
        testScenario.account0Token0Deposit = 50000e18;
        testScenario.account0Token1Deposit = 5e6;
        testScenario.account1Token0Deposit = 30000e18;
        testScenario.account1Token1Deposit = 10e6;
        testScenario.account0Token0Deployable = 50000e18;
        testScenario.account1Token0Deployable = 30000e18;
        testScenario.account0Token1Deployable = 2.666666e6;
        testScenario.account1Token1Deployable = 5.333333e6;
        testScenario.lastToken0DeployedLiquidity = 80000e18;
        testScenario.lastToken1DeployedLiquidity = 8e6;
        testScenario.account0LPTokensOwed = 479166.625e18;
        testScenario.account1LPTokensOwed = 520833.3125e18;
        testScenario.account0RemainingToken0Balance = 0;
        testScenario.account1RemainingToken0Balance = 0;
        testScenario.account0RemainingToken1Balance = 2.333334e6;
        testScenario.account1RemainingToken1Balance = 4.666667e6;
        testScenario.lastToken0AvailableLiquidity = 80000e18;
        testScenario.lastToken1AvailableLiquidity = 15e6;
        testScenario.adjustmentFactorNumerator = 0.0001e6;
        testScenario.adjustmentFactorDenominator = 1e18;
        testScenario.token0 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        testScenario.token1 = address(new TestToken("USD Coin", "USDC", 6));
        testScenario.conversionRate = 1;
        testScenario.conversionRateDecimals = 4;
        testScenario.subsequentValues.account0LPTokensOwed = 958333.25e18;
        testScenario.subsequentValues.account1LPTokensOwed = 1041666.625e18;
        testScenario.subsequentValues.account0RemainingToken0Balance = 0;
        testScenario.subsequentValues.account1RemainingToken0Balance = 0;
        testScenario.subsequentValues.account0RemainingToken1Balance = 4.666668e6;
        testScenario.subsequentValues.account1RemainingToken1Balance = 9.333334e6;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenario.subsequentValues.account0LPTokensOwed += _lpTokensDust_subsequent(testScenario);
        testScenariosCount++;
    }

    function _initializeTestScenario_switchToken0WithToken1() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.id = vm.toString(testScenariosCount);
        testScenario.account0Token0Deposit = 5e6;
        testScenario.account0Token1Deposit = 50000e18;
        testScenario.account1Token0Deposit = 10e6;
        testScenario.account1Token1Deposit = 30000e18;
        testScenario.account0Token0Deployable = 2.666666e6;
        testScenario.account1Token0Deployable = 5.333333e6;
        testScenario.account0Token1Deployable = 50000e18;
        testScenario.account1Token1Deployable = 30000e18;
        testScenario.lastToken0DeployedLiquidity = 8e6;
        testScenario.lastToken1DeployedLiquidity = 80000e18;
        testScenario.account0LPTokensOwed = 479166.625e18;
        testScenario.account1LPTokensOwed = 520833.3125e18;
        testScenario.account0RemainingToken0Balance = 2.333334e6;
        testScenario.account1RemainingToken0Balance = 4.666667e6;
        testScenario.account0RemainingToken1Balance = 0;
        testScenario.account1RemainingToken1Balance = 0;
        testScenario.lastToken0AvailableLiquidity = 15e6;
        testScenario.lastToken1AvailableLiquidity = 80000e18;
        testScenario.adjustmentFactorNumerator = 10000e18;
        testScenario.adjustmentFactorDenominator = 1e6;
        testScenario.token0 = address(new TestToken("USD Coin", "USDC", 6));
        testScenario.token1 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        testScenario.conversionRate = 1e4;
        testScenario.conversionRateDecimals = 0;
        testScenario.subsequentValues.account0LPTokensOwed = 958333.25e18;
        testScenario.subsequentValues.account1LPTokensOwed = 1041666.625e18;
        testScenario.subsequentValues.account0RemainingToken0Balance = 4.666668e6;
        testScenario.subsequentValues.account1RemainingToken0Balance = 9.333334e6;
        testScenario.subsequentValues.account0RemainingToken1Balance = 0;
        testScenario.subsequentValues.account1RemainingToken1Balance = 0;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenario.subsequentValues.account0LPTokensOwed += _lpTokensDust_subsequent(testScenario);
        testScenariosCount++;
    }

    function _initializeTestScenario_tokensWithEqualDecimals() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.id = vm.toString(testScenariosCount);
        testScenario.account0Token0Deposit = 50000e18;
        testScenario.account0Token1Deposit = 5e18;
        testScenario.account1Token0Deposit = 30000e18;
        testScenario.account1Token1Deposit = 10e18;
        testScenario.account0Token0Deployable = 50000e18;
        testScenario.account1Token0Deployable = 30000e18;
        testScenario.account0Token1Deployable = 2.666666666666666666e18;
        testScenario.account1Token1Deployable = 5.333333333333333333e18;
        testScenario.lastToken0DeployedLiquidity = 80000e18;
        testScenario.lastToken1DeployedLiquidity = 8e18;
        testScenario.account0LPTokensOwed = 479166.666666666666625e18;
        testScenario.account1LPTokensOwed = 520833.3333333333333125e18;
        testScenario.account0RemainingToken0Balance = 0;
        testScenario.account1RemainingToken0Balance = 0;
        testScenario.account0RemainingToken1Balance = 2.333333333333333334e18;
        testScenario.account1RemainingToken1Balance = 4.666666666666666667e18;
        testScenario.lastToken0AvailableLiquidity = 80000e18;
        testScenario.lastToken1AvailableLiquidity = 15e18;
        testScenario.adjustmentFactorNumerator = 0.0001e18;
        testScenario.adjustmentFactorDenominator = 1e18;
        testScenario.token0 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        testScenario.token1 = address(new TestToken("USD Coin", "USDC", 18));
        testScenario.conversionRate = 1;
        testScenario.conversionRateDecimals = 4;
        testScenario.subsequentValues.account0LPTokensOwed = 958333.33333333333325e18;
        testScenario.subsequentValues.account1LPTokensOwed = 1041666.666666666666625e18;
        testScenario.subsequentValues.account0RemainingToken0Balance = 0;
        testScenario.subsequentValues.account1RemainingToken0Balance = 0;
        testScenario.subsequentValues.account0RemainingToken1Balance = 4.666666666666666668e18;
        testScenario.subsequentValues.account1RemainingToken1Balance = 9.333333333333333334e18;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenario.subsequentValues.account0LPTokensOwed += _lpTokensDust_subsequent(testScenario);
        testScenariosCount++;
    }

    function _lpTokensDust(TestDataTypes.TestScenario storage testScenario) private view returns (uint) {
        return MINTED_LP_TOKENS - testScenario.account0LPTokensOwed - testScenario.account1LPTokensOwed;
    }

    function _lpTokensDust_subsequent(TestDataTypes.TestScenario storage testScenario)
        private
        view
        returns (uint)
    {
        return
            MINTED_LP_TOKENS -
            (testScenario.subsequentValues.account0LPTokensOwed - testScenario.account0LPTokensOwed) -
            (testScenario.subsequentValues.account1LPTokensOwed - testScenario.account1LPTokensOwed);
    }

    function _runWithTestScenarios(function(TestDataTypes.TestScenario storage) test) internal {
        for (uint i = 0; i < testScenariosCount; i++) {
            TestDataTypes.TestScenario storage testScenario = testScenarios[i];
            uint snapshotId = vm.snapshot();
            _init(
                testScenario.token0,
                testScenario.token1,
                testScenario.conversionRate,
                testScenario.conversionRateDecimals,
                testScenario.adjustmentFactorNumerator
            );
            test(testScenario);
            vm.revertTo(snapshotId);
        }
    }

    function _testDeployLiquidity_lastAvailableLiquidity(TestDataTypes.TestScenario storage testScenario)
        internal
    {
        _doDeposits(testScenario);

        liquidityDeployer.deployLiquidity();

        assertEq(
            liquidityDeployer.getLastToken0AvailableLiquidity(),
            testScenario.lastToken0AvailableLiquidity
        );
        assertEq(
            liquidityDeployer.getLastToken1AvailableLiquidity(),
            testScenario.lastToken1AvailableLiquidity
        );
    }

    function _testDeployLiquidity_lastGammaAdjustmentFactor(TestDataTypes.TestScenario storage testScenario)
        internal
    {
        _doDeposits(testScenario);

        liquidityDeployer.deployLiquidity();

        (uint numerator, uint denominator) = liquidityDeployer.getLastGammaAdjustmentFactor();

        assertEq(numerator, testScenario.adjustmentFactorNumerator);

        assertEq(denominator, testScenario.adjustmentFactorDenominator);
    }

    function _testDeployLiquidity_lastDeployableLiquidity(TestDataTypes.TestScenario storage testScenario)
        internal
    {
        _doDeposits(testScenario);

        liquidityDeployer.deployLiquidity();

        assertEq(
            liquidityDeployer.getLastToken0LiquidityDeployed(testAccount0),
            testScenario.account0Token0Deployable
        );
        assertEq(
            liquidityDeployer.getLastToken0LiquidityDeployed(testAccount1),
            testScenario.account1Token0Deployable
        );
        assertEq(
            liquidityDeployer.getLastToken1LiquidityDeployed(testAccount0),
            testScenario.account0Token1Deployable
        );
        assertEq(
            liquidityDeployer.getLastToken1LiquidityDeployed(testAccount1),
            testScenario.account1Token1Deployable
        );
    }

    function _testDeployLiquidity_lastTotalDeployedLiquidity(TestDataTypes.TestScenario storage testScenario)
        internal
    {
        _doDeposits(testScenario);

        liquidityDeployer.deployLiquidity();

        (uint lastToken0DeployedLiquidity, uint lastToken1DeployedLiquidity) = liquidityDeployer
            .getLastTotalDeployedLiquidity();

        assertEq(lastToken0DeployedLiquidity, testScenario.lastToken0DeployedLiquidity);
        assertEq(lastToken1DeployedLiquidity, testScenario.lastToken1DeployedLiquidity);
    }

    function _testDeployLiquidity_approvesGammaVaultToSpendDeployableTokens(
        TestDataTypes.TestScenario storage testScenario
    ) internal {
        _doDeposits(testScenario);

        liquidityDeployer.deployLiquidity();

        assertEq(
            IERC20(token0).allowance(address(liquidityDeployer), address(lpToken)),
            testScenario.lastToken0DeployedLiquidity
        );
        assertEq(
            IERC20(token1).allowance(address(liquidityDeployer), address(lpToken)),
            testScenario.lastToken1DeployedLiquidity
        );
    }

    function _testDeployLiquidity_calls_UniProxy_deposit(TestDataTypes.TestScenario storage testScenario)
        internal
    {
        _doDeposits(testScenario);

        _expectDepositIsCalledOnUniProxy(
            testScenario.lastToken0DeployedLiquidity,
            testScenario.lastToken1DeployedLiquidity,
            address(liquidityDeployer),
            address(lpToken)
        );
        liquidityDeployer.deployLiquidity();
    }

    function _testDeployLiquidity_computesHowMuchEachLiquidityProviderIsOwed(
        TestDataTypes.TestScenario storage testScenario
    ) internal {
        _doDeposits(testScenario);

        liquidityDeployer.deployLiquidity();

        uint user0LPTokens = liquidityDeployer.getLPTokensOwed(testAccount0);
        uint user1LPTokens = liquidityDeployer.getLPTokensOwed(testAccount1);

        assertEq(
            user0LPTokens,
            testScenario.account0LPTokensOwed,
            string.concat("User0 LP tokens are incorrect. Test scenario: ", testScenario.id)
        );
        assertEq(
            user1LPTokens,
            testScenario.account1LPTokensOwed,
            string.concat("User1 LP tokens are incorrect. Test scenario: ", testScenario.id)
        );
        assertEq(
            user0LPTokens + user1LPTokens,
            MINTED_LP_TOKENS,
            string.concat("Total LP tokens are incorrect. Test scenario: ", testScenario.id)
        );
    }

    function _testDeployLiquidity_updatesUserTokenBalances(TestDataTypes.TestScenario storage testScenario)
        internal
    {
        _doDeposits(testScenario);

        liquidityDeployer.deployLiquidity();

        assertEq(
            liquidityDeployer.token0BalanceOf(testAccount0),
            testScenario.account0RemainingToken0Balance
        );
        assertEq(
            liquidityDeployer.token0BalanceOf(testAccount1),
            testScenario.account1RemainingToken0Balance
        );
        assertEq(
            liquidityDeployer.token1BalanceOf(testAccount0),
            testScenario.account0RemainingToken1Balance
        );
        assertEq(
            liquidityDeployer.token1BalanceOf(testAccount1),
            testScenario.account1RemainingToken1Balance
        );
    }

    function _testDeployLiquidity_updatesTotalDeposits(TestDataTypes.TestScenario storage testScenario)
        internal
    {
        _doDeposits(testScenario);

        liquidityDeployer.deployLiquidity();

        (uint token0TotalDeposits, uint token1TotalDeposits) = liquidityDeployer.getTotalDeposits();

        assertEq(
            token0TotalDeposits,
            testScenario.account0Token0Deposit +
                testScenario.account1Token0Deposit -
                testScenario.account0Token0Deployable -
                testScenario.account1Token0Deployable
        );

        assertEq(
            token1TotalDeposits,
            testScenario.account0Token1Deposit +
                testScenario.account1Token1Deposit -
                testScenario.account0Token1Deployable -
                testScenario.account1Token1Deployable
        );
    }

    function _testDeployLiquidity_token0DeployedLiquidityIsCloseInValueToToken1DeployedLiquidity(
        TestDataTypes.TestScenario storage testScenario
    ) internal {
        _doDeposits(testScenario);
        liquidityDeployer.deployLiquidity();

        (uint lastToken0DeployedLiquidity, uint lastToken1DeployedLiquidity) = liquidityDeployer
            .getLastTotalDeployedLiquidity();

        uint8 token0Decimals = TestToken(token0).decimals();
        uint8 token1Decimals = TestToken(token1).decimals();

        uint lastToken0DeployedLiquidityInToken1 = LiquidityDeployerMath.convertTokenValue(
            token0Decimals,
            token1Decimals,
            testScenario.conversionRate,
            testScenario.conversionRateDecimals,
            lastToken0DeployedLiquidity
        );

        assertApproxEqRel(
            lastToken0DeployedLiquidityInToken1,
            lastToken1DeployedLiquidity,
            0.0000002e18 // 0.0000002% error
        );
    }

    function _testDeployLiquidity_subsequentCall(TestDataTypes.TestScenario storage testScenario) internal {
        _doDeposits(testScenario);
        liquidityDeployer.deployLiquidity();

        uint token0AvailableLiquidity = _computeToken0AvailableLiquidity(
            testScenario.account0RemainingToken0Balance
        ) + _computeToken0AvailableLiquidity(testScenario.account1RemainingToken0Balance);
        _expectRevert_NotEnoughAvailableLiquidity(
            token0AvailableLiquidity,
            testScenario.account0RemainingToken1Balance + testScenario.account1RemainingToken1Balance
        );
        liquidityDeployer.deployLiquidity();

        lpToken.mint(address(liquidityDeployer), INITIAL_TOKEN_BALANCE);
        _doDeposits(testScenario);
        liquidityDeployer.deployLiquidity();

        uint user0LPTokens = liquidityDeployer.getLPTokensOwed(testAccount0);
        uint user1LPTokens = liquidityDeployer.getLPTokensOwed(testAccount1);

        assertEq(
            user0LPTokens,
            testScenario.subsequentValues.account0LPTokensOwed,
            string.concat("User0 LP tokens are incorrect. Test scenario: ", testScenario.id)
        );
        assertEq(
            user1LPTokens,
            testScenario.subsequentValues.account1LPTokensOwed,
            string.concat("User1 LP tokens are incorrect. Test scenario: ", testScenario.id)
        );
        assertEq(
            user0LPTokens + user1LPTokens,
            MINTED_LP_TOKENS * 2,
            string.concat("Total LP tokens are incorrect. Test scenario: ", testScenario.id)
        );

        assertEq(
            liquidityDeployer.token0BalanceOf(testAccount0),
            testScenario.subsequentValues.account0RemainingToken0Balance,
            string.concat("User0 token0 balance is incorrect. Test scenario: ", testScenario.id)
        );
        assertEq(
            liquidityDeployer.token0BalanceOf(testAccount1),
            testScenario.subsequentValues.account1RemainingToken0Balance,
            string.concat("User1 token0 balance is incorrect. Test scenario: ", testScenario.id)
        );
        assertEq(
            liquidityDeployer.token1BalanceOf(testAccount0),
            testScenario.subsequentValues.account0RemainingToken1Balance,
            string.concat("User0 token1 balance is incorrect. Test scenario: ", testScenario.id)
        );
        assertEq(
            liquidityDeployer.token1BalanceOf(testAccount1),
            testScenario.subsequentValues.account1RemainingToken1Balance,
            string.concat("User1 token1 balance is incorrect. Test scenario: ", testScenario.id)
        );
    }

    function _testWithdrawLpTokens_decreasesLpTokensOwedToUser(
        TestDataTypes.TestScenario storage testScenario
    ) internal {
        _doDeposits(testScenario);
        liquidityDeployer.deployLiquidity();

        if (testScenario.account0LPTokensOwed > 0) {
            liquidityDeployer.withdrawLpTokens(testScenario.account0LPTokensOwed);
        }

        if (testScenario.account1LPTokensOwed > 0) {
            vm.prank(testAccount1);
            liquidityDeployer.withdrawLpTokens(testScenario.account1LPTokensOwed);
        }

        assertEq(liquidityDeployer.getLPTokensOwed(testAccount0), 0);
        assertEq(liquidityDeployer.getLPTokensOwed(testAccount1), 0);
    }

    function _testWithdrawLpTokens_transfersLpTokensToUser(TestDataTypes.TestScenario storage testScenario)
        internal
    {
        _doDeposits(testScenario);
        liquidityDeployer.deployLiquidity();

        if (testScenario.account0LPTokensOwed > 0) {
            liquidityDeployer.withdrawLpTokens(testScenario.account0LPTokensOwed);
        }

        if (testScenario.account1LPTokensOwed > 0) {
            vm.prank(testAccount1);
            liquidityDeployer.withdrawLpTokens(testScenario.account1LPTokensOwed);
        }

        assertEq(lpToken.balanceOf(testAccount0), testScenario.account0LPTokensOwed);
        assertEq(lpToken.balanceOf(testAccount1), testScenario.account1LPTokensOwed);
    }

    function _testWithdrawLpTokens_emitsWithdrawEvent(TestDataTypes.TestScenario storage testScenario)
        internal
    {
        _doDeposits(testScenario);
        liquidityDeployer.deployLiquidity();

        if (testScenario.account0LPTokensOwed > 0) {
            _expectEmit_LpTokenWithdrawn(address(this), testScenario.account0LPTokensOwed);
            liquidityDeployer.withdrawLpTokens(testScenario.account0LPTokensOwed);
        }

        if (testScenario.account1LPTokensOwed > 0) {
            vm.prank(testAccount1);
            _expectEmit_LpTokenWithdrawn(testAccount1, testScenario.account1LPTokensOwed);
            liquidityDeployer.withdrawLpTokens(testScenario.account1LPTokensOwed);
        }
    }

    function _testWithdrawLpTokens_subsequentCall(TestDataTypes.TestScenario storage testScenario) internal {
        _doDeposits(testScenario);
        liquidityDeployer.deployLiquidity();

        uint account0Withdraw1;
        uint account1Withdraw1;

        if (testScenario.account0LPTokensOwed > 0) {
            account0Withdraw1 = testScenario.account0LPTokensOwed / 2;
            liquidityDeployer.withdrawLpTokens(account0Withdraw1);
        }

        if (testScenario.account1LPTokensOwed > 0) {
            account1Withdraw1 = testScenario.account1LPTokensOwed / 2;
            vm.prank(testAccount1);
            liquidityDeployer.withdrawLpTokens(account1Withdraw1);
        }

        lpToken.mint(address(liquidityDeployer), INITIAL_TOKEN_BALANCE);
        _doDeposits(testScenario);
        liquidityDeployer.deployLiquidity();

        if (testScenario.subsequentValues.account0LPTokensOwed > 0) {
            liquidityDeployer.withdrawLpTokens(
                testScenario.subsequentValues.account0LPTokensOwed - account0Withdraw1
            );
        }

        if (testScenario.subsequentValues.account1LPTokensOwed > 0) {
            vm.prank(testAccount1);
            liquidityDeployer.withdrawLpTokens(
                testScenario.subsequentValues.account1LPTokensOwed - account1Withdraw1
            );
        }

        assertEq(liquidityDeployer.getLPTokensOwed(testAccount0), 0);
        assertEq(liquidityDeployer.getLPTokensOwed(testAccount1), 0);

        assertEq(lpToken.balanceOf(testAccount0), testScenario.subsequentValues.account0LPTokensOwed);
        assertEq(lpToken.balanceOf(testAccount1), testScenario.subsequentValues.account1LPTokensOwed);
    }

    function _testDeployLiquidity_emitsEvent(TestDataTypes.TestScenario storage testScenario) internal {
        _doDeposits(testScenario);

        _expectEmit_LiquidityDeployed(
            testScenario.lastToken0DeployedLiquidity,
            testScenario.lastToken1DeployedLiquidity,
            MINTED_LP_TOKENS
        );
        liquidityDeployer.deployLiquidity();
    }

    function _computeToken0AvailableLiquidity(uint token0Amount) private view returns (uint) {
        return token0Amount > liquidityDeployer.getMinConvertibleToken0Amount() ? token0Amount : 0;
    }
}
