// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "../contracts/SolidWorldManager.sol";

contract SolidWorldManagerTest is Test {
    SolidWorldManager manager;
    address root = address(this);
    address ownerAddress = vm.addr(1);

    function setUp() public {
        manager = new SolidWorldManager();
        manager.initialize(new Erc20Deployer());
    }

    function testAddCategory() public {
        assertEq(manager.categoryToken(1), address(0));
        manager.addCategory(1, "Test token", "TT");
        assertNotEq(manager.categoryToken(1), address(0));
    }

    function assertNotEq(address a, address b) private {
        if (a == b) {
            emit log("Error: a != b not satisfied [address]");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }
}
