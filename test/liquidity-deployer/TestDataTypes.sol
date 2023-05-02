// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

contract TestDataTypes {
    struct TestScenario {
        string id;
        uint account0Token0Deposit;
        uint account0Token1Deposit;
        uint account1Token0Deposit;
        uint account1Token1Deposit;
        uint account0Token0Deployable;
        uint account1Token0Deployable;
        uint account0Token1Deployable;
        uint account1Token1Deployable;
        uint lastToken0DeployedLiquidity;
        uint lastToken1DeployedLiquidity;
        uint account0LPTokensOwed;
        uint account1LPTokensOwed;
        uint account0RemainingToken0Balance;
        uint account1RemainingToken0Balance;
        uint account0RemainingToken1Balance;
        uint account1RemainingToken1Balance;
        uint lastToken0AvailableLiquidity;
        uint lastToken1AvailableLiquidity;
        uint adjustmentFactorNumerator; // token1 amount out
        uint adjustmentFactorDenominator; // token0 amount in
        address token0;
        address token1;
        uint conversionRate;
        uint8 conversionRateDecimals;
        SubsequentValues subsequentValues;
    }

    /// @dev values obtained after two `deposit() + deployLiquidity()` calls
    struct SubsequentValues {
        uint account0LPTokensOwed;
        uint account1LPTokensOwed;
        uint account0RemainingToken0Balance;
        uint account1RemainingToken0Balance;
        uint account0RemainingToken1Balance;
        uint account1RemainingToken1Balance;
    }
}
