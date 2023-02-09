// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BaseSolidWorldManager.t.sol";

contract Attacker1 is IERC1155Receiver {
    uint constant BATCH_ID = 5;
    ForwardContractBatchToken forwardContractBatch;

    constructor(ForwardContractBatchToken _forwardContractBatch) {
        forwardContractBatch = _forwardContractBatch;
    }

    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        forwardContractBatch.setApprovalForAll(operator, true);
        SolidWorldManager(operator).decollateralizeTokens(BATCH_ID, 1, 0);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override returns (bytes4) {
        forwardContractBatch.setApprovalForAll(operator, true);
        SolidWorldManager(operator).decollateralizeTokens(BATCH_ID, 1, 0);
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x4e2312e0;
    }
}

contract Attacker2 is IERC1155Receiver {
    uint constant BATCH_ID = 5;
    uint constant ADD_BATCH_AMOUNT = 100;
    ForwardContractBatchToken forwardContractBatch;

    constructor(ForwardContractBatchToken _forwardContractBatch) {
        forwardContractBatch = _forwardContractBatch;
    }

    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256 amount,
        bytes calldata
    ) external override returns (bytes4) {
        if (amount == ADD_BATCH_AMOUNT) {
            return this.onERC1155Received.selector;
        }

        forwardContractBatch.setApprovalForAll(operator, true);
        SolidWorldManager(operator).decollateralizeTokens(BATCH_ID, 1, 0);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override returns (bytes4) {
        forwardContractBatch.setApprovalForAll(operator, true);
        SolidWorldManager(operator).decollateralizeTokens(BATCH_ID, 1, 0);
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x4e2312e0;
    }
}

contract ReentrancyTest is BaseSolidWorldManager {
    function testAddBatchReentrancy() public {
        Attacker1 attacker = new Attacker1(forwardContractBatch);

        manager.addCategory(CATEGORY_ID, "Test token", "TT", INITIAL_CATEGORY_TA);
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        _expectRevertWithMessage("ReentrancyGuard: reentrant call");
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                collateralizedCredits: 0,
                certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
                vintage: 2022,
                batchTA: 0,
                supplier: address(attacker),
                isAccumulating: false
            }),
            100
        );
    }

    function testDecollateralizeTokensReentrancy() public {
        Attacker2 attacker = new Attacker2(forwardContractBatch);

        _addCategoryAndProjectWithApprovedSpending();
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                collateralizedCredits: 0,
                certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
                vintage: 2022,
                batchTA: 0,
                supplier: address(attacker),
                isAccumulating: false
            }),
            100
        );

        vm.startPrank(address(attacker));
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.getCategoryToken(CATEGORY_ID).approve(address(manager), type(uint256).max);

        manager.collateralizeBatch(BATCH_ID, 10, 0);

        _expectRevertWithMessage("ReentrancyGuard: reentrant call");
        manager.decollateralizeTokens(BATCH_ID, 3e18, 0);

        vm.stopPrank();
    }

    function testBulkDecollateralizeTokensReentrancy() public {
        Attacker2 attacker = new Attacker2(forwardContractBatch);

        _addCategoryAndProjectWithApprovedSpending();
        manager.addBatch(
            DomainDataTypes.Batch({
                id: BATCH_ID,
                status: 0,
                projectId: PROJECT_ID,
                collateralizedCredits: 0,
                certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
                vintage: 2022,
                batchTA: 0,
                supplier: address(attacker),
                isAccumulating: false
            }),
            100
        );

        vm.startPrank(address(attacker));
        forwardContractBatch.setApprovalForAll(address(manager), true);
        manager.getCategoryToken(CATEGORY_ID).approve(address(manager), type(uint256).max);

        manager.collateralizeBatch(BATCH_ID, 10, 0);

        uint[] memory batchIds = new uint[](1);
        batchIds[0] = BATCH_ID;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 3e18;
        uint[] memory amountsOutMin = new uint[](1);
        amountsOutMin[0] = 0;

        _expectRevertWithMessage("ReentrancyGuard: reentrant call");
        manager.bulkDecollateralizeTokens(batchIds, amounts, amountsOutMin);

        vm.stopPrank();
    }
}
