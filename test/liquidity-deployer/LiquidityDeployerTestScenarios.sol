// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseLiquidityDeployer.t.sol";

contract LiquidityDeployerTestScenarios is BaseLiquidityDeployerTest {
    mapping(uint => TestDataTypes.TestScenario) testScenarios;
    uint testScenariosCount;

    function setUp() public override {
        super.setUp();

        _initializeTestScenarios();
    }

    function _initializeTestScenarios() private {
        _initializeTestScenario0();
        _initializeTestScenario1();
        _initializeTestScenario2();
        //        _initializeTestScenario3();
    }

    function _initializeTestScenario0() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.account0Token0Deposit = 5e18;
        testScenario.account0Token1Deposit = 50e6;
        testScenario.account1Token0Deposit = 3e18;
        testScenario.account1Token1Deposit = 100e6;
        testScenario.account0Token0Deployable = 3.676470588235294117e18;
        testScenario.account1Token0Deployable = 2.205882352941176470e18;
        testScenario.account0Token1Deployable = 50e6;
        testScenario.account1Token1Deployable = 100e6;
        testScenario.lastToken0DeployedLiquidity = 5.882352941176470587e18;
        testScenario.lastToken1DeployedLiquidity = 150e6;
        testScenario.account0LPTokensOwed = 479166.664930555549768518e18;
        testScenario.account1LPTokensOwed = 520833.331736111105787037e18;
        testScenario.account0RemainingToken0Balance = 1.323529411764705883e18;
        testScenario.account1RemainingToken0Balance = 0.79411764705882353e18;
        testScenario.account0RemainingToken1Balance = 0;
        testScenario.account1RemainingToken1Balance = 0;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenariosCount++;
    }

    function _initializeTestScenario1() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.account0Token0Deposit = 5e18;
        testScenario.account0Token1Deposit = 250e6;
        testScenario.account1Token0Deposit = 3e18;
        testScenario.account1Token1Deposit = 100e6;
        testScenario.account0Token0Deployable = 5e18;
        testScenario.account1Token0Deployable = 3e18;
        testScenario.account0Token1Deployable = 145.714285e6;
        testScenario.account1Token1Deployable = 58.285714e6;
        testScenario.lastToken0DeployedLiquidity = 8e18;
        testScenario.lastToken1DeployedLiquidity = 203.999999e6;
        testScenario.account0LPTokensOwed = 669642.857033438375081956e18;
        testScenario.account1LPTokensOwed = 330357.142966561624918043e18;
        testScenario.account0RemainingToken0Balance = 0;
        testScenario.account1RemainingToken0Balance = 0;
        testScenario.account0RemainingToken1Balance = 104.285715e6;
        testScenario.account1RemainingToken1Balance = 41.714286e6;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenariosCount++;
    }

    function _initializeTestScenario2() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.account0Token0Deposit = 5e18;
        testScenario.account0Token1Deposit = 50e6;
        testScenario.account1Token0Deposit = 3e18;
        testScenario.account1Token1Deposit = 0;
        testScenario.account0Token0Deployable = 1.225490196078431372e18;
        testScenario.account1Token0Deployable = 0.735294117647058823e18;
        testScenario.account0Token1Deployable = 50e6;
        testScenario.account1Token1Deployable = 0;
        testScenario.lastToken0DeployedLiquidity = 1.960784313725490195e18;
        testScenario.lastToken1DeployedLiquidity = 50e6;
        testScenario.account0LPTokensOwed = 812500.008125000081250001e18;
        testScenario.account1LPTokensOwed = 187499.991874999918749999e18;
        testScenario.account0RemainingToken0Balance = 3.774509803921568628e18;
        testScenario.account1RemainingToken0Balance = 2.264705882352941177e18;
        testScenario.account0RemainingToken1Balance = 0;
        testScenario.account1RemainingToken1Balance = 0;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenariosCount++;
    }

    function _initializeTestScenario3() private {
        TestDataTypes.TestScenario storage testScenario = testScenarios[testScenariosCount];
        testScenario.account0Token0Deposit = 1e12;
        testScenario.account0Token1Deposit = 50e6;
        testScenario.account1Token0Deposit = 0.999999999999e12;
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
        testScenario.account1RemainingToken0Balance = 0.999999999999e12;
        testScenario.account0RemainingToken1Balance = 49.999975e6;
        testScenario.account1RemainingToken1Balance = 0;

        testScenario.account0LPTokensOwed += _lpTokensDust(testScenario);
        testScenariosCount++;
    }

    function _lpTokensDust(TestDataTypes.TestScenario storage testScenario) private view returns (uint) {
        return MINTED_LP_TOKENS - testScenario.account0LPTokensOwed - testScenario.account1LPTokensOwed;
    }

    function _runWithTestScenarios(function(TestDataTypes.TestScenario storage) test) internal {
        for (uint i = 0; i < testScenariosCount; i++) {
            uint snapshotId = vm.snapshot();
            test(testScenarios[i]);
            vm.revertTo(snapshotId);
        }
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

    function _testDeployLiquidity_approvesUniProxyToSpendDeployableTokens(
        TestDataTypes.TestScenario storage testScenario
    ) internal {
        _doDeposits(testScenario);

        liquidityDeployer.deployLiquidity();

        assertEq(
            IERC20(token0).allowance(address(liquidityDeployer), address(uniProxy)),
            testScenario.lastToken0DeployedLiquidity
        );
        assertEq(
            IERC20(token1).allowance(address(liquidityDeployer), address(uniProxy)),
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
            gammaVault
        );
        liquidityDeployer.deployLiquidity();
    }

    function _testDeployLiquidity_computesHowMuchEachLiquidityProviderIsOwed(
        TestDataTypes.TestScenario storage testScenario
    ) internal {
        _doDeposits(testScenario);

        liquidityDeployer.deployLiquidity();

        uint user0LPTokens = liquidityDeployer.getLastLPTokensOwed(testAccount0);
        uint user1LPTokens = liquidityDeployer.getLastLPTokensOwed(testAccount1);

        assertEq(user0LPTokens, testScenario.account0LPTokensOwed);
        assertEq(user1LPTokens, testScenario.account1LPTokensOwed);
        assertEq(user0LPTokens + user1LPTokens, MINTED_LP_TOKENS);
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
}
