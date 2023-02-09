// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./ReactiveTimeAppreciationMathWrapper.t.sol";
import "./BaseReactiveTimeAppreciationMath.sol";

contract ReactiveTimeAppreciationMathTest is BaseReactiveTimeAppreciationMathTest {
    function testComputeDecayingMomentum() public {
        uint lastCollateralizationMomentum = 10000;

        uint[] memory lastCollateralizationTimestamps = new uint[](6);
        lastCollateralizationTimestamps[0] = PRESET_CURRENT_DATE - 1 days;
        lastCollateralizationTimestamps[1] = PRESET_CURRENT_DATE - 21 days;
        lastCollateralizationTimestamps[2] = PRESET_CURRENT_DATE - 1 days - 18 hours;
        lastCollateralizationTimestamps[3] =
            PRESET_CURRENT_DATE -
            3 days -
            15 hours -
            33 minutes -
            12 seconds;
        lastCollateralizationTimestamps[4] = PRESET_CURRENT_DATE - 19 days - 18 hours;
        lastCollateralizationTimestamps[5] = PRESET_CURRENT_DATE - 20 days;

        uint[] memory expectedDecayingMomentum = new uint[](6);
        expectedDecayingMomentum[0] = 9500;
        expectedDecayingMomentum[1] = 0;
        expectedDecayingMomentum[2] = 9125;
        expectedDecayingMomentum[3] = 8175;
        expectedDecayingMomentum[4] = 125;
        expectedDecayingMomentum[5] = 0;

        for (uint i; i < lastCollateralizationTimestamps.length; i++) {
            uint decayingMomentum = ReactiveTimeAppreciationMath.computeDecayingMomentum(
                PRESET_DECAY_PER_SECOND,
                lastCollateralizationMomentum,
                lastCollateralizationTimestamps[i]
            );
            assertEq(decayingMomentum, expectedDecayingMomentum[i]);
        }
    }

    function testComputeDecayingMomentum_fuzz(
        uint decayPerSecond,
        uint lastCollateralizationMomentum,
        uint lastCollateralizationTimestamp
    ) public {
        decayPerSecond = bound(decayPerSecond, 0, ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS);
        lastCollateralizationTimestamp = bound(lastCollateralizationTimestamp, 0, PRESET_CURRENT_DATE);
        ReactiveTimeAppreciationMath.computeDecayingMomentum(
            decayPerSecond,
            lastCollateralizationMomentum,
            lastCollateralizationTimestamp
        );
    }

    function testComputeReactiveTA() public {
        uint16 maxDepreciation = 10; // 1% yearly rate
        uint24 averageTA = 80000; // 8% yearly rate

        DomainDataTypes.Category[] memory categoryStates = new DomainDataTypes.Category[](2);
        categoryStates[0].volumeCoefficient = 50000;
        categoryStates[0].decayPerSecond = PRESET_DECAY_PER_SECOND;
        categoryStates[0].maxDepreciation = maxDepreciation;
        categoryStates[0].averageTA = averageTA;
        categoryStates[0].totalCollateralized = 0;
        categoryStates[0].lastCollateralizationTimestamp = PRESET_CURRENT_DATE;
        categoryStates[0].lastCollateralizationMomentum = 0; // eliminates decaying momentum from the equation

        categoryStates[1].volumeCoefficient = 50000;
        categoryStates[1].decayPerSecond = PRESET_DECAY_PER_SECOND;
        categoryStates[1].maxDepreciation = maxDepreciation;
        categoryStates[1].averageTA = averageTA;
        categoryStates[1].totalCollateralized = 0;
        categoryStates[1].lastCollateralizationTimestamp = PRESET_CURRENT_DATE; // decayingMomentum = lastCollateralizationMomentum
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
        decayPerSecond = uint40(bound(decayPerSecond, 0, ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS));
        lastCollateralizationTimestamp = uint32(
            bound(lastCollateralizationTimestamp, 0, PRESET_CURRENT_DATE)
        );

        averageTA = uint24(bound(averageTA, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1));
        maxDepreciation = uint16(bound(maxDepreciation, 0, averageTA / 1000));
        lastCollateralizationMomentum = bound(
            lastCollateralizationMomentum,
            type(uint).max / 2 + 1 + averageTA,
            type(uint).max - 1 - averageTA
        );
        forwardCreditsAmount = bound(
            forwardCreditsAmount,
            0,
            (type(uint).max - lastCollateralizationMomentum - averageTA) * 2 - 1
        );

        DomainDataTypes.Category memory categoryState;
        categoryState.volumeCoefficient = volumeCoefficient;
        categoryState.decayPerSecond = decayPerSecond;
        categoryState.maxDepreciation = maxDepreciation;
        categoryState.averageTA = averageTA;
        categoryState.totalCollateralized = 0;
        categoryState.lastCollateralizationTimestamp = lastCollateralizationTimestamp;
        categoryState.lastCollateralizationMomentum = lastCollateralizationMomentum;

        ReactiveTimeAppreciationMathWrapper wrapper = new ReactiveTimeAppreciationMathWrapper();
        try wrapper.computeReactiveTA(categoryState, forwardCreditsAmount) {} catch (bytes memory reason) {
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
        categoryState.averageTA = 1599;
        // 8% per year
        categoryState.totalCollateralized = 0;
        categoryState.lastCollateralizationTimestamp = PRESET_CURRENT_DATE;
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
        uint circulatingCBT = 945 * 10**PRESET_DECIMALS;
        uint totalCollateralizedForwardCredits = 1000;
        uint certificationDate = PRESET_CURRENT_DATE;

        uint batchTA = ReactiveTimeAppreciationMath.inferBatchTA(
            circulatingCBT,
            totalCollateralizedForwardCredits,
            certificationDate,
            PRESET_DECIMALS
        );

        assertEq(batchTA, 0);
    }

    function testFailInferBatchTA_invalidInputs() public view {
        ReactiveTimeAppreciationMath.inferBatchTA(0, 0, PRESET_CURRENT_DATE, PRESET_DECIMALS);
    }

    function testInferBatchTA() public {
        uint circulatingCBT = 880.88600587e18;
        uint totalCollateralizedForwardCredits = 1000;
        uint certificationDate = PRESET_CURRENT_DATE + 77 weeks;

        uint batchTA = ReactiveTimeAppreciationMath.inferBatchTA(
            circulatingCBT,
            totalCollateralizedForwardCredits,
            certificationDate,
            PRESET_DECIMALS
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
        certificationDate = bound(certificationDate, PRESET_CURRENT_DATE + 72 weeks, type(uint32).max);

        ReactiveTimeAppreciationMathWrapper wrapper = new ReactiveTimeAppreciationMathWrapper();
        try
            wrapper.inferBatchTA(
                circulatingCBT,
                totalCollateralizedForwardCredits,
                certificationDate,
                PRESET_DECIMALS
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
        uint maxDepreciation = 10;
        // 1% yearly rate

        uint initialMomentum = ReactiveTimeAppreciationMath.computeInitialMomentum(
            volumeCoefficient,
            maxDepreciation
        );

        assertEq(initialMomentum, 50000);
    }

    function testComputeAdjustedMomentum() public {
        DomainDataTypes.Category memory category;
        category.volumeCoefficient = 50000;
        category.decayPerSecond = PRESET_DECAY_PER_SECOND;
        category.maxDepreciation = 10;
        // 1% yearly rate
        category.averageTA = 1599;
        // 8% yearly rate
        category.totalCollateralized = 0;
        category.lastCollateralizationTimestamp = PRESET_CURRENT_DATE;
        category.lastCollateralizationMomentum = 50000;

        uint newVolumeCoefficient = 75000;
        uint newMaxDepreciation0 = 20;
        // 2% yearly rate
        uint newMaxDepreciation1 = 10;
        // 1% yearly rate
        uint newMaxDepreciation2 = 5;
        // 0.5% yearly rate

        vm.warp(PRESET_CURRENT_DATE + 2 days);
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
        decayPerSecond = uint40(bound(decayPerSecond, 0, ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS));
        lastCollateralizationTimestamp = uint32(
            bound(lastCollateralizationTimestamp, 0, PRESET_CURRENT_DATE)
        );

        averageTA = uint24(bound(averageTA, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1));
        maxDepreciation = uint16(bound(maxDepreciation, 0, averageTA / 1000));
        newMaxDepreciation = uint16(bound(newMaxDepreciation, 0, averageTA / 1000));

        int depreciationDiff = int16(newMaxDepreciation) - int16(maxDepreciation);
        if (depreciationDiff > 0) {
            lastCollateralizationMomentum = bound(
                lastCollateralizationMomentum,
                0,
                type(uint256).max - Math.mulDiv(newVolumeCoefficient, uint(depreciationDiff), 10)
            );
        }

        DomainDataTypes.Category memory categoryState;
        categoryState.volumeCoefficient = volumeCoefficient;
        categoryState.decayPerSecond = decayPerSecond;
        categoryState.maxDepreciation = maxDepreciation;
        categoryState.averageTA = averageTA;
        categoryState.totalCollateralized = 0;
        categoryState.lastCollateralizationTimestamp = lastCollateralizationTimestamp;
        categoryState.lastCollateralizationMomentum = lastCollateralizationMomentum;

        ReactiveTimeAppreciationMath.inferMomentum(categoryState, newVolumeCoefficient, newMaxDepreciation);
    }
}
