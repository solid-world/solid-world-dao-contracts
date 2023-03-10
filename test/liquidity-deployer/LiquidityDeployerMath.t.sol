// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/libraries/liquidity-deployer/LiquidityDeployerMath.sol";
import "../../contracts/libraries/liquidity-deployer/LiquidityDeployerDataTypes.sol";

contract LiquidityDeployerMathTest is BaseTest {
    function testConvertTokenValue() public {
        uint token0Decimals = 18;
        uint token1Decimals = 6;
        uint conversionRate = 255;
        uint conversionRateDecimals = 1;

        assertEq(
            LiquidityDeployerMath.convertTokenValue(
                token0Decimals,
                token1Decimals,
                conversionRate,
                conversionRateDecimals,
                1e12
            ),
            25
        );
        assertEq(
            LiquidityDeployerMath.convertTokenValue(
                token0Decimals,
                token1Decimals,
                conversionRate,
                conversionRateDecimals,
                100e18
            ),
            2550e6
        );
    }

    function testAdjustTokenAmount_revertsForInvalidFraction() public {
        uint amount = 100;
        LiquidityDeployerDataTypes.Fraction memory adjustmentFactor = LiquidityDeployerDataTypes.Fraction({
            numerator: 1,
            denominator: 0
        });

        vm.expectRevert(abi.encodeWithSelector(LiquidityDeployerMath.InvalidFraction.selector, 1, 0));
        LiquidityDeployerMath.adjustTokenAmount(amount, adjustmentFactor);
    }

    function testAdjustTokenAmount_neutralAdjustmentFactor() public {
        uint amount = 100;
        LiquidityDeployerDataTypes.Fraction memory adjustmentFactor = LiquidityDeployerDataTypes.Fraction({
            numerator: 1,
            denominator: 1
        });

        assertEq(LiquidityDeployerMath.adjustTokenAmount(amount, adjustmentFactor), amount);
    }

    function testAdjustTokenAmount() public {
        uint amount = 100;
        LiquidityDeployerDataTypes.Fraction memory adjustmentFactor = LiquidityDeployerDataTypes.Fraction({
            numerator: 2,
            denominator: 3
        });

        assertEq(LiquidityDeployerMath.adjustTokenAmount(amount, adjustmentFactor), 66);
    }
}
