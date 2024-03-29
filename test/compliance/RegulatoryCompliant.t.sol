// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseRegulatoryCompliant.sol";

contract RegulatoryCompliantTest is BaseRegulatoryCompliantTest {
    function testGetVerificationRegistry() public {
        address _verificationRegistry = regulatoryCompliant.getVerificationRegistry();

        assertEq(_verificationRegistry, address(verificationRegistry));
    }

    function testConstructor_revertsForInvalidRegistry() public {
        _expectRevert_InvalidVerificationRegistry();
        new BasicRegulatoryCompliant(address(0));
    }

    function testSetVerificationRegistry_revertsForInvalidRegistry() public {
        _expectRevert_InvalidVerificationRegistry();
        regulatoryCompliant.setVerificationRegistry(address(0));
    }

    function testSetVerificationRegistry() public {
        address newVerificationRegistry = address(1);

        regulatoryCompliant.setVerificationRegistry(newVerificationRegistry);

        assertEq(regulatoryCompliant.getVerificationRegistry(), newVerificationRegistry);
    }

    function testSetVerificationRegistry_emitsEvent() public {
        address newVerificationRegistry = address(1);

        _expectEmit_VerificationRegistryUpdated(newVerificationRegistry);
        regulatoryCompliant.setVerificationRegistry(newVerificationRegistry);
    }

    function testIsValidCounterparty() public {
        bool kycRequired = true;
        bool kycNotRequired = false;

        assertTrue(regulatoryCompliant.isValidCounterparty(counterparty1, kycNotRequired));
        assertTrue(regulatoryCompliant.isValidCounterparty(counterparty2, kycNotRequired));
        assertFalse(regulatoryCompliant.isValidCounterparty(counterparty3, kycNotRequired));

        assertTrue(regulatoryCompliant.isValidCounterparty(counterparty1, kycRequired));
        assertFalse(regulatoryCompliant.isValidCounterparty(counterparty2, kycRequired));
        assertFalse(regulatoryCompliant.isValidCounterparty(counterparty3, kycRequired));
    }
}
