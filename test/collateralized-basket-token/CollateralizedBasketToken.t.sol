// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseCollateralizedBasketToken.t.sol";

contract CollateralizedBasketTokenTest is BaseCollateralizedBasketTokenTest {
    function testIsKYCRequired() public {
        assertFalse(collateralizedBasketToken.isKYCRequired());
    }

    function testSetKYCRequired() public {
        collateralizedBasketToken.setKYCRequired(true);
        assertTrue(collateralizedBasketToken.isKYCRequired());
    }

    function testSetKYCRequired_revertsIfNotOwner() public {
        vm.prank(testAccount0);
        _expectRevertWithMessage("Ownable: caller is not the owner");
        collateralizedBasketToken.setKYCRequired(true);
    }

    function testSetKYCRequired_emitsEvent() public {
        _expectEmit_KYCRequiredSet(true);
        collateralizedBasketToken.setKYCRequired(true);
    }

    function testSetVerificationRegistry_revertsIfNotOwner() public {
        address _verificationRegistry = vm.addr(1);

        vm.prank(testAccount0);
        _expectRevertWithMessage("Ownable: caller is not the owner");
        collateralizedBasketToken.setVerificationRegistry(_verificationRegistry);
    }

    function testSetVerificationRegistry_setsRegistry() public {
        address _verificationRegistry = vm.addr(1);

        collateralizedBasketToken.setVerificationRegistry(_verificationRegistry);
        assertEq(collateralizedBasketToken.getVerificationRegistry(), _verificationRegistry);
    }
}
