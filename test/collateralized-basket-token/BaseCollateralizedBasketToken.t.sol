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

    event KYCRequiredSet(bool indexed kycRequired);

    function setUp() public {
        _initVerificationRegistry();

        collateralizedBasketToken = new CollateralizedBasketToken(
            "Mangrove Collateralized Basket Token",
            "MCBT",
            address(verificationRegistry)
        );

        _mintInitialTokens();
    }

    function _mintInitialTokens() private {
        collateralizedBasketToken.mint(testAccount0, 10000);
        collateralizedBasketToken.mint(testAccount1, 10000);
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
