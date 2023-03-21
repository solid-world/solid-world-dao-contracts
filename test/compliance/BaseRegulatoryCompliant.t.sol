// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/compliance/RegulatoryCompliant.sol";
import "../../contracts/compliance/VerificationRegistry.sol";
import "../../contracts/interfaces/compliance/IVerificationRegistry.sol";

contract BasicRegulatoryCompliant is RegulatoryCompliant {
    constructor(address _verificationRegistry) RegulatoryCompliant(_verificationRegistry) {}
}

contract BaseRegulatoryCompliantTest is BaseTest {
    IVerificationRegistry verificationRegistry;
    IRegulatoryCompliant regulatoryCompliant;

    address counterparty1 = address(1);
    address counterparty2 = address(2);
    address counterparty3 = address(3);

    event VerificationRegistryUpdated(address indexed verificationRegistry);

    function setUp() public {
        initVerificationRegistry();
        setupCounterparties();

        regulatoryCompliant = new BasicRegulatoryCompliant(address(verificationRegistry));
    }

    function initVerificationRegistry() private {
        VerificationRegistry _verificationRegistry = new VerificationRegistry();
        _verificationRegistry.initialize(address(this));

        verificationRegistry = IVerificationRegistry(address(_verificationRegistry));
    }

    function setupCounterparties() private {
        verificationRegistry.registerVerification(counterparty1);
        verificationRegistry.blacklist(counterparty3);
    }

    function _expectRevert_InvalidVerificationRegistry() internal {
        vm.expectRevert(abi.encodeWithSelector(IRegulatoryCompliant.InvalidVerificationRegistry.selector));
    }

    function _expectEmit_VerificationRegistryUpdated(address _verificationRegistry) internal {
        vm.expectEmit(true, true, false, false, address(regulatoryCompliant));
        emit VerificationRegistryUpdated(_verificationRegistry);
    }
}
