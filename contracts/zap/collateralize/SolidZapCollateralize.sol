// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./BaseSolidZapCollateralize.sol";

/// @author Solid World
contract SolidZapCollateralize is BaseSolidZapCollateralize {
    constructor(
        address _router,
        address _weth,
        address _swManager,
        address _forwardContractBatch
    ) BaseSolidZapCollateralize(_router, _weth, _swManager, _forwardContractBatch) {}
}
