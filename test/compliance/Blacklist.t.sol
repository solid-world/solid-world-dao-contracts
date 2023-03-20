// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseBlacklist.t.sol";

contract BlacklistTest is BaseBlacklistTest {
    function testGetBlacklister_initial() public {
        address blacklister = blacklist.getBlacklister();
        assertEq(blacklister, address(0));
    }

    function testSetBlacklister_revertsIfBlacklisterIsZeroAddress() public {
        _expectRevert_InvalidInput();
        blacklist.setBlacklister(address(0));
    }

    function testSetBlacklister_updatesBlacklister() public {
        address newBlacklister = vm.addr(1);
        blacklist.setBlacklister(newBlacklister);

        assertEq(blacklist.getBlacklister(), newBlacklister);
    }

    function testSetBlacklister_emitsEvent() public {
        address newBlacklister = vm.addr(1);

        _expectEmit_BlacklisterUpdated(address(0), newBlacklister);
        blacklist.setBlacklister(newBlacklister);
    }

    function testIsBlacklisted() public {
        address subject = vm.addr(1);

        assertEq(blacklist.isBlacklisted(subject), false);
    }

    function testBlacklist_blacklistsSubject() public {
        address subject = vm.addr(1);

        blacklist.blacklist(subject);

        assertEq(blacklist.isBlacklisted(subject), true);
    }

    function testBlacklist_emitsEvent() public {
        address subject = vm.addr(1);

        _expectEmit_Blacklisted(subject);
        blacklist.blacklist(subject);
    }

    function testUnBlacklist_unblacklistsSubject() public {
        address subject = vm.addr(1);

        blacklist.blacklist(subject);
        blacklist.unBlacklist(subject);

        assertEq(blacklist.isBlacklisted(subject), false);
    }

    function testUnBlacklist_emitsEvent() public {
        address subject = vm.addr(1);

        _expectEmit_UnBlacklisted(subject);
        blacklist.unBlacklist(subject);
    }
}
