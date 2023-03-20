// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseVerificationRegistry.t.sol";

contract VerificationRegistryTest is BaseVerificationRegistryTest {
    function testBlacklist_revertsIfNotBlacklisterOrOwner() public {
        address addressToBlacklist = address(1);
        address arbitraryCaller = address(2);

        vm.prank(arbitraryCaller);
        _expectRevert_BlacklistingNotAuthorized(arbitraryCaller);
        verificationRegistry.blacklist(addressToBlacklist);
    }

    function testBlacklist_blacklistsIfAuthorized() public {
        address addressToBlacklist1 = address(1);
        address addressToBlacklist2 = address(2);
        address blacklister = address(3);

        verificationRegistry.setBlacklister(blacklister);
        vm.prank(blacklister);
        verificationRegistry.blacklist(addressToBlacklist1);
        assertTrue(verificationRegistry.isBlacklisted(addressToBlacklist1));

        verificationRegistry.blacklist(addressToBlacklist2);
        assertTrue(verificationRegistry.isBlacklisted(addressToBlacklist2));
    }
}
