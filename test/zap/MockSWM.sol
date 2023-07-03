// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./TestERC1155.sol";
import "../TestToken.sol";

contract MockSWM is IERC1155Receiver {
    TestERC1155 private fcbt;
    TestToken private crispToken;

    constructor(TestERC1155 _fcbt, TestToken _crispToken) {
        fcbt = _fcbt;
        crispToken = _crispToken;
    }

    function collateralizeBatch(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external {
        fcbt.safeTransferFrom(msg.sender, address(this), batchId, amountIn, "");
        crispToken.mint(msg.sender, amountOutMin);
    }

    function bulkDecollateralizeTokens(
        uint[] calldata batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external {
        for (uint i; i < batchIds.length; i++) {
            crispToken.transferFrom(msg.sender, address(this), amountsIn[i]);
            fcbt.mint(msg.sender, batchIds[i], amountsOutMin[i], "");
        }
    }

    function getBatchCategory(uint) external pure returns (uint) {
        return 1;
    }

    function onERC1155Received(
        address,
        address,
        uint,
        uint,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint[] memory,
        uint[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // ERC165 && ERC1155TokenReceiver support
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x4e2312e0;
    }
}
