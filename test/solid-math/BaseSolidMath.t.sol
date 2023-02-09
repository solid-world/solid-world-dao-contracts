// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../BaseTest.sol";
import "../../contracts/libraries/SolidMath.sol";

abstract contract BaseSolidMathTest is BaseTest {
    uint constant COLLATERALIZATION_FEE = 200; // 2%
    uint constant DECOLLATERALIZATION_FEE = 500; // 5%
    uint constant REWARDS_FEE = 500; // 5%
    uint constant PRESET_TIME_APPRECIATION = 8_0000; // 8%
    uint constant CURRENT_DATE = 1666016743;

    function setUp() public {
        vm.warp(CURRENT_DATE);
    }
}
