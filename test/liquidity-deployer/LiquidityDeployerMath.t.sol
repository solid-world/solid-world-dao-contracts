// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/libraries/liquidity-deployer/LiquidityDeployerMath.sol";
import "../../contracts/libraries/liquidity-deployer/LiquidityDeployerDataTypes.sol";

contract LiquidityDeployerMathTest is BaseTest {
    function testConvertTokenDecimals_revertsIfConvertedValueIs0() public {
        uint token0Decimals = 18;
        uint token1Decimals = 6;
        uint token0Amount = 0.9999999e12; //1e12 is the minimum amount of token0 that can be converted to token1

        _expectRevert_TokenAmountTooSmall(token0Amount);
        LiquidityDeployerMath.convertTokenDecimals(token0Decimals, token1Decimals, token0Amount);
    }

    function testConvertTokenDecimals() public {
        uint token0Decimals = 18;
        uint token1Decimals = 6;

        assertEq(LiquidityDeployerMath.convertTokenDecimals(token0Decimals, token1Decimals, 1e12), 1);
        assertEq(LiquidityDeployerMath.convertTokenDecimals(token0Decimals, token1Decimals, 100e18), 100e6);
    }

    function testConvertTokenValue_revertsIfConvertedValueIs0() public {
        uint token0Decimals = 18;
        uint token1Decimals = 6;
        uint conversionRate = 1;
        uint conversionRateDecimals = 2;
        uint token0Amount = 1e12;

        _expectRevert_TokenAmountTooSmall(token0Amount);
        LiquidityDeployerMath.convertTokenValue(
            token0Decimals,
            token1Decimals,
            conversionRate,
            conversionRateDecimals,
            token0Amount
        );
    }

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

    function testAdjustTokenAmount_revertsForInvalidAdjustmentFactor() public {
        uint amount = 100;
        LiquidityDeployerDataTypes.AdjustmentFactor memory adjustmentFactor = LiquidityDeployerDataTypes
            .AdjustmentFactor({ numerator: 1, denominator: 0 });

        vm.expectRevert(abi.encodeWithSelector(LiquidityDeployerMath.InvalidAdjustmentFactor.selector, 1, 0));
        LiquidityDeployerMath.adjustTokenAmount(amount, adjustmentFactor);
    }

    function testAdjustTokenAmount_neutralAdjustmentFactor() public {
        uint amount = 100;
        LiquidityDeployerDataTypes.AdjustmentFactor memory adjustmentFactor = LiquidityDeployerDataTypes
            .AdjustmentFactor({ numerator: 1, denominator: 1 });

        assertEq(LiquidityDeployerMath.adjustTokenAmount(amount, adjustmentFactor), amount);
    }

    function testAdjustTokenAmount() public {
        uint amount = 100;
        LiquidityDeployerDataTypes.AdjustmentFactor memory adjustmentFactor = LiquidityDeployerDataTypes
            .AdjustmentFactor({ numerator: 2, denominator: 3 });

        assertEq(LiquidityDeployerMath.adjustTokenAmount(amount, adjustmentFactor), 66);
    }

    function _expectRevert_TokenAmountTooSmall(uint amount) internal {
        vm.expectRevert(abi.encodeWithSelector(LiquidityDeployerMath.TokenAmountTooSmall.selector, amount));
    }
}
