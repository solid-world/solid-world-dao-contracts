// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "../contracts/Erc20Deployer.sol";
import "../contracts/CTERC20.sol";

contract CTTreasuryTest is Test {
    Erc20Deployer private erc20Deployer;

    address root = address(this);
    address internal ownerAddress = vm.addr(1);
    CTERC20TokenTemplate token;

    function setUp() public {
        erc20Deployer = new Erc20Deployer();
        address tokenAddress = erc20Deployer.deploy(ownerAddress, "Test Token", "TT");
        token = CTERC20TokenTemplate(tokenAddress);
    }

    function testTokenDeploy() public {
        assertEq(token.balanceOf(root), 0);
    }

    function testMintAsOwner() public {
        vm.prank(ownerAddress);
        token.mint(root, 3);
        assertEq(token.balanceOf(root), 3);
    }

    function testFailMintAsNotOwner() public {
        token.mint(root, 5);
    }
}
