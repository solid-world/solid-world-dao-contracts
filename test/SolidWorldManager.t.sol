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

        ForwardContractBatchToken forwardContractBatch = new ForwardContractBatchToken("");
        forwardContractBatch.transferOwnership(address(manager));

        manager.initialize(forwardContractBatch);
    }

    function testAddCategory() public {
        assertEq(address(manager.categoryToken(1)), address(0));
        assertEq(manager.categoryIds(1), false);

        manager.addCategory(1, "Test token", "TT");

        assertNotEq(address(manager.categoryToken(1)), address(0));
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
                owner: vm.addr(1)
            })
        );

        assertEq(manager.batchIds(7), true);

        (
            uint id,
            uint projectId,
            uint totalAmount,
            address owner,
            uint32 expectedDueDate,
            uint8 status,
            uint8 discountRate
        ) = manager.batches(7);

        assertEq(id, 7);
        assertEq(status, 0);
        assertEq(projectId, 5);
        assertEq(totalAmount, 10);
        assertEq(expectedDueDate, uint32(block.timestamp + 12));
        assertEq(discountRate, 1);
        assertEq(owner, vm.addr(1));
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
                owner: vm.addr(1)
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
                owner: vm.addr(1)
            })
        );

        assertEq(manager.getBatchIdsByProject(5).length, 2);
        assertEq(manager.getBatchIdsByProject(5)[0], 7);
        assertEq(manager.getBatchIdsByProject(5)[1], 11);
    }

    function testAddBatchIssuesERC1155Tokens() public {
        manager.addCategory(3, "Test token", "TT");
        manager.addProject(3, 5);

        assertEq(manager.forwardContractBatch().balanceOf(address(this), 7), 0);

        manager.addBatch(
            SolidWorldManager.Batch({
                id: 7,
                status: 0,
                projectId: 5,
                totalAmount: 10,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: vm.addr(1)
            })
        );

        assertEq(manager.forwardContractBatch().balanceOf(vm.addr(1), 7), 10);
    }

    function testFailCollateralizeBatchWhenInvalidBatchId() public {
        manager.collateralizeBatch(1, 0);
    }

    function testFailCollateralizeBatchWhenNotEnoughFunds() public {
        manager.addCategory(1, "Test token", "TT");
        manager.addProject(1, 1);
        manager.addBatch(
            SolidWorldManager.Batch({
                id: 1,
                status: 0,
                projectId: 1,
                totalAmount: 100,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: vm.addr(1)
            })
        );

        manager.collateralizeBatch(1, 1000);
    }

    function testCollateralizeBatchMintsERC20AndTransfersERC1155ToManager() public {
        manager.addCategory(1, "Test token", "TT");
        manager.addProject(1, 1);
        manager.addBatch(
            SolidWorldManager.Batch({
                id: 1,
                status: 0,
                projectId: 1,
                totalAmount: 100,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: vm.addr(1)
            })
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(vm.addr(1));
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(1, 100);
        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(vm.addr(1), 1), 0);
        assertEq(forwardContractBatch.balanceOf(address(manager), 1), 100);
        assertEq(manager.categoryToken(1).balanceOf(vm.addr(1)), 100);
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
                owner: vm.addr(1)
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
                owner: vm.addr(1)
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
                owner: vm.addr(1)
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
                owner: vm.addr(1)
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
                owner: vm.addr(1)
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
