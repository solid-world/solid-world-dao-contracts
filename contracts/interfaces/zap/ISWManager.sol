// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @author Solid World
/// @dev The minimal interface used to interact with SolidWorldManager
interface ISWManager {
    function collateralizeBatch(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external;

    function bulkDecollateralizeTokens(
        uint[] calldata batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external;

    function getBatchCategory(uint batchId) external view returns (uint);
}
