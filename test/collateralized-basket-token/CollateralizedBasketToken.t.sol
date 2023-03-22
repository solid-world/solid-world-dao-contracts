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
}
