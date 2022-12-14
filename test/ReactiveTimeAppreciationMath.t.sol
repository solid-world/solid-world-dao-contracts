pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../contracts/libraries/DomainDataTypes.sol";
import "../contracts/libraries/ReactiveTimeAppreciationMath.sol";

contract ReactiveTimeAppreciationMathTest is Test {
    uint constant CURRENT_DATE = 1666016743;

    function setUp() public {
        vm.warp(CURRENT_DATE);
    }

    function testComputeDecayingMomentum() public {
        uint lastCollateralizationMomentum = 10000;

        // 5% decay per day quantified per second
        uint decayPerSecond = Math.mulDiv(
            5,
            ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS,
            100 * 1 days
        );

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
}
