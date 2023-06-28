// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./BaseSolidZapDecollateralize.sol";

interface SWManager {
    function bulkDecollateralizeTokens(
        uint[] calldata batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external;
}

/// @author Solid World
contract SolidZapDecollateralize is BaseSolidZapDecollateralize {
    using GPv2SafeERC20 for IERC20;

    constructor(
        address _router,
        address _weth,
        address _swManager,
        address _forwardContractBatch
    ) BaseSolidZapDecollateralize(_router, _weth, _swManager, _forwardContractBatch) {}

    /// @inheritdoc ISolidZapDecollateralize
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

    /// @inheritdoc ISolidZapDecollateralize
    function zapDecollateralize(
        address inputToken,
        uint inputAmount,
        address crispToken,
        bytes calldata swap,
        address dustReceiver,
        DecollateralizeParams calldata decollateralizeParams,
        address recipient
    ) external nonReentrant {
        _prepareToSwap(inputToken, inputAmount);
        _zapDecollateralize(
            inputToken,
            inputAmount,
            crispToken,
            swap,
            dustReceiver,
            decollateralizeParams,
            recipient
        );
    }

    function _zapDecollateralize(
        address inputToken,
        uint inputAmount,
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
        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        _approveTokenSpendingIfNeeded(inputToken, router);
    }

    function _transferDust(address token, address dustReceiver) private {
        uint dustAmount = IERC20(token).balanceOf(address(this));
        if (dustAmount > 0) {
            IERC20(token).safeTransfer(dustReceiver, dustAmount);
        }
    }
}
