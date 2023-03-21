// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseRegulatoryCompliant.t.sol";

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
}
