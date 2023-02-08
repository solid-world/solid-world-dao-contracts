// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

abstract contract BaseTest is Test {
    uint constant ONE_YEAR = 52 weeks;

    function _expectRevertWithMessage(string memory message) internal {
        vm.expectRevert(abi.encodePacked(message));
    }

    function _expectRevert_ArithmeticError() internal {
        vm.expectRevert(stdError.arithmeticError);
    }

    function assertNotEq(address a, address b) internal {
        if (a == b) {
            emit log("Error: a != b not satisfied [address]");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }

    function _yearsToSeconds(uint _years) internal pure returns (uint) {
        return _years * ONE_YEAR;
    }

    function _toArray(address _address) internal pure returns (address[] memory array) {
        array = new address[](1);
        array[0] = _address;
    }

    function _toArray(address _address0, address _address1)
        internal
        pure
        returns (address[] memory array)
    {
        array = new address[](2);
        array[0] = _address0;
        array[1] = _address1;
    }

    function _toArray(uint _number) internal pure returns (uint[] memory array) {
        array = new uint[](1);
        array[0] = _number;
    }

    function _toArray(uint _number0, uint _number1) internal pure returns (uint[] memory array) {
        array = new uint[](2);
        array[0] = _number0;
        array[1] = _number1;
    }

    function _toArrayUint88(uint _number) internal pure returns (uint88[] memory array) {
        array = new uint88[](1);
        array[0] = uint88(_number);
    }

    function _toArrayUint88(uint _number0, uint _number1)
        internal
        pure
        returns (uint88[] memory array)
    {
        array = new uint88[](2);
        array[0] = uint88(_number0);
        array[1] = uint88(_number1);
    }
}
