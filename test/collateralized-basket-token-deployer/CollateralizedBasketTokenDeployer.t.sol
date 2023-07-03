// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseCollateralizedBasketTokenDeployer.sol";

contract CollateralizedBasketTokenDeployerTest is BaseCollateralizedBasketTokenDeployerTest {
    function testGetVerificationRegistry() public {
        assertEq(deployer.getVerificationRegistry(), verificationRegistry);
    }

    function testSetVerificationRegistry_revertsIfNotOwner() public {
        address _verificationRegistry = vm.addr(1);

        vm.prank(testAccount0);
        _expectRevert_NotOwner();
        deployer.setVerificationRegistry(_verificationRegistry);
    }

    function testSetVerificationRegistry_setsRegistry() public {
        address _verificationRegistry = vm.addr(1);

        deployer.setVerificationRegistry(_verificationRegistry);
        assertEq(deployer.getVerificationRegistry(), _verificationRegistry);
    }

    function testDeploy_theERC20HasTheExpectedVerificationRegistry() public {
        CollateralizedBasketToken cbt = deployer.deploy("", "");
        assertEq(cbt.getVerificationRegistry(), verificationRegistry);
    }
}
