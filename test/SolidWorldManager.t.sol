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

    function testAddBatch() public {
        manager.addCategory(3, "Test token", "TT");
        manager.addProject(3, 5);

        assertEq(manager.batchIds(7), false);

        manager.addBatch(
            SolidWorldManager.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                totalAmount: 10,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: address(this)
            })
        );

        assertEq(manager.batchIds(7), true);

        (
            uint256 id,
            uint8 status,
            uint256 projectId,
            uint256 totalAmount,
            uint32 expectedDueDate,
            uint8 discountRate,
            address owner
        ) = manager.batches(7);

        assertEq(id, 7);
        assertEq(status, 0);
        assertEq(projectId, 5);
        assertEq(totalAmount, 10);
        assertEq(expectedDueDate, uint32(block.timestamp + 12));
        assertEq(discountRate, 1);
        assertEq(owner, address(this));
    }

    function testAddMultipleBatches() public {
        manager.addCategory(3, "Test token", "TT");
        manager.addProject(3, 5);

        assertEq(manager.getBatchIdsByProject(5).length, 0);

        manager.addBatch(
            SolidWorldManager.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                totalAmount: 10,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: address(this)
            })
        );

        manager.addBatch(
            SolidWorldManager.Batch({
                id: 11,
                status: 0,
                projectId: 5,
                totalAmount: 20,
                expectedDueDate: uint32(block.timestamp + 24),
                discountRate: 1,
                owner: address(this)
            })
        );

        assertEq(manager.getBatchIdsByProject(5).length, 2);
        assertEq(manager.getBatchIdsByProject(5)[0], 7);
        assertEq(manager.getBatchIdsByProject(5)[1], 11);
    }

    function testFailAddBatchWhenProjectDoesntExist() public {
        manager.addBatch(
            SolidWorldManager.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                totalAmount: 10,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: address(this)
            })
        );
    }

    function testFailAddBatchWhenBatchAlreadyAdded() public {
        manager.addCategory(3, "Test token", "TT");
        manager.addProject(3, 5);

        manager.addBatch(
            SolidWorldManager.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                totalAmount: 10,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: address(this)
            })
        );

        manager.addBatch(
            SolidWorldManager.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                totalAmount: 10,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: address(this)
            })
        );
    }

    function testFailAddBatchWhenOwnerIsNotDefined() public {
        manager.addCategory(3, "Test token", "TT");
        manager.addProject(3, 5);

        manager.addBatch(
            SolidWorldManager.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                totalAmount: 10,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: address(0)
            })
        );
    }

    function testFailAddBatchWhenDueDateIsNow() public {
        manager.addCategory(3, "Test token", "TT");
        manager.addProject(3, 5);

        manager.addBatch(
            SolidWorldManager.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                totalAmount: 10,
                expectedDueDate: uint32(block.timestamp),
                discountRate: 1,
                owner: address(0)
            })
        );
    }

    function testFailAddBatchWhenDueDateInThePast() public {
        manager.addCategory(3, "Test token", "TT");
        manager.addProject(3, 5);

        manager.addBatch(
            SolidWorldManager.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                totalAmount: 10,
                expectedDueDate: uint32(block.timestamp - 1),
                discountRate: 1,
                owner: address(0)
            })
        );
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
