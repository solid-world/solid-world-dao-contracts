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
        assertEq(manager.categoryIds(1), false);

        manager.addCategory(1, "Test token", "TT");

        assertNotEq(manager.categoryToken(1), address(0));
        assertEq(manager.categoryIds(1), true);
    }

    function testAddProject() public {
        assertEq(manager.projectIds(5), false);

        manager.addCategory(3, "Test token", "TT");
        manager.addProject(3, 5);

        assertEq(manager.projectIds(5), true);
    }

    function testAddMultipleProjects() public {
        assertEq(manager.getProjectIdsByCategory(3).length, 0);

        manager.addCategory(3, "Test token", "TT");
        manager.addProject(3, 5);
        manager.addProject(3, 7);

        assertEq(manager.getProjectIdsByCategory(3).length, 2);
        assertEq(manager.getProjectIdsByCategory(3)[0], 5);
        assertEq(manager.getProjectIdsByCategory(3)[1], 7);
    }

    function testFailAddProjectWhenCategoryDoesntExist() public {
        manager.addProject(3, 5);
    }

    function testFailAddProjectWhenProjectAlreadyAdded() public {
        manager.addCategory(3, "Test token", "TT");
        manager.addProject(3, 5);
        manager.addProject(3, 5);
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
