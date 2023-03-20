// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/compliance/KYCRegistry.sol";

contract BasicKYCRegistry is KYCRegistry {}

abstract contract BaseKYCRegistryTest is BaseTest {
    IKYCRegistry kycRegistry;

    function setUp() public {
        kycRegistry = new BasicKYCRegistry();
    }
}
