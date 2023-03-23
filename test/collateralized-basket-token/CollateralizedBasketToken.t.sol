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

    function testTransfer_revertsIfComplianceCheckFails_fromAddress() public {
        uint transferAmount = 100;

        collateralizedBasketToken.setKYCRequired(true);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(testAccount0);
        collateralizedBasketToken.transfer(testAccount1, transferAmount);
    }

    function testTransfer_revertsIfComplianceCheckFails_toAddress() public {
        uint transferAmount = 100;

        collateralizedBasketToken.setKYCRequired(true);
        verificationRegistry.registerVerification(testAccount0);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(testAccount1);
        collateralizedBasketToken.transfer(testAccount1, transferAmount);
    }

    function testTransferFrom_revertsIfComplianceCheckFails_fromAddress() public {
        uint transferAmount = 100;

        vm.prank(testAccount1);
        collateralizedBasketToken.approve(testAccount0, transferAmount);

        collateralizedBasketToken.setKYCRequired(true);
        verificationRegistry.registerVerification(testAccount0);
        verificationRegistry.registerVerification(testAccount2);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(testAccount1);
        collateralizedBasketToken.transferFrom(testAccount1, testAccount2, transferAmount);
    }

    function testTransferFrom_revertsIfComplianceCheckFails_toAddress() public {
        uint transferAmount = 100;

        vm.prank(testAccount1);
        collateralizedBasketToken.approve(testAccount0, transferAmount);

        collateralizedBasketToken.setKYCRequired(true);
        verificationRegistry.registerVerification(testAccount0);
        verificationRegistry.registerVerification(testAccount1);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(testAccount2);
        collateralizedBasketToken.transferFrom(testAccount1, testAccount2, transferAmount);
    }

    function testTransferFrom_revertsIfComplianceCheckFails_spender() public {
        uint transferAmount = 100;

        vm.prank(testAccount1);
        collateralizedBasketToken.approve(testAccount0, transferAmount);

        collateralizedBasketToken.setKYCRequired(true);
        verificationRegistry.registerVerification(testAccount1);
        verificationRegistry.registerVerification(testAccount2);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(testAccount0);
        collateralizedBasketToken.transferFrom(testAccount1, testAccount2, transferAmount);
    }

    function testApprove_revertsIfComplianceCheckFails_spender() public {
        uint transferAmount = 100;

        collateralizedBasketToken.setKYCRequired(true);
        verificationRegistry.registerVerification(testAccount0);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(testAccount1);
        collateralizedBasketToken.approve(testAccount1, transferAmount);
    }

    function testApprove_revertsIfComplianceCheckFails_caller() public {
        uint transferAmount = 100;

        collateralizedBasketToken.setKYCRequired(true);
        verificationRegistry.registerVerification(testAccount1);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(testAccount0);
        collateralizedBasketToken.approve(testAccount1, transferAmount);
    }

    function testMint_revertsIfComplianceCheckFails_toAddress() public {
        collateralizedBasketToken.setKYCRequired(true);

        _expectRevert_NotRegulatoryCompliant(testAccount0);
        collateralizedBasketToken.mint(testAccount0, 100);
    }
}
