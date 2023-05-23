// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/libraries/DateTime.sol";

abstract contract BaseDateTime is BaseTest {
    function setUp() public {
        vm.warp(PRESET_CURRENT_DATE);
    }
}
