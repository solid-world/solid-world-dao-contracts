// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/compliance/VerificationRegistry.sol";
import "../../contracts/CollateralizedBasketTokenDeployer.sol";

abstract contract BaseCollateralizedBasketTokenDeployerTest is BaseTest {
    address verificationRegistry = address(new VerificationRegistry());
    CollateralizedBasketTokenDeployer deployer;

    address testAccount0 = vm.addr(1);

    function setUp() public {
        deployer = new CollateralizedBasketTokenDeployer(verificationRegistry);
    }
}
