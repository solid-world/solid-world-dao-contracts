// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/compliance/Blacklist.sol";

contract BasicBlacklist is Blacklist {}

abstract contract BaseBlacklistTest is BaseTest {
    IBlacklist blacklist;

    event BlacklisterUpdated(address indexed oldBlacklister, address indexed newBlacklister);
    event Blacklisted(address indexed subject);
    event UnBlacklisted(address indexed subject);

    function setUp() public {
        blacklist = new BasicBlacklist();
    }

    function _expectRevert_InvalidInput() internal {
        vm.expectRevert(abi.encodeWithSelector(IBlacklist.InvalidInput.selector));
    }

    function _expectEmit_BlacklisterUpdated(address oldBlacklister, address newBlacklister) internal {
        vm.expectEmit(true, true, true, false, address(blacklist));
        emit BlacklisterUpdated(oldBlacklister, newBlacklister);
    }

    function _expectEmit_Blacklisted(address subject) internal {
        vm.expectEmit(true, true, false, false, address(blacklist));
        emit Blacklisted(subject);
    }

    function _expectEmit_UnBlacklisted(address subject) internal {
        vm.expectEmit(true, true, false, false, address(blacklist));
        emit UnBlacklisted(subject);
    }
}
