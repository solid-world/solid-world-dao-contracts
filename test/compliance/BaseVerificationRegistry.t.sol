// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/compliance/VerificationRegistry.sol";

contract BaseVerificationRegistryTest is BaseTest {
    IVerificationRegistry verificationRegistry;

    function setUp() public {
        VerificationRegistry _verificationRegistry = new VerificationRegistry();
        _verificationRegistry.initialize(address(this));

        verificationRegistry = _verificationRegistry;
    }
}
