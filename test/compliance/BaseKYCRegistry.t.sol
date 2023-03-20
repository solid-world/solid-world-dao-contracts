// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/compliance/KYCRegistry.sol";

contract BasicKYCRegistry is KYCRegistry {}

abstract contract BaseKYCRegistryTest is BaseTest {
    IKYCRegistry kycRegistry;

    event VerifierUpdated(address indexed oldVerifier, address indexed newVerifier);

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
}
