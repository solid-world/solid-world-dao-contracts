// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/interfaces/staking/IWETH.sol";

interface SWManager {
    function bulkDecollateralizeTokens(
        uint[] calldata batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external;
}

contract SolidZapDecollateralize_0_8_16 is IERC1155Receiver, ReentrancyGuard {
    address public immutable router;
    address public immutable weth;
    address public immutable swManager;
    address public immutable forwardContractBatch;

    error GenericSwapError();
    error InvalidInput();

    event ZapDecollateralize();

    struct DecollateralizeParams {
        uint[] batchIds;
        uint[] amountsIn;
        uint[] amountsOutMin;
    }

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

        IWETH(weth).approve(_router, type(uint).max);
    }

    /// @dev accept transfers from swManager contract only
    function onERC1155Received(
        address operator,
        address,
        uint,
        uint,
        bytes memory
    ) public virtual returns (bytes4) {
        if (operator != swManager) {
            return bytes4(0);
        }

        return this.onERC1155Received.selector;
    }

    /// @dev accept transfers from swManager contract only
    function onERC1155BatchReceived(
        address operator,
        address,
        uint[] memory,
        uint[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        if (operator != swManager) {
            return bytes4(0);
        }

        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // ERC165 && ERC1155TokenReceiver support
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x4e2312e0;
    }

    function zapDecollateralize(
        address inputToken,
        uint inputAmount,
        address crispToken,
        bytes calldata swap,
        address dustReceiver,
        DecollateralizeParams calldata decollateralizeParams
    ) external nonReentrant {
        _prepareToSwap(inputToken, inputAmount);
        _zapDecollateralize(
            inputToken,
            inputAmount,
            crispToken,
            swap,
            dustReceiver,
            decollateralizeParams,
            msg.sender
        );
    }

    function _zapDecollateralize(
        address,
        uint,
        address crispToken,
        bytes calldata swap,
        address dustReceiver,
        DecollateralizeParams calldata decollateralizeParams,
        address recipient
    ) private {
        _swapViaRouter(router, swap);
        _approveTokenSpendingIfNeeded(crispToken, swManager);
        SWManager(swManager).bulkDecollateralizeTokens(
            decollateralizeParams.batchIds,
            decollateralizeParams.amountsIn,
            decollateralizeParams.amountsOutMin
        );
        IERC1155(forwardContractBatch).safeBatchTransferFrom(
            address(this),
            recipient,
            decollateralizeParams.batchIds,
            decollateralizeParams.amountsOutMin,
            ""
        );
        _transferDust(crispToken, dustReceiver);
        emit ZapDecollateralize();
    }

    function _prepareToSwap(address inputToken, uint inputAmount) private {
        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
        _approveTokenSpendingIfNeeded(inputToken, router);
    }

    function _transferDust(address token, address dustReceiver) private {
        uint dustAmount = IERC20(token).balanceOf(address(this));
        if (dustAmount > 0) {
            IERC20(token).transfer(dustReceiver, dustAmount);
        }
    }

    function _swapViaRouter(address _router, bytes calldata encodedSwap) internal {
        (bool success, bytes memory retData) = _router.call(encodedSwap);

        if (!success) {
            _propagateError(retData);
        }
    }

    function _propagateError(bytes memory revertReason) internal pure {
        if (revertReason.length == 0) {
            revert GenericSwapError();
        }

        assembly {
            revert(add(32, revertReason), mload(revertReason))
        }
    }

    function _wrap(address _weth, uint amount) internal {
        IWETH(_weth).deposit{ value: amount }();
    }

    function _approveTokenSpendingIfNeeded(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).approve(spender, type(uint).max);
        }
    }
}
