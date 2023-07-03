// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseVerificationRegistry.sol";

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

    function testUnBlacklist_revertsIfNotBlacklisterOrOwner() public {
        address addressToBlacklist = address(1);
        address arbitraryCaller = address(2);

        vm.prank(arbitraryCaller);
        _expectRevert_BlacklistingNotAuthorized(arbitraryCaller);
        verificationRegistry.unBlacklist(addressToBlacklist);
    }

    function testUnBlacklist_unBlacklistsIfAuthorized() public {
        address addressToBlacklist1 = address(1);
        address addressToBlacklist2 = address(2);
        address blacklister = address(3);

        verificationRegistry.setBlacklister(blacklister);

        verificationRegistry.blacklist(addressToBlacklist1);
        verificationRegistry.blacklist(addressToBlacklist2);

        vm.prank(blacklister);
        verificationRegistry.unBlacklist(addressToBlacklist1);
        assertFalse(verificationRegistry.isBlacklisted(addressToBlacklist1));

        verificationRegistry.unBlacklist(addressToBlacklist2);
        assertFalse(verificationRegistry.isBlacklisted(addressToBlacklist2));
    }

    function testRegisterVerification_revertsIfNotVerifierOrOwner() public {
        address subject = address(1);
        address arbitraryCaller = address(2);

        vm.prank(arbitraryCaller);
        _expectRevert_VerificationNotAuthorized(arbitraryCaller);
        verificationRegistry.registerVerification(subject);
    }

    function testRegisterVerification_registersVerificationIfAuthorized() public {
        address subject1 = address(1);
        address subject2 = address(2);
        address verifier = address(3);

        verificationRegistry.setVerifier(verifier);

        vm.prank(verifier);
        verificationRegistry.registerVerification(subject1);
        assertTrue(verificationRegistry.isVerified(subject1));

        verificationRegistry.registerVerification(subject2);
        assertTrue(verificationRegistry.isVerified(subject2));
    }

    function testRevokeVerification_revertsIfNotVerifierOrOwner() public {
        address subject = address(1);
        address arbitraryCaller = address(2);

        vm.prank(arbitraryCaller);
        _expectRevert_VerificationNotAuthorized(arbitraryCaller);
        verificationRegistry.revokeVerification(subject);
    }

    function testRevokeVerification_revokesVerificationIfAuthorized() public {
        address subject1 = address(1);
        address subject2 = address(2);
        address verifier = address(3);

        verificationRegistry.setVerifier(verifier);

        verificationRegistry.registerVerification(subject1);
        verificationRegistry.registerVerification(subject2);

        vm.prank(verifier);
        verificationRegistry.revokeVerification(subject1);
        assertFalse(verificationRegistry.isVerified(subject1));

        verificationRegistry.revokeVerification(subject2);
        assertFalse(verificationRegistry.isVerified(subject2));
    }

    function testSetBlacklister_revertsIfNotOwner() public {
        address blacklister = address(1);
        address arbitraryCaller = address(2);

        vm.prank(arbitraryCaller);
        _expectRevert_NotOwner();
        verificationRegistry.setBlacklister(blacklister);
    }

    function testSetVerifier_revertsIfNotOwner() public {
        address verifier = address(1);
        address arbitraryCaller = address(2);

        vm.prank(arbitraryCaller);
        _expectRevert_NotOwner();
        verificationRegistry.setVerifier(verifier);
    }

    function testIsVerifiedAndNotBlacklisted() public {
        address subject1 = address(1);
        address subject2 = address(2);
        address subject3 = address(3);
        address subject4 = address(4);

        verificationRegistry.registerVerification(subject1);
        verificationRegistry.registerVerification(subject2);
        verificationRegistry.registerVerification(subject3);
        verificationRegistry.registerVerification(subject4);

        verificationRegistry.blacklist(subject2);
        verificationRegistry.blacklist(subject4);

        assertTrue(verificationRegistry.isVerifiedAndNotBlacklisted(subject1));
        assertFalse(verificationRegistry.isVerifiedAndNotBlacklisted(subject2));
        assertTrue(verificationRegistry.isVerifiedAndNotBlacklisted(subject3));
        assertFalse(verificationRegistry.isVerifiedAndNotBlacklisted(subject4));
    }
}
