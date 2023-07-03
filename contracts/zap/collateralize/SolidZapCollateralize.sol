// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./BaseSolidZapCollateralize.sol";

interface SWManager {
    function collateralizeBatch(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external;

    function getBatchCategory(uint batchId) external view returns (uint);
}

/// @author Solid World
contract SolidZapCollateralize is BaseSolidZapCollateralize {
    using GPv2SafeERC20 for IERC20;

    constructor(
        address _router,
        address _weth,
        address _swManager,
        address _forwardContractBatch
    ) BaseSolidZapCollateralize(_router, _weth, _swManager, _forwardContractBatch) {}

    /// @inheritdoc ISolidZapCollateralize
    function zapCollateralize(
        address outputToken,
        address crispToken,
        uint batchId,
        uint amountIn,
        uint amountOutMin,
        bytes calldata swap,
        address dustReceiver
    ) external nonReentrant {
        _transferOverTheForwardCredits(batchId, amountIn);
        _collateralize(batchId, amountIn, amountOutMin);
    }

    /// @inheritdoc ISolidZapCollateralize
    function zapCollateralize(
        address outputToken,
        address crispToken,
        uint batchId,
        uint amountIn,
        uint amountOutMin,
        bytes calldata swap,
        address dustReceiver,
        address recipient
    ) external nonReentrant {
        _transferOverTheForwardCredits(batchId, amountIn);
        _collateralize(batchId, amountIn, amountOutMin);
    }

    function _transferOverTheForwardCredits(uint batchId, uint amountIn) private {
        IERC1155(forwardContractBatch).safeTransferFrom(msg.sender, address(this), batchId, amountIn, "");
    }

    function _collateralize(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) private {
        SWManager(swManager).collateralizeBatch(batchId, amountIn, amountOutMin);
    }
}
