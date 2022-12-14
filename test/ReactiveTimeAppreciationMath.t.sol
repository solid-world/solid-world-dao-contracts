pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../contracts/libraries/DomainDataTypes.sol";
import "../contracts/libraries/ReactiveTimeAppreciationMath.sol";

contract ReactiveTimeAppreciationMathTest is Test {
    uint32 constant CURRENT_DATE = 1666016743;

    function setUp() public {
        vm.warp(CURRENT_DATE);
    }

    function testComputeDecayingMomentum() public {
        uint lastCollateralizationMomentum = 10000;
        uint decayPerSecond = getTestDecayPerSecond();

        uint32[] memory lastCollateralizationTimestamps = new uint32[](6);
        lastCollateralizationTimestamps[0] = uint32(CURRENT_DATE - 1 days);
        lastCollateralizationTimestamps[1] = uint32(CURRENT_DATE - 21 days);
        lastCollateralizationTimestamps[2] = uint32(CURRENT_DATE - 1 days - 18 hours);
        lastCollateralizationTimestamps[3] = uint32(
            CURRENT_DATE - 3 days - 15 hours - 33 minutes - 12 seconds
        );
        lastCollateralizationTimestamps[4] = uint32(CURRENT_DATE - 19 days - 18 hours);
        lastCollateralizationTimestamps[5] = uint32(CURRENT_DATE - 20 days);

        uint decayingMomentum0 = ReactiveTimeAppreciationMath.computeDecayingMomentum(
            decayPerSecond,
            lastCollateralizationMomentum,
            lastCollateralizationTimestamps[0]
        );
        uint decayingMomentum1 = ReactiveTimeAppreciationMath.computeDecayingMomentum(
            decayPerSecond,
            lastCollateralizationMomentum,
            lastCollateralizationTimestamps[1]
        );
        uint decayingMomentum2 = ReactiveTimeAppreciationMath.computeDecayingMomentum(
            decayPerSecond,
            lastCollateralizationMomentum,
            lastCollateralizationTimestamps[2]
        );
        uint decayingMomentum3 = ReactiveTimeAppreciationMath.computeDecayingMomentum(
            decayPerSecond,
            lastCollateralizationMomentum,
            lastCollateralizationTimestamps[3]
        );
        uint decayingMomentum4 = ReactiveTimeAppreciationMath.computeDecayingMomentum(
            decayPerSecond,
            lastCollateralizationMomentum,
            lastCollateralizationTimestamps[4]
        );
        uint decayingMomentum5 = ReactiveTimeAppreciationMath.computeDecayingMomentum(
            decayPerSecond,
            lastCollateralizationMomentum,
            lastCollateralizationTimestamps[5]
        );

        assertEq(decayingMomentum0, 9500);
        assertEq(decayingMomentum1, 0);
        assertEq(decayingMomentum2, 9125);
        assertEq(decayingMomentum3, 8175);
        assertEq(decayingMomentum4, 125);
        assertEq(decayingMomentum5, 0);
    }

    function testComputeReactiveTA() public {
        uint24 decayPerSecond = uint24(getTestDecayPerSecond());
        uint24 maxDepreciation = 193; // 1% yearly rate
        uint24 averageTA = 1599; // 8% yearly rate

        DomainDataTypes.Category[] memory categoryStates = new DomainDataTypes.Category[](2);
        categoryStates[0].volumeCoefficient = 50000;
        categoryStates[0].decayPerSecond = decayPerSecond;
        categoryStates[0].maxDepreciation = maxDepreciation;
        categoryStates[0].averageTA = averageTA;
        categoryStates[0].totalCollateralized = 0;
        categoryStates[0].lastCollateralizationTimestamp = CURRENT_DATE;
        categoryStates[0].lastCollateralizationMomentum = 0; // eliminates decaying momentum from the equation

        categoryStates[1].volumeCoefficient = 50000;
        categoryStates[1].decayPerSecond = decayPerSecond;
        categoryStates[1].maxDepreciation = maxDepreciation;
        categoryStates[1].averageTA = averageTA;
        categoryStates[1].totalCollateralized = 0;
        categoryStates[1].lastCollateralizationTimestamp = CURRENT_DATE; // decayingMomentum = lastCollateralizationMomentum
        categoryStates[1].lastCollateralizationMomentum = 30000;

        (uint decayingMomentum0, uint24 reactiveTA0) = ReactiveTimeAppreciationMath
            .computeReactiveTA(categoryStates[0], 10000);
        (uint decayingMomentum1, uint24 reactiveTA1) = ReactiveTimeAppreciationMath
            .computeReactiveTA(categoryStates[1], 10000);
        (uint decayingMomentum2, uint24 reactiveTA2) = ReactiveTimeAppreciationMath
            .computeReactiveTA(categoryStates[0], 0);

        assertEq(decayingMomentum0, 0);
        // 7.1% yearly rate
        // js result: 1425.4519410847877
        assertEq(reactiveTA0, 1426);

        assertEq(decayingMomentum1, 30000);
        // 7.7% yearly rate
        // js result: 1541.06903645157
        assertEq(reactiveTA1, 1541);

        assertEq(decayingMomentum2, 0);
        // 7% yearly rate
        // js result: 1406.2486641728267
        assertEq(reactiveTA2, 1406);
    }

    function testComputeReactiveTA_revertsWhenTAOverflows() public {
        DomainDataTypes.Category memory categoryState;
        categoryState.volumeCoefficient = 50000;
        categoryState.decayPerSecond = 0;
        categoryState.maxDepreciation = 0;
        categoryState.averageTA = 1599; // 8% per year
        categoryState.totalCollateralized = 0;
        categoryState.lastCollateralizationTimestamp = CURRENT_DATE;
        categoryState.lastCollateralizationMomentum = 0;

        uint forwardCreditsAmount = 1e18;
        vm.expectRevert(
            abi.encodeWithSelector(
                ReactiveTimeAppreciationMath.ForwardCreditsInputAmountTooLarge.selector,
                forwardCreditsAmount
            )
        );
        ReactiveTimeAppreciationMath.computeReactiveTA(categoryState, forwardCreditsAmount);
    }

    function testToWeeklyRate() public {
        assertEq(ReactiveTimeAppreciationMath.toWeeklyRate(0), 0);

        // js result: 1599.1347781311172
        assertEq(ReactiveTimeAppreciationMath.toWeeklyRate(80000), 1600);

        // js result: 4273.826727360097
        assertEq(ReactiveTimeAppreciationMath.toWeeklyRate(200000), 4274);

        // js result: 84597.09972808382
        assertEq(ReactiveTimeAppreciationMath.toWeeklyRate(990000), 84598);
    }

    function getTestDecayPerSecond() internal pure returns (uint decayPerSecond) {
        // 5% decay per day quantified per second
        decayPerSecond = Math.mulDiv(
            5,
            ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS,
            100 * 1 days
        );
    }
}
