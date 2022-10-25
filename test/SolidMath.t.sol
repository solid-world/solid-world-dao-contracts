pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/lib/SolidMath.sol";

contract SolidMathTest is Test {
    uint constant COLLATERALIZATION_FEE = 200; // 2%
    uint constant DECOLLATERALIZATION_FEE = 500; // 5%
    uint constant ONE_YEAR = 1 weeks * 52;
    uint constant CURRENT_DATE = 1666016743;

    error IncorrectDates(uint startDate, uint endDate);

    function setUp() public {
        vm.warp(CURRENT_DATE);
        vm.label(vm.addr(1), "Dummy account 1");
    }

    function testWeeksBetweenWhenEndDateIsBeforeStartDate() public {
        uint endDate = CURRENT_DATE - 3 weeks;

        vm.expectRevert(abi.encodeWithSelector(IncorrectDates.selector, CURRENT_DATE, endDate));
        SolidMath.weeksBetween(CURRENT_DATE, endDate);
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
        uint expectedCertificationDate = block.timestamp + 1 weeks;

        uint actual = SolidMath.computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );
        uint expected = 920_000; // 92%

        assertEq(actual, expected);
    }

    function testComputeTimeAppreciationDiscountFewWeeks() public {
        uint timeAppreciation = 80_000; // 8%
        uint expectedCertificationDate = block.timestamp + 5 weeks;

        uint actual = SolidMath.computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );
        uint expected = 659_081; // 65.90815232%

        assertEq(actual, expected);
    }

    function testComputeTimeAppreciationDiscountOneYear() public {
        uint timeAppreciation = 80_000; // 8%
        uint expectedCertificationDate = block.timestamp + ONE_YEAR;

        uint actual = SolidMath.computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );
        uint expected = 13_090; // 1.309082514%

        assertEq(actual, expected);
    }

    function testCollateralizationOutcomeAgainstLinearAlgorithm_oneWeek() public {
        uint delta = 500000000000000000;

        (uint256 cbtUserCut, uint256 cbtDaoCut) = SolidMath.computeCollateralizationOutcome(
            block.timestamp + 1 weeks + 1 hours,
            10000,
            984,
            COLLATERALIZATION_FEE,
            18
        );
        assertApproxEqAbs(cbtUserCut, 9790_356800000_000000000, delta);
        assertApproxEqAbs(cbtDaoCut, 199_803200000_000000000, delta);
    }

    function testCollateralizationOutcomeAgainstLinearAlgorithm_oneYear() public {
        uint delta = 500000000000000000;

        (uint256 userAmountOut2, uint256 daoAmountOut2) = SolidMath.computeCollateralizationOutcome(
            block.timestamp + ONE_YEAR + 1 hours,
            10000,
            984,
            COLLATERALIZATION_FEE,
            18
        );
        assertApproxEqAbs(userAmountOut2, 9310_666400000_000000000, delta);
        assertApproxEqAbs(daoAmountOut2, 190_013600000_000000000, delta);
    }

    function testCollateralizationOutcomeAgainstLinearAlgorithm_tenYears() public {
        uint delta = 50000000000000000000;

        (uint256 userAmountOut3, uint256 daoAmountOut3) = SolidMath.computeCollateralizationOutcome(
            block.timestamp + 10 * ONE_YEAR + 1 hours,
            100000,
            984,
            COLLATERALIZATION_FEE,
            18
        );
        assertApproxEqAbs(userAmountOut3, 58714_348000000_000000000, delta);
        assertApproxEqAbs(daoAmountOut3, 1198_252000000_000000000, delta);
    }

    function testDecollateralizationOutcome_oneWeek() public {
        (uint amountOut, uint cbtDaoCut, uint cbtToBurn) = SolidMath
            .computeDecollateralizationOutcome(
                block.timestamp + 1 weeks,
                10000e18,
                10_0000,
                DECOLLATERALIZATION_FEE,
                18
            );

        assertEq(amountOut, 10555);
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
}
