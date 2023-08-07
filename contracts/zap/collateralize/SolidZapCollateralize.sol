// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./BaseSolidZapCollateralize.sol";

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
        address dustRecipient
    ) external nonReentrant {
        _collateralizeToOutputToken(crispToken, batchId, amountIn, amountOutMin, swap);
        uint outputAmount = _sweepTokensTo(outputToken, msg.sender, true);
        uint dust = _sweepTokensTo(crispToken, dustRecipient);

        _emitZapEvent(msg.sender, batchId, outputToken, outputAmount, dust, dustRecipient);
    }

    /// @inheritdoc ISolidZapCollateralize
    function zapCollateralize(
        address outputToken,
        address crispToken,
        uint batchId,
        uint amountIn,
        uint amountOutMin,
        bytes calldata swap,
        address dustRecipient,
        address zapRecipient
    ) external nonReentrant {
        _collateralizeToOutputToken(crispToken, batchId, amountIn, amountOutMin, swap);
        uint outputAmount = _sweepTokensTo(outputToken, zapRecipient, true);
        uint dust = _sweepTokensTo(crispToken, dustRecipient);

        _emitZapEvent(zapRecipient, batchId, outputToken, outputAmount, dust, dustRecipient);
    }

    /// @inheritdoc ISolidZapCollateralize
    function zapCollateralizeETH(
        address crispToken,
        uint batchId,
        uint amountIn,
        uint amountOutMin,
        bytes calldata swap,
        address dustRecipient
    ) external nonReentrant {
        _collateralizeToOutputToken(crispToken, batchId, amountIn, amountOutMin, swap);
        uint outputAmount = _sweepETHTo(msg.sender);
        uint dust = _sweepTokensTo(crispToken, dustRecipient);

        _emitZapEvent(msg.sender, batchId, weth, outputAmount, dust, dustRecipient);
    }

    /// @inheritdoc ISolidZapCollateralize
    function zapCollateralizeETH(
        address crispToken,
        uint batchId,
        uint amountIn,
        uint amountOutMin,
        bytes calldata swap,
        address dustRecipient,
        address zapRecipient
    ) external nonReentrant {
        _collateralizeToOutputToken(crispToken, batchId, amountIn, amountOutMin, swap);
        uint outputAmount = _sweepETHTo(zapRecipient);
        uint dust = _sweepTokensTo(crispToken, dustRecipient);

        _emitZapEvent(zapRecipient, batchId, weth, outputAmount, dust, dustRecipient);
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
        ISWManager(swManager).collateralizeBatch(batchId, amountIn, amountOutMin);
    }

    function _sweepETHTo(address zapRecipient) private returns (uint sweptAmount) {
        sweptAmount = IERC20(weth).balanceOf(address(this));
        if (sweptAmount == 0) {
            revert SweepAmountZero();
        }

        IWETH(weth).withdraw(sweptAmount);
        (bool success, ) = payable(zapRecipient).call{ value: sweptAmount }("");
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
        address dustRecipient
    ) private {
        emit ZapCollateralize(
            receiver,
            outputToken,
            outputAmount,
            dust,
            dustRecipient,
            ISWManager(swManager).getBatchCategory(batchId)
        );
    }
}
