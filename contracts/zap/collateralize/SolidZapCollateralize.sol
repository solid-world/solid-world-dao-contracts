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
        _collateralizeToOutputToken(crispToken, batchId, amountIn, amountOutMin, swap);
        uint outputAmount = _sweepTokensTo(outputToken, msg.sender);
        uint dust = _sweepTokensTo(crispToken, dustReceiver);

        _emitZapEvent(msg.sender, batchId, outputToken, outputAmount, dust, dustReceiver);
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
        _collateralizeToOutputToken(crispToken, batchId, amountIn, amountOutMin, swap);
        uint outputAmount = _sweepTokensTo(outputToken, recipient);
        uint dust = _sweepTokensTo(crispToken, dustReceiver);

        _emitZapEvent(recipient, batchId, outputToken, outputAmount, dust, dustReceiver);
    }

    /// @inheritdoc ISolidZapCollateralize
    function zapCollateralizeETH(
        address crispToken,
        uint batchId,
        uint amountIn,
        uint amountOutMin,
        bytes calldata swap,
        address dustReceiver
    ) external nonReentrant {
        _collateralizeToOutputToken(crispToken, batchId, amountIn, amountOutMin, swap);
        uint outputAmount = _sweepETHTo(msg.sender);
        uint dust = _sweepTokensTo(crispToken, dustReceiver);

        _emitZapEvent(msg.sender, batchId, weth, outputAmount, dust, dustReceiver);
    }

    /// @inheritdoc ISolidZapCollateralize
    function zapCollateralizeETH(
        address crispToken,
        uint batchId,
        uint amountIn,
        uint amountOutMin,
        bytes calldata swap,
        address dustReceiver,
        address recipient
    ) external nonReentrant {
        _collateralizeToOutputToken(crispToken, batchId, amountIn, amountOutMin, swap);
        uint outputAmount = _sweepETHTo(recipient);
        uint dust = _sweepTokensTo(crispToken, dustReceiver);

        _emitZapEvent(recipient, batchId, weth, outputAmount, dust, dustReceiver);
    }

    function _collateralizeToOutputToken(
        address crispToken,
        uint batchId,
        uint amountIn,
        uint amountOutMin,
        bytes calldata swap
    ) private {
        _transferOverTheForwardCredits(batchId, amountIn);
        _collateralize(batchId, amountIn, amountOutMin);
        _approveTokenSpendingIfNeeded(crispToken, router);
        _swapViaRouter(router, swap);
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

    function _sweepETHTo(address recipient) private returns (uint sweptAmount) {
        sweptAmount = IERC20(weth).balanceOf(address(this));
        if (sweptAmount == 0) {
            return 0;
        }

        IWETH(weth).withdraw(sweptAmount);
        (bool success, ) = payable(recipient).call{ value: sweptAmount }("");
        if (!success) {
            revert ETHTransferFailed();
        }
    }

    function _emitZapEvent(
        address receiver,
        uint batchId,
        address outputToken,
        uint outputAmount,
        uint dust,
        address dustReceiver
    ) private {
        emit ZapCollateralize(
            receiver,
            outputToken,
            outputAmount,
            dust,
            dustReceiver,
            SWManager(swManager).getBatchCategory(batchId)
        );
    }
}
