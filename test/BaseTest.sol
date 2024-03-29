// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console.sol";

abstract contract BaseTest is Test {
    uint32 constant ONE_YEAR = 52 weeks;
    uint32 constant PRESET_CURRENT_DATE = 1666016743; // 17-10-2022 14:25:43:000 UTC
    uint8 constant PRESET_DECIMALS = 18;

    function _expectRevertWithMessage(string memory message) internal {
        vm.expectRevert(abi.encodePacked(message));
    }

    function _expectRevert_ArithmeticError() internal {
        vm.expectRevert(stdError.arithmeticError);
    }

    function _expectRevert_NotOwner() internal {
        _expectRevertWithMessage("Ownable: caller is not the owner");
    }

    function _yearsToSeconds(uint _years) internal pure returns (uint) {
        return _years * ONE_YEAR;
    }

    function _toArray(address _address) internal pure returns (address[] memory array) {
        array = new address[](1);
        array[0] = _address;
    }

    function _toArray(address _address0, address _address1) internal pure returns (address[] memory array) {
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

    function _toArrayUint88(uint _number0, uint _number1) internal pure returns (uint88[] memory array) {
        array = new uint88[](2);
        array[0] = uint88(_number0);
        array[1] = uint88(_number1);
    }
}
