// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/libraries/liquidity-deployer/LiquidityDeployerMath.sol";

contract LiquidityDeployerMathTest is BaseTest {
    function testConvertToken0DecimalsToToken1_revertsIfConvertedValueIs0() public {
        uint token0Decimals = 18;
        uint token1Decimals = 6;
        uint token0Amount = 0.9999999e12; //1e12 is the minimum amount of token0 that can be converted to token1

        _expectRevert_Token0AmountTooSmall(token0Amount);
        LiquidityDeployerMath.convertToken0DecimalsToToken1(token0Decimals, token1Decimals, token0Amount);
    }

    function testConvertToken0DecimalsToToken1() public {
        uint token0Decimals = 18;
        uint token1Decimals = 6;

        assertEq(
            LiquidityDeployerMath.convertToken0DecimalsToToken1(token0Decimals, token1Decimals, 1e12),
            1
        );
        assertEq(
            LiquidityDeployerMath.convertToken0DecimalsToToken1(token0Decimals, token1Decimals, 100e18),
            100e6
        );
    }

    function testConvertToken0ValueToToken1_revertsIfConvertedValueIs0() public {
        uint token0Decimals = 18;
        uint token1Decimals = 6;
        uint conversionRate = 1;
        uint conversionRateDecimals = 2;
        uint token0Amount = 1e12;

        _expectRevert_Token0AmountTooSmall(token0Amount);
        LiquidityDeployerMath.convertToken0ValueToToken1(
            token0Decimals,
            token1Decimals,
            conversionRate,
            conversionRateDecimals,
            token0Amount
        );
    }

    function testConvertToken0ValueToToken1() public {
        uint token0Decimals = 18;
        uint token1Decimals = 6;
        uint conversionRate = 255;
        uint conversionRateDecimals = 1;

        assertEq(
            LiquidityDeployerMath.convertToken0ValueToToken1(
                token0Decimals,
                token1Decimals,
                conversionRate,
                conversionRateDecimals,
                1e12
            ),
            25
        );
        assertEq(
            LiquidityDeployerMath.convertToken0ValueToToken1(
                token0Decimals,
                token1Decimals,
                conversionRate,
                conversionRateDecimals,
                100e18
            ),
            2550e6
        );
    }

    function _expectRevert_Token0AmountTooSmall(uint amount) internal {
        vm.expectRevert(abi.encodeWithSelector(LiquidityDeployerMath.Token0AmountTooSmall.selector, amount));
    }
}
