// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/compliance/KYCRegistry.sol";

contract BasicKYCRegistry is KYCRegistry {}

abstract contract BaseKYCRegistryTest is BaseTest {
    IKYCRegistry kycRegistry;

    event VerifierUpdated(address indexed oldVerifier, address indexed newVerifier);
    event Verified(address indexed subject);
    event VerificationRevoked(address indexed subject);

    function setUp() public {
        kycRegistry = new BasicKYCRegistry();
    }

    function _expectRevert_InvalidInput() internal {
        vm.expectRevert(abi.encodeWithSelector(IKYCRegistry.InvalidInput.selector));
    }

    function _expectEmit_VerifierUpdated(address oldVerifier, address newVerifier) internal {
        vm.expectEmit(true, true, true, false, address(kycRegistry));
        emit VerifierUpdated(oldVerifier, newVerifier);
    }

    function _expectEmit_Verified(address subject) internal {
        vm.expectEmit(true, true, false, false, address(kycRegistry));
        emit Verified(subject);
    }

    function _expectEmit_VerificationRevoked(address subject) internal {
        vm.expectEmit(true, true, false, false, address(kycRegistry));
        emit VerificationRevoked(subject);
    }
}
