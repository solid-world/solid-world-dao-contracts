// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

abstract contract BaseTest is Test {
    function _expectRevertWithMessage(string memory message) internal {
        vm.expectRevert(abi.encodePacked(message));
    }
}
