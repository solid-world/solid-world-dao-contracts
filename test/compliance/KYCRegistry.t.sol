// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseKYCRegistry.t.sol";

contract KYCRegistryTest is BaseKYCRegistryTest {
    function testGetVerifier_initial() public {
        address verifier = kycRegistry.getVerifier();
        assertEq(verifier, address(0));
    }

    function testSetVerifier_revertsIfVerifierIsZeroAddress() public {
        _expectRevert_InvalidInput();
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
}
