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

    function setUp() public {
        initVerificationRegistry();

        regulatoryCompliant = new BasicRegulatoryCompliant(address(verificationRegistry));
    }

    function initVerificationRegistry() private {
        VerificationRegistry _verificationRegistry = new VerificationRegistry();
        _verificationRegistry.initialize(address(this));

        verificationRegistry = IVerificationRegistry(address(_verificationRegistry));
    }
}
