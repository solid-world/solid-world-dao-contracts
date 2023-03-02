// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/libraries/ReactiveTimeAppreciationMath.sol";

contract BaseReactiveTimeAppreciationMathTest is BaseTest {
    uint40 immutable PRESET_DECAY_PER_SECOND;

    constructor() {
        PRESET_DECAY_PER_SECOND = _getTestDecayPerSecond();
    }

    function setUp() public {
        vm.warp(PRESET_CURRENT_DATE);
    }

    function _getTestDecayPerSecond() internal pure returns (uint40 decayPerSecond) {
        // 5% decay per day quantified per second
        decayPerSecond = uint40(
            Math.mulDiv(5, ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS, 100 * 1 days)
        );
    }

    function _boundNewVolumeCoefficient(uint newVolumeCoefficient, uint volumeCoefficient)
        internal
        returns (uint)
    {
        return bound(newVolumeCoefficient, 0, volumeCoefficient);
    }

    function _boundLastCollateralizationTimestamp(uint lastCollateralizationTimestamp)
        internal
        returns (uint32)
    {
        return uint32(bound(lastCollateralizationTimestamp, 0, PRESET_CURRENT_DATE));
    }

    function _boundDecayPerSecond(uint40 decayPerSecond) internal returns (uint40) {
        return uint40(bound(decayPerSecond, 0, ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS));
    }

    function _boundAverageTA(uint24 averageTA) internal returns (uint24) {
        return uint24(bound(averageTA, 0, SolidMath.TIME_APPRECIATION_BASIS_POINTS - 1));
    }
}
