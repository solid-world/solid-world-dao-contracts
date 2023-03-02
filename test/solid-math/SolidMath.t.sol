// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseSolidMath.t.sol";
import "./SolidMathWrapper.t.sol";

contract SolidMathTest is BaseSolidMathTest {
    function testComputeTimeAppreciationDiscountSingleWeek() public {
        uint certificationDate = PRESET_CURRENT_DATE + 1 weeks;

        uint actual = SolidMath.computeTimeAppreciationDiscount(PRESET_TIME_APPRECIATION, certificationDate);
        uint expected = 998_402; // js: 998402.178529

        assertEq(actual, expected);
    }

    function testComputeTimeAppreciationDiscountFewWeeks() public {
        uint certificationDate = PRESET_CURRENT_DATE + 5 weeks;

        uint actual = SolidMath.computeTimeAppreciationDiscount(PRESET_TIME_APPRECIATION, certificationDate);
        uint expected = 992_036; // js: 992036.382217

        assertEq(actual, expected);
    }

    function testComputeTimeAppreciationDiscountOneYear() public {
        uint certificationDate = PRESET_CURRENT_DATE + ONE_YEAR;

        uint actual = SolidMath.computeTimeAppreciationDiscount(PRESET_TIME_APPRECIATION, certificationDate);
        uint expected = 920_210; // js: 920210.191351

        assertEq(actual, expected);
    }

    function testComputeTimeAppreciationDiscount_fuzz(uint timeAppreciation, uint certificationDate) public {
        timeAppreciation = bound(timeAppreciation, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1);
        certificationDate = bound(
            certificationDate,
            PRESET_CURRENT_DATE,
            PRESET_CURRENT_DATE + _yearsToSeconds(50)
        );

        SolidMathWrapper wrapper = new SolidMathWrapper();
        try wrapper.computeTimeAppreciationDiscount(timeAppreciation, certificationDate) {} catch (
            bytes memory reason
        ) {
            assertEq(SolidMath.InvalidTADiscount.selector, bytes4(reason), "Fuzz test failed.");
        }
    }

    function testCollateralizationOutcome_oneWeek() public {
        (uint cbtUserCut, uint cbtDaoCut, uint cbtForfeited) = SolidMath.computeCollateralizationOutcome(
            PRESET_CURRENT_DATE + 1 weeks + 1 hours,
            10000,
            8_2300,
            COLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );

        // js:    9783871661228226000000
        // sol:   9783869200000000000000
        assertApproxEqAbs(cbtUserCut, 9783871661228226000000, 0.002462e18);
        // expected: 199670850229147480000
        // actual:   199670800000000000000
        assertApproxEqAbs(cbtDaoCut, 199670850229147480000, 0.0000503e18);
        // js:    16457488542626520000
        // sol:   16460000000000000000
        assertApproxEqAbs(cbtForfeited, 16457488542626520000, 0.00252e18);
    }

    function testCollateralizationOutcome_oneYear() public {
        (uint cbtUserCut, uint cbtDaoCut, uint cbtForfeited) = SolidMath.computeCollateralizationOutcome(
            PRESET_CURRENT_DATE + ONE_YEAR + 1 hours,
            10000,
            8_2300,
            COLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );

        // js:       8995576416018013000000
        // sol:      8995567000000000000000
        assertApproxEqAbs(cbtUserCut, 8995576416018013000000, 0.009417e18);

        // js:       183583192163632930000
        // sol:      183583000000000000000
        assertApproxEqAbs(cbtDaoCut, 183583192163632930000, 0.0001922e18);

        // js:     820840391818354000000
        // sol:    820850000000000000000
        assertApproxEqAbs(cbtForfeited, 820840391818354000000, 0.009609e18);
    }

    function testCollateralizationOutcome_tenYears() public {
        (uint cbtUserCut, uint cbtDaoCut, uint cbtForfeited) = SolidMath.computeCollateralizationOutcome(
            PRESET_CURRENT_DATE + _yearsToSeconds(10) + 1 hours,
            10000,
            8_2300,
            COLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );

        // js:       4161551663070000000000
        // sol:      4161550400000000000000
        assertApproxEqAbs(cbtUserCut, 4161551663070000000000, 0.0012631e18);

        // js:       84929625776900000000
        // sol:      84929600000000000000
        assertApproxEqAbs(cbtDaoCut, 84929625776900000000, 0.000025776900000000e18);

        // js:       5753518711160000000000
        // sol:      5753520000000000000000
        assertApproxEqAbs(cbtForfeited, 5753518711160000000000, 0.0012889e18);
    }

    function testCollateralizationOutcome_fuzz(
        uint timeAppreciation,
        uint certificationDate,
        uint inputAmount
    ) public {
        timeAppreciation = bound(timeAppreciation, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1);
        certificationDate = bound(
            certificationDate,
            PRESET_CURRENT_DATE + 1,
            PRESET_CURRENT_DATE + _yearsToSeconds(50)
        );
        inputAmount = bound(inputAmount, 0, type(uint256).max / 1e18);

        SolidMathWrapper wrapper = new SolidMathWrapper();
        try
            wrapper.computeCollateralizationOutcome(
                certificationDate,
                inputAmount,
                timeAppreciation,
                COLLATERALIZATION_FEE,
                PRESET_DECIMALS
            )
        {} catch (bytes memory reason) {
            assertEq(SolidMath.InvalidTADiscount.selector, bytes4(reason), "Fuzz test failed.");
        }
    }

    function testDecollateralizationOutcome_oneWeek() public {
        (uint cbtUserCut, uint cbtDaoCut, uint cbtToBurn) = SolidMath.computeDecollateralizationOutcome(
            PRESET_CURRENT_DATE + 1 weeks,
            10000e18,
            99_5888,
            DECOLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );

        assertEq(cbtUserCut, 10555);
        assertEq(cbtDaoCut, 500e18);
        assertEq(cbtToBurn, 9500e18);
    }

    function testDecollateralizationOutcome_oneYear() public {
        (uint amountOut, uint cbtDaoCut, uint cbtToBurn) = SolidMath.computeDecollateralizationOutcome(
            PRESET_CURRENT_DATE + ONE_YEAR + 1 hours,
            10000e18,
            8_0105,
            DECOLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );

        assertEq(amountOut, 10324); // js: 10324.8997581
        assertEq(cbtDaoCut, 500e18);
        assertEq(cbtToBurn, 9500e18);
    }

    function testDecollateralizationOutcome_tenYears() public {
        (uint amountOut, uint cbtDaoCut, uint cbtToBurn) = SolidMath.computeDecollateralizationOutcome(
            PRESET_CURRENT_DATE + _yearsToSeconds(10),
            1000e18,
            8_0105,
            DECOLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );

        assertEq(amountOut, 2184); // js: 2184.46952993
        assertEq(cbtDaoCut, 50e18);
        assertEq(cbtToBurn, 950e18);
    }

    function testDecollateralizationOutcome_fuzz(
        uint timeAppreciation,
        uint certificationDate,
        uint inputAmount
    ) public {
        timeAppreciation = bound(timeAppreciation, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1);
        certificationDate = bound(certificationDate, 1, PRESET_CURRENT_DATE + _yearsToSeconds(50));
        inputAmount = bound(inputAmount, 0, type(uint256).max / SolidMath.TIME_APPRECIATION_BASIS_POINTS);

        SolidMathWrapper wrapper = new SolidMathWrapper();
        try
            wrapper.computeDecollateralizationOutcome(
                certificationDate,
                inputAmount,
                timeAppreciation,
                DECOLLATERALIZATION_FEE,
                PRESET_DECIMALS
            )
        {} catch (bytes memory reason) {
            assertEq(SolidMath.InvalidTADiscount.selector, bytes4(reason), "Fuzz test failed.");
        }
    }

    function testComputeDecollateralizationMinAmountInAndDaoCut_oneYear() public {
        uint expectedFcbtAmount = 10324;
        (uint minAmountIn, uint minCbtDaoCut) = SolidMath.computeDecollateralizationMinAmountInAndDaoCut(
            PRESET_CURRENT_DATE + ONE_YEAR + 1 hours,
            expectedFcbtAmount,
            8_0105,
            DECOLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );

        // js result:       9999128559644928000000
        // macbook result:  9999128559600000000000
        // keisan result:   9999128559644950203259
        // solidity result: 9999120021052631578947
        // delta = 9999128559644950203259 - 9999120021052631578947 = 8538592318624312 = ~8540000000000000
        assertApproxEqAbs(minAmountIn, 9999128559644950203259, 8540000000000000);

        // js result:       499956427982246450000
        // macbook result:  499956427980000000000
        // keisan result:   499956427982247510163
        // solidity result: 499956001052631578947
        // delta = 499956427982247510163 - 499956001052631578947 = 426929615931216 = ~427000000000000
        assertApproxEqAbs(minCbtDaoCut, 499956427982247510163, 427000000000000);

        (uint amountOut, uint cbtDaoCut, uint cbtToBurn) = SolidMath.computeDecollateralizationOutcome(
            PRESET_CURRENT_DATE + ONE_YEAR + 1 hours,
            minAmountIn,
            8_0105,
            DECOLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );

        assertEq(amountOut, expectedFcbtAmount);
        assertEq(minCbtDaoCut, cbtDaoCut);
        assertEq(minAmountIn, cbtDaoCut + cbtToBurn);
    }

    function testComputeDecollateralizationMinAmountInAndDaoCut_tenYears() public {
        uint expectedFcbtAmount = 10324;
        (uint minAmountIn, uint minCbtDaoCut) = SolidMath.computeDecollateralizationMinAmountInAndDaoCut(
            PRESET_CURRENT_DATE + _yearsToSeconds(10) + 1 hours,
            expectedFcbtAmount,
            8_0105,
            DECOLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );

        // js result:        4726073221850000000000
        // sol result:       4726066383157894736842
        assertApproxEqAbs(minAmountIn, 4726073221850000000000, 0.00684e18);

        // js result:        236303661093000000000
        // sol result:       236303319157894736842
        assertApproxEqAbs(minCbtDaoCut, 236303661093000000000, 0.000342e18);

        (uint amountOut, uint cbtDaoCut, ) = SolidMath.computeDecollateralizationOutcome(
            PRESET_CURRENT_DATE + _yearsToSeconds(10) + 1 hours,
            minAmountIn,
            8_0105,
            DECOLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );

        assertEq(amountOut, expectedFcbtAmount);
        assertEq(minCbtDaoCut, cbtDaoCut);
    }

    function testComputeDecollateralizationMinAmountInAndDaoCut_tenYears_fuzz(
        uint expectedFcbtAmount,
        uint certificationDate,
        uint timeAppreciation,
        uint decollateralizationFee
    ) public {
        expectedFcbtAmount = bound(
            expectedFcbtAmount,
            0,
            type(uint256).max / 1e18 / SolidMath.FEE_BASIS_POINTS
        );
        certificationDate = bound(
            certificationDate,
            PRESET_CURRENT_DATE,
            PRESET_CURRENT_DATE + _yearsToSeconds(50)
        );
        timeAppreciation = bound(timeAppreciation, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1);
        decollateralizationFee = bound(decollateralizationFee, 1, 9900); // max 99% fee

        SolidMathWrapper wrapper = new SolidMathWrapper();

        try
            wrapper.computeDecollateralizationMinAmountInAndDaoCut(
                certificationDate,
                expectedFcbtAmount,
                timeAppreciation,
                decollateralizationFee,
                PRESET_DECIMALS
            )
        returns (uint minAmountIn, uint minCbtDaoCut) {
            try
                wrapper.computeDecollateralizationOutcome(
                    certificationDate,
                    minAmountIn,
                    timeAppreciation,
                    decollateralizationFee,
                    PRESET_DECIMALS
                )
            returns (uint amountOut, uint cbtDaoCut, uint) {
                assertEq(amountOut, expectedFcbtAmount);
                assertEq(minCbtDaoCut, cbtDaoCut);
            } catch (bytes memory reason) {
                assertEq(SolidMath.InvalidTADiscount.selector, bytes4(reason), "Fuzz test failed.");
            }
        } catch (bytes memory reason) {
            assertEq(SolidMath.InvalidTADiscount.selector, bytes4(reason), "Fuzz test failed.");
        }
    }

    function testComputeWeeklyBatchReward_batchIsCertified() public {
        (uint rewardAmount, uint feeAmount) = SolidMath.computeWeeklyBatchReward(
            PRESET_CURRENT_DATE - 1 minutes,
            10000,
            1647,
            REWARDS_FEE,
            PRESET_DECIMALS
        );

        assertEq(rewardAmount, 0);
        assertEq(feeAmount, 0);
    }

    function testComputeWeeklyBatchReward_lessThanOneWeek() public {
        (uint rewardAmount, uint feeAmount) = SolidMath.computeWeeklyBatchReward(
            PRESET_CURRENT_DATE + 1 minutes,
            10000,
            8_2359,
            REWARDS_FEE,
            PRESET_DECIMALS
        );

        assertEq(rewardAmount, 15.6465e18);
        assertEq(feeAmount, 0.8235e18);
    }

    function testComputeWeeklyBatchReward_oneWeek() public {
        (uint rewardAmount, uint feeAmount) = SolidMath.computeWeeklyBatchReward(
            PRESET_CURRENT_DATE + 1 weeks + 1 minutes,
            10000,
            8_2360,
            REWARDS_FEE,
            PRESET_DECIMALS
        );

        // js:   15620736937500000000
        // sol:  15618000000000000000
        assertApproxEqAbs(rewardAmount, 15.6207369375e18, 0.00274e18);
        // js:   822144049341000000
        // sol:  822000000000000000
        assertApproxEqAbs(feeAmount, 0.822144049341e18, 0.00014405e18);
    }

    function testComputeWeeklyBatchReward_fiveYears() public {
        (uint rewardAmount, uint feeAmount) = SolidMath.computeWeeklyBatchReward(
            PRESET_CURRENT_DATE + _yearsToSeconds(5) + 1 minutes,
            10000,
            8_2360,
            REWARDS_FEE,
            PRESET_DECIMALS
        );

        // js:   10192727432200000000
        // sol:  10193500000000000000
        assertApproxEqAbs(rewardAmount, 10.1927274322e18, 0.00077257e18);
        // js:   536459338537000000
        // sol:  536500000000000000
        assertApproxEqAbs(feeAmount, 0.536459338537e18, 0.0000407e18);
    }

    function testComputeWeeklyBatchReward_fuzz(
        uint timeAppreciation,
        uint certificationDate,
        uint availableCredits
    ) public {
        timeAppreciation = bound(timeAppreciation, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1);
        certificationDate = bound(certificationDate, 1, PRESET_CURRENT_DATE + _yearsToSeconds(50));
        availableCredits = bound(availableCredits, 0, type(uint256).max / 1e18 / SolidMath.FEE_BASIS_POINTS);

        SolidMathWrapper wrapper = new SolidMathWrapper();
        try
            wrapper.computeWeeklyBatchReward(
                certificationDate,
                availableCredits,
                timeAppreciation,
                REWARDS_FEE,
                PRESET_DECIMALS
            )
        {} catch (bytes memory reason) {
            assertEq(SolidMath.InvalidTADiscount.selector, bytes4(reason), "Fuzz test failed.");
        }
    }

    function testFailComputeCollateralizationOutcome_ifCertificationDateIsInThePast() public view {
        SolidMath.computeCollateralizationOutcome(
            PRESET_CURRENT_DATE - 1 hours,
            10000,
            1647,
            COLLATERALIZATION_FEE,
            PRESET_DECIMALS
        );
    }
}
