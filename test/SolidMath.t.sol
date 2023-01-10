pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../contracts/libraries/SolidMath.sol";

/// @notice Dummy wrapper over some SolidMath functions, such that we can make external calls to them
/// @notice and use the try/catch syntax
contract DummySolidMath {
    function computeTimeAppreciationDiscount(uint timeAppreciation, uint certificationDate)
        external
        view
        returns (uint)
    {
        return SolidMath.computeTimeAppreciationDiscount(timeAppreciation, certificationDate);
    }

    function computeCollateralizationOutcome(
        uint certificationDate,
        uint fcbtAmount,
        uint timeAppreciation,
        uint collateralizationFee,
        uint cbtDecimals
    )
        external
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return
            SolidMath.computeCollateralizationOutcome(
                certificationDate,
                fcbtAmount,
                timeAppreciation,
                collateralizationFee,
                cbtDecimals
            );
    }

    function computeDecollateralizationOutcome(
        uint certificationDate,
        uint cbtAmount,
        uint timeAppreciation,
        uint decollateralizationFee,
        uint cbtDecimals
    )
        external
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return
            SolidMath.computeDecollateralizationOutcome(
                certificationDate,
                cbtAmount,
                timeAppreciation,
                decollateralizationFee,
                cbtDecimals
            );
    }

    function computeDecollateralizationMinAmountInAndDaoCut(
        uint certificationDate,
        uint expectedFcbtAmount,
        uint timeAppreciation,
        uint decollateralizationFee,
        uint cbtDecimals
    ) external view returns (uint minAmountIn, uint minCbtDaoCut) {
        return
            SolidMath.computeDecollateralizationMinAmountInAndDaoCut(
                certificationDate,
                expectedFcbtAmount,
                timeAppreciation,
                decollateralizationFee,
                cbtDecimals
            );
    }

    function computeWeeklyBatchReward(
        uint certificationDate,
        uint availableCredits,
        uint timeAppreciation,
        uint rewardsFee,
        uint decimals
    ) external view returns (uint netRewardAmount, uint feeAmount) {
        return
            SolidMath.computeWeeklyBatchReward(
                certificationDate,
                availableCredits,
                timeAppreciation,
                rewardsFee,
                decimals
            );
    }
}

contract SolidMathTest is Test {
    uint constant COLLATERALIZATION_FEE = 200; // 2%
    uint constant DECOLLATERALIZATION_FEE = 500; // 5%
    uint constant REWARDS_FEE = 500; // 5%
    uint constant ONE_YEAR = 1 weeks * 52;
    uint constant CURRENT_DATE = 1666016743;

    function setUp() public {
        vm.warp(CURRENT_DATE);
        vm.label(vm.addr(1), "Dummy account 1");
    }

    function testWeeksBetween_endDateIsBeforeStartDate() public {
        uint endDate = CURRENT_DATE - 3 weeks;

        uint weeksBetween = SolidMath.weeksBetween(CURRENT_DATE, endDate);
        assertEq(weeksBetween, 0);
    }

    function testWeeksBetween_invalidDates() public {
        vm.expectRevert(abi.encodeWithSelector(SolidMath.IncorrectDates.selector, 0, CURRENT_DATE));
        SolidMath.weeksBetween(0, CURRENT_DATE);
    }

    function testWeeksBetweenExactTimeDifference() public {
        uint endDate = CURRENT_DATE + 3 weeks;

        uint actual = SolidMath.weeksBetween(CURRENT_DATE, endDate);
        uint expected = 3;

        assertEq(actual, expected);
    }

    function testWeeksBetweenRoughTimeDifference() public {
        uint endDate = CURRENT_DATE + 4 weeks - 1 seconds;

        uint actual = SolidMath.weeksBetween(CURRENT_DATE, endDate);
        uint expected = 3;

        assertEq(actual, expected);
    }

    function testComputeTimeAppreciationDiscountSingleWeek() public {
        uint timeAppreciation = 80_000; // 8%
        uint certificationDate = block.timestamp + 1 weeks;

        uint actual = SolidMath.computeTimeAppreciationDiscount(
            timeAppreciation,
            certificationDate
        );
        uint expected = 920_000; // 92%

        assertEq(actual, expected);
    }

    function testComputeTimeAppreciationDiscountFewWeeks() public {
        uint timeAppreciation = 80_000; // 8%
        uint certificationDate = block.timestamp + 5 weeks;

        uint actual = SolidMath.computeTimeAppreciationDiscount(
            timeAppreciation,
            certificationDate
        );
        uint expected = 659_081; // 65.90815232%

        assertEq(actual, expected);
    }

    function testComputeTimeAppreciationDiscountOneYear() public {
        uint timeAppreciation = 80_000; // 8%
        uint certificationDate = block.timestamp + ONE_YEAR;

        uint actual = SolidMath.computeTimeAppreciationDiscount(
            timeAppreciation,
            certificationDate
        );
        uint expected = 13_090; // 1.309082514%

        assertEq(actual, expected);
    }

    function testComputeTimeAppreciationDiscount_fuzz(uint timeAppreciation, uint certificationDate)
        public
    {
        timeAppreciation = bound(timeAppreciation, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1);
        certificationDate = bound(certificationDate, CURRENT_DATE, CURRENT_DATE + 50 * ONE_YEAR);

        DummySolidMath dummy = new DummySolidMath();

        try dummy.computeTimeAppreciationDiscount(timeAppreciation, certificationDate) {} catch (
            bytes memory reason
        ) {
            assertEq(SolidMath.InvalidTADiscount.selector, bytes4(reason), "Fuzz test failed.");
        }
    }

    function testCollateralizationOutcome_oneWeek() public {
        (uint cbtUserCut, uint cbtDaoCut, uint cbtForfeited) = SolidMath
            .computeCollateralizationOutcome(
                block.timestamp + 1 weeks + 1 hours,
                10000,
                1647,
                COLLATERALIZATION_FEE,
                18
            );
        assertEq(cbtUserCut, 9783859400000000000000);
        assertEq(cbtDaoCut, 199670600000000000000);
        assertEq(cbtForfeited, 16470000000000000000);
    }

    function testCollateralizationOutcome_oneYear() public {
        (uint cbtUserCut, uint cbtDaoCut, uint cbtForfeited) = SolidMath
            .computeCollateralizationOutcome(
                block.timestamp + ONE_YEAR + 1 hours,
                10000,
                1647,
                COLLATERALIZATION_FEE,
                18
            );

        // js result:       8994990221582975000000
        // macbook result:  8994990221600000000000
        // desmos result:   8994990221600000000000
        // solidity result: 8994988800000000000000
        // delta = 8994990221600000000000 - 8994988800000000000000 = 1421599999800000 = ~1430000000000000
        assertApproxEqAbs(cbtUserCut, 8994990221600000000000, 1430000000000000);

        // js result:       183571229011897580000
        // macbook result:  183571229010000000000
        // desmos result:   183571229010000000000
        // solidity result: 183571200000000000000
        // delta = 183571229010000000000 - 183571200000000000000 = 29009999987000 = ~29100000000000
        assertApproxEqAbs(cbtDaoCut, 183571229010000000000, 29100000000000);

        // js result:       821438549405127900000
        // macbook result:  821438549410000000000
        // desmos result:   821438549410000000000
        // solidity result: 821440000000000000000
        // delta = 821440000000000000000 - 821438549410000000000 = 1450590000000000 = ~1460000000000000
        assertApproxEqAbs(cbtForfeited, 821438549410000000000, 1460000000000000);
    }

    function testCollateralizationOutcome_tenYears() public {
        (uint cbtUserCut, uint cbtDaoCut, uint cbtForfeited) = SolidMath
            .computeCollateralizationOutcome(
                block.timestamp + 10 * ONE_YEAR + 1 hours,
                10000,
                1647,
                COLLATERALIZATION_FEE,
                18
            );

        // js result:       4158840593668590000000
        // macbook result:  4158840593700000000000
        // desmos result:   4158840593700000000000
        // solidity result: 4158835800000000000000
        // delta = 4158840593700000000000 - 4158835800000000000000 = 4793699999900000 = ~4800000000000000
        assertApproxEqAbs(cbtUserCut, 4158840593700000000000, 4800000000000000);

        // js result:       84874297829971300000
        // macbook result:  84874297829969190000
        // desmos result:   84874297830000000000
        // solidity result: 84874200000000000000
        // delta = 84874297830000000000 - 84874200000000000000 = 97830000000000 = ~97900000000000
        assertApproxEqAbs(cbtDaoCut, 84874297830000000000, 97900000000000);

        // js result:       5756285108501439000000
        // macbook result:  5756285108500000000000
        // desmos result:   5756285108500000000000
        // solidity result: 5756290000000000000000
        // delta = 5756290000000000000000 - 5756285108500000000000 = 4891500000000000 = ~4900000000000000
        assertApproxEqAbs(cbtForfeited, 5756290000000000000000, 4900000000000000);
    }

    function testCollateralizationOutcome_fuzz(
        uint timeAppreciation,
        uint certificationDate,
        uint inputAmount
    ) public {
        timeAppreciation = bound(timeAppreciation, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1);
        certificationDate = bound(
            certificationDate,
            CURRENT_DATE + 1,
            CURRENT_DATE + 50 * ONE_YEAR
        );
        inputAmount = bound(inputAmount, 0, type(uint256).max / 1e18);

        DummySolidMath dummy = new DummySolidMath();
        try
            dummy.computeCollateralizationOutcome(
                certificationDate,
                inputAmount,
                timeAppreciation,
                COLLATERALIZATION_FEE,
                18
            )
        {} catch (bytes memory reason) {
            assertEq(SolidMath.InvalidTADiscount.selector, bytes4(reason), "Fuzz test failed.");
        }
    }

    function testDecollateralizationOutcome_oneWeek() public {
        (uint cbtUserCut, uint cbtDaoCut, uint cbtToBurn) = SolidMath
            .computeDecollateralizationOutcome(
                block.timestamp + 1 weeks,
                10000e18,
                10_0000,
                DECOLLATERALIZATION_FEE,
                18
            );

        assertEq(cbtUserCut, 10555);
        assertEq(cbtDaoCut, 500e18);
        assertEq(cbtToBurn, 9500e18);
    }

    function testDecollateralizationOutcome_oneYear() public {
        (uint amountOut, uint cbtDaoCut, uint cbtToBurn) = SolidMath
            .computeDecollateralizationOutcome(
                block.timestamp + ONE_YEAR + 1 hours,
                10000e18,
                1600, // 0.16% weekly discount
                DECOLLATERALIZATION_FEE,
                18
            );

        assertEq(amountOut, 10324);
        assertEq(cbtDaoCut, 500e18);
        assertEq(cbtToBurn, 9500e18);
    }

    function testDecollateralizationOutcome_tenYears() public {
        (uint amountOut, uint cbtDaoCut, uint cbtToBurn) = SolidMath
            .computeDecollateralizationOutcome(
                block.timestamp + 10 * ONE_YEAR,
                1000e18,
                1600, // 0.16% weekly discount
                DECOLLATERALIZATION_FEE,
                18
            );

        assertEq(amountOut, 2184);
        assertEq(cbtDaoCut, 50e18);
        assertEq(cbtToBurn, 950e18);
    }

    function testDecollateralizationOutcome_fuzz(
        uint timeAppreciation,
        uint certificationDate,
        uint inputAmount
    ) public {
        timeAppreciation = bound(timeAppreciation, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1);
        certificationDate = bound(certificationDate, 1, CURRENT_DATE + 50 * ONE_YEAR);
        inputAmount = bound(
            inputAmount,
            0,
            type(uint256).max / SolidMath.TIME_APPRECIATION_BASIS_POINTS
        );

        DummySolidMath dummy = new DummySolidMath();
        try
            dummy.computeDecollateralizationOutcome(
                certificationDate,
                inputAmount,
                timeAppreciation,
                DECOLLATERALIZATION_FEE,
                18
            )
        {} catch (bytes memory reason) {
            assertEq(SolidMath.InvalidTADiscount.selector, bytes4(reason), "Fuzz test failed.");
        }
    }

    function testComputeDecollateralizationMinAmountInAndDaoCut_oneYear() public {
        uint expectedFcbtAmount = 10324;
        (uint minAmountIn, uint minCbtDaoCut) = SolidMath
            .computeDecollateralizationMinAmountInAndDaoCut(
                block.timestamp + ONE_YEAR + 1 hours,
                expectedFcbtAmount,
                1600, // 0.16% weekly discount
                DECOLLATERALIZATION_FEE,
                18
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

        (uint amountOut, uint cbtDaoCut, ) = SolidMath.computeDecollateralizationOutcome(
            block.timestamp + ONE_YEAR + 1 hours,
            minAmountIn,
            1600, // 0.16% weekly discount
            DECOLLATERALIZATION_FEE,
            18
        );

        assertEq(amountOut, expectedFcbtAmount);
        assertEq(minCbtDaoCut, cbtDaoCut);
    }

    function testComputeDecollateralizationMinAmountInAndDaoCut_tenYears() public {
        uint expectedFcbtAmount = 10324;
        (uint minAmountIn, uint minCbtDaoCut) = SolidMath
            .computeDecollateralizationMinAmountInAndDaoCut(
                block.timestamp + 10 * ONE_YEAR + 1 hours,
                expectedFcbtAmount,
                1600, // 0.16% weekly discount
                DECOLLATERALIZATION_FEE,
                18
            );

        // macbook result:   4726090204400000000000
        // js result:        4726090204381908000000
        // keisan result:    4726090204382020388684
        // sol result:       4726088117894736842105
        // delta = 4726090204400000000000 - 4726088117894736842105 = 2086505263157895 = ~2087000000000000
        assertApproxEqAbs(minAmountIn, 4726090204400000000000, 2087000000000000);

        // macbook result:   236304510220000000000
        // js result:        236304510220000030000
        // keisan result:    236304510220000000000
        // sol result:       236304405894736842105
        // delta = 236304510220000030000 - 236304405894736842105 = 104325263187895 = ~104400000000000
        assertApproxEqAbs(minCbtDaoCut, 236304510220000030000, 104400000000000);

        (uint amountOut, uint cbtDaoCut, ) = SolidMath.computeDecollateralizationOutcome(
            block.timestamp + 10 * ONE_YEAR + 1 hours,
            minAmountIn,
            1600, // 0.16% weekly discount
            DECOLLATERALIZATION_FEE,
            18
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
        certificationDate = bound(certificationDate, CURRENT_DATE, CURRENT_DATE + 50 * ONE_YEAR);
        timeAppreciation = bound(timeAppreciation, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1);
        decollateralizationFee = bound(decollateralizationFee, 1, 9900); // max 99% fee

        DummySolidMath dummy = new DummySolidMath();

        try
            dummy.computeDecollateralizationMinAmountInAndDaoCut(
                certificationDate,
                expectedFcbtAmount,
                timeAppreciation,
                decollateralizationFee,
                18
            )
        returns (uint minAmountIn, uint minCbtDaoCut) {
            try
                dummy.computeDecollateralizationOutcome(
                    certificationDate,
                    minAmountIn,
                    timeAppreciation,
                    decollateralizationFee,
                    18
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
            block.timestamp - 1 minutes,
            10000,
            1647,
            REWARDS_FEE,
            18
        );

        assertEq(rewardAmount, 0);
        assertEq(feeAmount, 0);
    }

    function testComputeWeeklyBatchReward_lessThanOneWeek() public {
        (uint rewardAmount, uint feeAmount) = SolidMath.computeWeeklyBatchReward(
            block.timestamp + 1 minutes,
            10000,
            1647,
            REWARDS_FEE,
            18
        );

        assertEq(rewardAmount, 15.6465e18);
        assertEq(feeAmount, 0.8235e18);
    }

    function testComputeWeeklyBatchReward_oneWeek() public {
        (uint rewardAmount, uint feeAmount) = SolidMath.computeWeeklyBatchReward(
            block.timestamp + 1 weeks + 1 minutes,
            10000,
            1647,
            REWARDS_FEE,
            18
        );

        assertEq(rewardAmount, 15.6207302145e18);
        assertEq(feeAmount, 0.8221436955e18);
    }

    function testComputeWeeklyBatchReward_fiveYears() public {
        (uint rewardAmount, uint feeAmount) = SolidMath.computeWeeklyBatchReward(
            block.timestamp + 5 * ONE_YEAR + 1 minutes,
            10000,
            1647,
            REWARDS_FEE,
            18
        );

        assertApproxEqAbs(rewardAmount, 10.1927249229e18, 256500000000);
        assertApproxEqAbs(feeAmount, 0.5364592065e18, 13500000000);
    }

    function testComputeWeeklyBatchReward_fuzz(
        uint timeAppreciation,
        uint certificationDate,
        uint availableCredits
    ) public {
        timeAppreciation = bound(timeAppreciation, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1);
        certificationDate = bound(certificationDate, 1, CURRENT_DATE + 50 * ONE_YEAR);
        availableCredits = bound(
            availableCredits,
            0,
            type(uint256).max / 1e18 / SolidMath.FEE_BASIS_POINTS
        );

        DummySolidMath dummy = new DummySolidMath();
        try
            dummy.computeWeeklyBatchReward(
                certificationDate,
                availableCredits,
                timeAppreciation,
                REWARDS_FEE,
                18
            )
        {} catch (bytes memory reason) {
            assertEq(SolidMath.InvalidTADiscount.selector, bytes4(reason), "Fuzz test failed.");
        }
    }

    function testFailComputeCollateralizationOutcome_ifCertificationDateIsInThePast() public view {
        SolidMath.computeCollateralizationOutcome(
            block.timestamp - 1 hours,
            10000,
            1647,
            COLLATERALIZATION_FEE,
            18
        );
    }
}
