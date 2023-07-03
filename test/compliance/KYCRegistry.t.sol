// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseKYCRegistry.sol";

contract KYCRegistryTest is BaseKYCRegistryTest {
    function testGetVerifier_initial() public {
        address verifier = kycRegistry.getVerifier();
        assertEq(verifier, address(0));
    }

    function testSetVerifier_revertsIfVerifierIsZeroAddress() public {
        _expectRevert_InvalidVerifier();
        kycRegistry.setVerifier(address(0));
    }

    function testSetVerifier_updatesVerifier() public {
        address newVerifier = vm.addr(1);
        kycRegistry.setVerifier(newVerifier);

        assertEq(kycRegistry.getVerifier(), newVerifier);
    }

    function testSetVerifier_emitsEvent() public {
        address newVerifier = vm.addr(1);

        _expectEmit_VerifierUpdated(address(0), newVerifier);
        kycRegistry.setVerifier(newVerifier);
    }

    function testIsVerified() public {
        address subject = vm.addr(1);

        assertEq(kycRegistry.isVerified(subject), false);
    }

    function testRegisterVerification_verifiesSubject() public {
        address subject = vm.addr(1);

        kycRegistry.registerVerification(subject);
        assertEq(kycRegistry.isVerified(subject), true);
    }

    function testRegisterVerification_emitsEvent() public {
        address subject = vm.addr(1);

        _expectEmit_Verified(subject);
        kycRegistry.registerVerification(subject);
    }

    function testRevokeVerification_revokesVerification() public {
        address subject = vm.addr(1);

        kycRegistry.registerVerification(subject);
        kycRegistry.revokeVerification(subject);

        assertEq(kycRegistry.isVerified(subject), false);
    }

    function testRevokeVerification_emitsEvent() public {
        address subject = vm.addr(1);

        _expectEmit_VerificationRevoked(subject);
        kycRegistry.revokeVerification(subject);
    }
}
