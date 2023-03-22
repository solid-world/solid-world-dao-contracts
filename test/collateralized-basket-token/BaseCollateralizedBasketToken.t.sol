// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/compliance/VerificationRegistry.sol";
import "../../contracts/interfaces/compliance/IVerificationRegistry.sol";
import "../../contracts/CollateralizedBasketToken.sol";

abstract contract BaseCollateralizedBasketTokenTest is BaseTest {
    IVerificationRegistry verificationRegistry;
    CollateralizedBasketToken collateralizedBasketToken;

    function setUp() public {
        _initVerificationRegistry();

        collateralizedBasketToken = new CollateralizedBasketToken(
            "Mangrove Collateralized Basket Token",
            "MCBT",
            address(verificationRegistry)
        );
    }

    function _initVerificationRegistry() private {
        VerificationRegistry _verificationRegistry = new VerificationRegistry();
        _verificationRegistry.initialize(address(this));

        verificationRegistry = IVerificationRegistry(address(_verificationRegistry));
    }
}
