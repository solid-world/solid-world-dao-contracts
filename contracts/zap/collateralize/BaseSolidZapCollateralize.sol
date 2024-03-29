// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../../interfaces/zap/ISolidZapCollateralize.sol";
import "../../interfaces/staking/IWETH.sol";
import "../BaseZap.sol";

/// @author Solid World
abstract contract BaseSolidZapCollateralize is
    BaseZap,
    ISolidZapCollateralize,
    IERC1155Receiver,
    ReentrancyGuard
{
    address public immutable router;
    address public immutable weth;
    address public immutable swManager;
    address public immutable forwardContractBatch;

    constructor(
        address _router,
        address _weth,
        address _swManager,
        address _forwardContractBatch
    ) {
        router = _router;
        weth = _weth;
        swManager = _swManager;
        forwardContractBatch = _forwardContractBatch;

        IERC1155(forwardContractBatch).setApprovalForAll(swManager, true);
    }

    /// @dev accept transfers from this contract only
    function onERC1155Received(
        address operator,
        address,
        uint,
        uint,
        bytes memory
    ) public virtual returns (bytes4) {
        if (operator != address(this)) {
            return bytes4(0);
        }

        return this.onERC1155Received.selector;
    }

    /// @dev accept transfers from this contract only
    function onERC1155BatchReceived(
        address operator,
        address,
        uint[] memory,
        uint[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        if (operator != address(this)) {
            return bytes4(0);
        }

        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // ERC165 && ERC1155TokenReceiver support
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x4e2312e0;
    }

    receive() external payable {
        if (msg.sender != weth) {
            revert ETHTransferFailed();
        }
    }

    fallback() external payable {
        if (msg.sender != weth) {
            revert ETHTransferFailed();
        }
    }
}
