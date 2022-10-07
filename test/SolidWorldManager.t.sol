// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "../contracts/SolidWorldManager.sol";

contract SolidWorldManagerTest is Test {
    SolidWorldManager manager;
    address root = address(this);
    address ownerAddress = vm.addr(1);

    uint constant CATEGORY_ID = 1;
    uint constant PROJECT_ID = 3;
    uint constant BATCH_ID = 5;

    event BatchCollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed batchOwner
    );
    event TokensDecollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed tokensOwner
    );

    function setUp() public {
        manager = new SolidWorldManager();

        ForwardContractBatchToken forwardContractBatch = new ForwardContractBatchToken("");
        forwardContractBatch.transferOwnership(address(manager));

        manager.initialize(forwardContractBatch, 50, 80_000);

        vm.label(vm.addr(1), "Dummy account 1");
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

    function testCollateralizeBatchWhenInvalidBatchId() public {
        vm.expectRevert(abi.encodePacked("Collateralize batch: invalid batchId."));
        manager.collateralizeBatch(CATEGORY_ID, 0, 0);
    }

    function testCollateralizeBatchWhenNotEnoughFunds() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT");
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            SolidWorldManager.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                totalAmount: 100,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: vm.addr(1)
            })
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(vm.addr(1));
        forwardContractBatch.setApprovalForAll(address(manager), true);
        vm.expectRevert(abi.encodePacked("ERC1155: insufficient balance for transfer"));
        manager.collateralizeBatch(BATCH_ID, 1000, 1000);
        vm.stopPrank();
    }

    function testCollateralizeBatchWhenERC20OutputIsLessThanMinimum() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT");
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            SolidWorldManager.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                totalAmount: 100,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: vm.addr(1)
            })
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(vm.addr(1));
        forwardContractBatch.setApprovalForAll(address(manager), true);
        vm.expectRevert(abi.encodePacked("Collateralize batch: amountOut < amountOutMin."));
        manager.collateralizeBatch(BATCH_ID, 100, 101);
        vm.stopPrank();
    }

    function testCollateralizeBatchMintsERC20AndTransfersERC1155ToManager() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT");
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            SolidWorldManager.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                totalAmount: 100,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: vm.addr(1)
            })
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();

        vm.startPrank(vm.addr(1));
        forwardContractBatch.setApprovalForAll(address(manager), true);

        vm.expectEmit(true, true, false, true, address(manager));
        emit BatchCollateralized(BATCH_ID, 100, 100, vm.addr(1));
        manager.collateralizeBatch(BATCH_ID, 100, 100);

        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(vm.addr(1), BATCH_ID), 0);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 100);
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(vm.addr(1)), 100);
    }

    function testDecollateralizeTokensWhenInvalidBatchId() public {
        vm.expectRevert(abi.encodePacked("Decollateralize batch: invalid batchId."));
        manager.decollateralizeTokens(BATCH_ID, 10, 5);
    }

    function testDecollateralizeTokensWhenNotEnoughFunds() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT");
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            SolidWorldManager.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                totalAmount: 100,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: vm.addr(1)
            })
        );

        vm.expectRevert(abi.encodePacked("ERC20: insufficient allowance"));
        manager.decollateralizeTokens(BATCH_ID, 1000, 500);
    }

    function testDecollateralizeTokensBurnsWhenERC1155OutputIsLessThanMinimum() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT");
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            SolidWorldManager.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                totalAmount: 100,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: vm.addr(1)
            })
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.categoryToken(CATEGORY_ID);

        vm.startPrank(vm.addr(1));
        collateralizedToken.approve(address(manager), 75);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 90, 90);
        vm.expectRevert(abi.encodePacked("Decollateralize batch: amountOut < amountOutMin."));
        manager.decollateralizeTokens(BATCH_ID, 75, 100);
        vm.stopPrank();
    }

    function testDecollateralizeTokensBurnsERC20AndReceivesERC1155() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT");
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addBatch(
            SolidWorldManager.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                totalAmount: 100,
                expectedDueDate: uint32(block.timestamp + 12),
                discountRate: 1,
                owner: vm.addr(1)
            })
        );

        ForwardContractBatchToken forwardContractBatch = manager.forwardContractBatch();
        CollateralizedBasketToken collateralizedToken = manager.categoryToken(CATEGORY_ID);

        vm.startPrank(vm.addr(1));
        collateralizedToken.approve(address(manager), 75);
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.collateralizeBatch(BATCH_ID, 90, 90);

        vm.expectEmit(true, true, false, true, address(manager));
        emit TokensDecollateralized(BATCH_ID, 75, 75, vm.addr(1));
        manager.decollateralizeTokens(BATCH_ID, 75, 75);

        vm.stopPrank();

        assertEq(forwardContractBatch.balanceOf(vm.addr(1), BATCH_ID), 100 - 90 + 75);
        assertEq(forwardContractBatch.balanceOf(address(manager), BATCH_ID), 90 - 75);
        assertEq(manager.categoryToken(CATEGORY_ID).balanceOf(vm.addr(1)), 90 - 75);
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
