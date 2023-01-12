pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../contracts/libraries/DomainDataTypes.sol";
import "../contracts/libraries/ReactiveTimeAppreciationMath.sol";

/// @notice Dummy wrapper over some ReactiveTimeAppreciationMath functions, such that we can make external calls to them
/// @notice and use the try/catch syntax
contract DummyReactiveTimeAppreciationMath {
    function computeReactiveTA(
        DomainDataTypes.Category memory categoryState,
        uint forwardCreditsAmount
    ) external view returns (uint decayingMomentum, uint reactiveTA) {
        return ReactiveTimeAppreciationMath.computeReactiveTA(categoryState, forwardCreditsAmount);
    }

    function inferBatchTA(
        uint circulatingCBT,
        uint totalCollateralizedForwardCredits,
        uint certificationDate,
        uint cbtDecimals
    ) external view returns (uint batchTA) {
        return
            ReactiveTimeAppreciationMath.inferBatchTA(
                circulatingCBT,
                totalCollateralizedForwardCredits,
                certificationDate,
                cbtDecimals
            );
    }
}

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

    function testComputeDecayingMomentum_fuzz(
        uint decayPerSecond,
        uint lastCollateralizationMomentum,
        uint lastCollateralizationTimestamp
    ) public {
        decayPerSecond = bound(decayPerSecond, 0, ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS);
        lastCollateralizationTimestamp = bound(lastCollateralizationTimestamp, 0, CURRENT_DATE);
        ReactiveTimeAppreciationMath.computeDecayingMomentum(
            decayPerSecond,
            lastCollateralizationMomentum,
            lastCollateralizationTimestamp
        );
    }

    function testComputeReactiveTA() public {
        uint24 decayPerSecond = uint24(getTestDecayPerSecond());
        uint16 maxDepreciation = 10; // 1% yearly rate
        uint24 averageTA = 80000; // 8% yearly rate

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

        (uint decayingMomentum0, uint reactiveTA0) = ReactiveTimeAppreciationMath.computeReactiveTA(
            categoryStates[0],
            10000
        );
        (uint decayingMomentum1, uint reactiveTA1) = ReactiveTimeAppreciationMath.computeReactiveTA(
            categoryStates[1],
            10000
        );
        (uint decayingMomentum2, uint reactiveTA2) = ReactiveTimeAppreciationMath.computeReactiveTA(
            categoryStates[0],
            0
        );

        assertEq(decayingMomentum0, 0);
        // 7.1% yearly rate
        assertEq(reactiveTA0, 71000);

        assertEq(decayingMomentum1, 30000);
        // 7.7% yearly rate
        assertEq(reactiveTA1, 77000);

        assertEq(decayingMomentum2, 0);
        // 7% yearly rate
        assertEq(reactiveTA2, 70000);
    }

    function testComputeReactiveTA_fuzz(
        uint volumeCoefficient,
        uint40 decayPerSecond,
        uint16 maxDepreciation,
        uint24 averageTA,
        uint32 lastCollateralizationTimestamp,
        uint lastCollateralizationMomentum,
        uint forwardCreditsAmount
    ) public {
        volumeCoefficient = bound(volumeCoefficient, 10000, type(uint).max / 100);
        decayPerSecond = uint40(
            bound(decayPerSecond, 0, ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS)
        );
        lastCollateralizationTimestamp = uint32(
            bound(lastCollateralizationTimestamp, 0, CURRENT_DATE)
        );

        averageTA = uint24(bound(averageTA, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1));
        maxDepreciation = uint16(bound(maxDepreciation, 0, averageTA / 1000));
        lastCollateralizationMomentum = bound(
            lastCollateralizationMomentum,
            type(uint).max / 2 + 1 + averageTA,
            type(uint).max - 1
        );
        forwardCreditsAmount = bound(
            forwardCreditsAmount,
            0,
            (type(uint).max - lastCollateralizationMomentum) * 2 - 1
        );

        DomainDataTypes.Category memory categoryState;
        categoryState.volumeCoefficient = volumeCoefficient;
        categoryState.decayPerSecond = decayPerSecond;
        categoryState.maxDepreciation = maxDepreciation;
        categoryState.averageTA = averageTA;
        categoryState.totalCollateralized = 0;
        categoryState.lastCollateralizationTimestamp = lastCollateralizationTimestamp;
        categoryState.lastCollateralizationMomentum = lastCollateralizationMomentum;

        DummyReactiveTimeAppreciationMath dummy = new DummyReactiveTimeAppreciationMath();
        try dummy.computeReactiveTA(categoryState, forwardCreditsAmount) {} catch (
            bytes memory reason
        ) {
            assertEq(
                bytes4(keccak256(bytes("ReactiveTAMathBroken(uint256,uint256)"))),
                bytes4(reason),
                "Fuzz test failed."
            );
        }
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
                ReactiveTimeAppreciationMath.ReactiveTAMathBroken.selector,
                forwardCreditsAmount,
                categoryState.lastCollateralizationMomentum
            )
        );
        ReactiveTimeAppreciationMath.computeReactiveTA(categoryState, forwardCreditsAmount);
    }

    function testFailInferBatchTA_weeksTillCertificationAre0() public {
        uint cbtDecimals = 18;
        uint circulatingCBT = 945 * 10**cbtDecimals;
        uint totalCollateralizedForwardCredits = 1000;
        uint certificationDate = CURRENT_DATE;

        uint batchTA = ReactiveTimeAppreciationMath.inferBatchTA(
            circulatingCBT,
            totalCollateralizedForwardCredits,
            certificationDate,
            cbtDecimals
        );

        assertEq(batchTA, 0);
    }

    function testFailInferBatchTA_invalidInputs() public view {
        ReactiveTimeAppreciationMath.inferBatchTA(0, 0, CURRENT_DATE, 18);
    }

    function testInferBatchTA() public {
        uint circulatingCBT = 880.88600587e18;
        uint totalCollateralizedForwardCredits = 1000;
        uint certificationDate = CURRENT_DATE + 77 weeks;
        uint cbtDecimals = 18;

        uint batchTA = ReactiveTimeAppreciationMath.inferBatchTA(
            circulatingCBT,
            totalCollateralizedForwardCredits,
            certificationDate,
            cbtDecimals
        );

        assertEq(batchTA, 82300);
    }

    function testInferBatchTA_fuzz(
        uint circulatingCBT,
        uint totalCollateralizedForwardCredits,
        uint certificationDate
    ) public {
        circulatingCBT = bound(circulatingCBT, 1e18, 2**122);
        totalCollateralizedForwardCredits = bound(
            totalCollateralizedForwardCredits,
            1,
            circulatingCBT / 1e18
        );
        certificationDate = bound(certificationDate, CURRENT_DATE + 72 weeks, type(uint32).max);

        DummyReactiveTimeAppreciationMath dummy = new DummyReactiveTimeAppreciationMath();
        try
            dummy.inferBatchTA(
                circulatingCBT,
                totalCollateralizedForwardCredits,
                certificationDate,
                18
            )
        {} catch (bytes memory reason) {
            assertEq(
                bytes4(keccak256(bytes("ReactiveTAMathBroken(uint256,uint256)"))),
                bytes4(reason),
                "Fuzz test failed."
            );
        }
    }

    function testComputeInitialMomentum() public {
        uint volumeCoefficient = 50000;
        uint maxDepreciation = 10; // 1% yearly rate

        uint initialMomentum = ReactiveTimeAppreciationMath.computeInitialMomentum(
            volumeCoefficient,
            maxDepreciation
        );

        assertEq(initialMomentum, 50000);
    }

    function testComputeAdjustedMomentum() public {
        DomainDataTypes.Category memory category;
        category.volumeCoefficient = 50000;
        category.decayPerSecond = uint40(getTestDecayPerSecond());
        category.maxDepreciation = 10; // 1% yearly rate
        category.averageTA = 1599; // 8% yearly rate
        category.totalCollateralized = 0;
        category.lastCollateralizationTimestamp = CURRENT_DATE;
        category.lastCollateralizationMomentum = 50000;

        uint newVolumeCoefficient = 75000;
        uint newMaxDepreciation0 = 20; // 2% yearly rate
        uint newMaxDepreciation1 = 10; // 1% yearly rate
        uint newMaxDepreciation2 = 5; // 0.5% yearly rate

        vm.warp(CURRENT_DATE + 2 days);
        uint adjustedMomentum0 = ReactiveTimeAppreciationMath.computeAdjustedMomentum(
            category,
            newVolumeCoefficient,
            newMaxDepreciation0
        );
        uint adjustedMomentum1 = ReactiveTimeAppreciationMath.computeAdjustedMomentum(
            category,
            newVolumeCoefficient,
            newMaxDepreciation1
        );
        uint adjustedMomentum2 = ReactiveTimeAppreciationMath.computeAdjustedMomentum(
            category,
            newVolumeCoefficient,
            newMaxDepreciation2
        );

        assertEq(adjustedMomentum0, 142500);
        assertEq(adjustedMomentum1, 67500);
        assertEq(adjustedMomentum2, 67500);
    }

    function testInferMomentum_fuzz(
        uint volumeCoefficient,
        uint40 decayPerSecond,
        uint16 maxDepreciation,
        uint24 averageTA,
        uint32 lastCollateralizationTimestamp,
        uint lastCollateralizationMomentum,
        uint newVolumeCoefficient,
        uint16 newMaxDepreciation
    ) public {
        volumeCoefficient = bound(volumeCoefficient, 0, type(uint256).max / 101 - 1);
        newVolumeCoefficient = bound(newVolumeCoefficient, 0, volumeCoefficient);
        decayPerSecond = uint40(
            bound(decayPerSecond, 0, ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS)
        );
        lastCollateralizationTimestamp = uint32(
            bound(lastCollateralizationTimestamp, 0, CURRENT_DATE)
        );

        averageTA = uint24(bound(averageTA, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1));
        maxDepreciation = uint16(bound(maxDepreciation, 0, averageTA / 1000));
        newMaxDepreciation = uint16(bound(newMaxDepreciation, 0, averageTA / 1000));

        DomainDataTypes.Category memory categoryState;
        categoryState.volumeCoefficient = volumeCoefficient;
        categoryState.decayPerSecond = decayPerSecond;
        categoryState.maxDepreciation = maxDepreciation;
        categoryState.averageTA = averageTA;
        categoryState.totalCollateralized = 0;
        categoryState.lastCollateralizationTimestamp = lastCollateralizationTimestamp;
        categoryState.lastCollateralizationMomentum = lastCollateralizationMomentum;

        ReactiveTimeAppreciationMath.inferMomentum(
            categoryState,
            newVolumeCoefficient,
            newMaxDepreciation
        );
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
