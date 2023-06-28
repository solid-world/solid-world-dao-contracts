// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./BaseSolidZapDecollateralize.sol";

/// @author Solid World
contract SolidZapDecollateralize is BaseSolidZapDecollateralize {
    constructor(
        address _router,
        address _weth,
        address _swManager,
        address _forwardContractBatch
    ) BaseSolidZapDecollateralize(_router, _weth, _swManager, _forwardContractBatch) {}
}
