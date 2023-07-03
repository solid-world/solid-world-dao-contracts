// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/compliance/VerificationRegistry.sol";
import "../../contracts/interfaces/compliance/IVerificationRegistry.sol";
import "../../contracts/CollateralizedBasketToken.sol";

abstract contract BaseCollateralizedBasketTokenTest is BaseTest {
    IVerificationRegistry verificationRegistry;
    CollateralizedBasketToken collateralizedBasketToken;

    address testAccount0 = vm.addr(1);
    address testAccount1 = vm.addr(2);
    address testAccount2 = vm.addr(3);

    event KYCRequiredSet(bool indexed kycRequired);

    function setUp() public {
        _initVerificationRegistry();

        collateralizedBasketToken = new CollateralizedBasketToken(
            "Mangrove Collateralized Basket Token",
            "MCBT",
            address(verificationRegistry)
        );

        _labelAccounts();
        _mintInitialTokens();
    }

    function _labelAccounts() private {
        vm.label(testAccount0, "testAccount0");
        vm.label(testAccount1, "testAccount1");
        vm.label(testAccount2, "testAccount2");
        vm.label(address(this), "CBTTest");
        vm.label(address(collateralizedBasketToken), "CBT");
        vm.label(address(verificationRegistry), "Verification Registry");
    }

    function _mintInitialTokens() private {
        collateralizedBasketToken.mint(testAccount0, 10000);
        collateralizedBasketToken.mint(testAccount1, 10000);
        collateralizedBasketToken.mint(testAccount2, 10000);
        collateralizedBasketToken.mint(address(this), 10000);
    }

    function _initVerificationRegistry() private {
        VerificationRegistry _verificationRegistry = new VerificationRegistry();
        _verificationRegistry.initialize(address(this));

        verificationRegistry = IVerificationRegistry(address(_verificationRegistry));
    }

    function _expectEmit_KYCRequiredSet(bool _kycRequired) internal {
        vm.expectEmit(true, true, false, false, address(collateralizedBasketToken));
        emit KYCRequiredSet(_kycRequired);
    }

    function _expectRevert_NotRegulatoryCompliant(address subject) internal {
        vm.expectRevert(
            abi.encodeWithSelector(CollateralizedBasketToken.NotRegulatoryCompliant.selector, subject)
        );
    }
}
