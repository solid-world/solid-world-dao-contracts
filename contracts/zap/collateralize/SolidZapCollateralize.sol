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
}
