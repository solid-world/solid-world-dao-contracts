// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/compliance/VerificationRegistry.sol";
import "../../contracts/interfaces/compliance/IVerificationRegistry.sol";

contract BaseVerificationRegistryTest is BaseTest {
    IVerificationRegistry verificationRegistry;

    function setUp() public {
        VerificationRegistry _verificationRegistry = new VerificationRegistry();
        _verificationRegistry.initialize(address(this));

        verificationRegistry = IVerificationRegistry(address(_verificationRegistry));
    }

    function _expectRevert_BlacklistingNotAuthorized(address caller) internal {
        vm.expectRevert(abi.encodeWithSelector(IBlacklist.BlacklistingNotAuthorized.selector, caller));
    }

    function _expectRevert_VerificationNotAuthorized(address caller) internal {
        vm.expectRevert(abi.encodeWithSelector(IKYCRegistry.VerificationNotAuthorized.selector, caller));
    }
}
