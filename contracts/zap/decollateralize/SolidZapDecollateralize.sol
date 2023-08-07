// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./BaseSolidZapDecollateralize.sol";

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
        address dustRecipient,
        DecollateralizeParams calldata decollateralizeParams
    ) external nonReentrant {
        _prepareToSwap(inputToken, inputAmount, router);
        _zapDecollateralize(
            inputToken,
            inputAmount,
            crispToken,
            swap,
            dustRecipient,
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
        address dustRecipient,
        DecollateralizeParams calldata decollateralizeParams,
        address zapRecipient
    ) external nonReentrant {
        _prepareToSwap(inputToken, inputAmount, router);
        _zapDecollateralize(
            inputToken,
            inputAmount,
            crispToken,
            swap,
            dustRecipient,
            decollateralizeParams,
            zapRecipient
        );
    }

    /// @inheritdoc ISolidZapDecollateralize
    function zapDecollateralizeETH(
        address crispToken,
        bytes calldata swap,
        address dustRecipient,
        DecollateralizeParams calldata decollateralizeParams
    ) external payable nonReentrant {
        _wrap(weth, msg.value);
        _zapDecollateralize(
            weth,
            msg.value,
            crispToken,
            swap,
            dustRecipient,
            decollateralizeParams,
            msg.sender
        );
    }

    /// @inheritdoc ISolidZapDecollateralize
    function zapDecollateralizeETH(
        address crispToken,
        bytes calldata swap,
        address dustRecipient,
        DecollateralizeParams calldata decollateralizeParams,
        address zapRecipient
    ) external payable nonReentrant {
        _wrap(weth, msg.value);
        _zapDecollateralize(
            weth,
            msg.value,
            crispToken,
            swap,
            dustRecipient,
            decollateralizeParams,
            zapRecipient
        );
    }

    function _zapDecollateralize(
        address inputToken,
        uint inputAmount,
        address crispToken,
        bytes calldata swap,
        address dustRecipient,
        DecollateralizeParams calldata decollateralizeParams,
        address zapRecipient
    ) private {
        _swapViaRouter(router, swap);
        _approveTokenSpendingIfNeeded(crispToken, swManager);
        ISWManager(swManager).bulkDecollateralizeTokens(
            decollateralizeParams.batchIds,
            decollateralizeParams.amountsIn,
            decollateralizeParams.amountsOutMin
        );
        IERC1155(forwardContractBatch).safeBatchTransferFrom(
            address(this),
            zapRecipient,
            decollateralizeParams.batchIds,
            _getDecollateralizedForwardCreditAmounts(decollateralizeParams.batchIds),
            ""
        );
        uint dustAmount = _sweepTokensTo(crispToken, dustRecipient);
        uint categoryId = ISWManager(swManager).getBatchCategory(decollateralizeParams.batchIds[0]);

        emit ZapDecollateralize(zapRecipient, inputToken, inputAmount, dustAmount, dustRecipient, categoryId);
    }

    function _getDecollateralizedForwardCreditAmounts(uint[] calldata batchIds)
        private
        view
        returns (uint[] memory decollateralizedForwardCreditAmounts)
    {
        address[] memory addresses = new address[](1);
        addresses[0] = address(this);
        decollateralizedForwardCreditAmounts = IERC1155(forwardContractBatch).balanceOfBatch(
            addresses,
            batchIds
        );
    }
}
