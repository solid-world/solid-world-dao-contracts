// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../BaseTest.sol";
import "../../contracts/libraries/ReactiveTimeAppreciationMath.sol";

contract BaseReactiveTimeAppreciationMathTest is BaseTest {
    function setUp() public {
        vm.warp(PRESET_CURRENT_DATE);
    }

    function _getTestDecayPerSecond() internal pure returns (uint decayPerSecond) {
        // 5% decay per day quantified per second
        decayPerSecond = Math.mulDiv(5, ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS, 100 * 1 days);
    }
}
