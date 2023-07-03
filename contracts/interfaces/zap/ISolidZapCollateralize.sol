// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @author Solid World
interface ISolidZapCollateralize {
    function router() external view returns (address);

    function weth() external view returns (address);

    function swManager() external view returns (address);

    function forwardContractBatch() external view returns (address);

    /// @notice Zap function that achieves the following:
    /// 1. Transfers `amountIn` forward credits with batch id `batchId` to this contract
    /// 2. Collateralizes the transferred forward credits via SolidWorldManager, receives `crispToken`
    /// 3. Swaps `crispToken` for `outputToken` via encoded swap
    /// 4. Transfers the `outputToken` balance of SolidZapCollateralize to `msg.sender`
    /// 5. Transfers remaining crisp token balance of SolidZapCollateralize to the `dustReceiver`
    /// @notice The `msg.sender` must approve this contract to spend the forward credits
    /// @param outputToken The token used for obtaining forward credits
    /// @param crispToken The intermediate token used for redeeming forward credits
    /// @param batchId The batch id of the forward credits to collateralize
    /// @param amountIn The amounts of forward credits to collateralize
    /// @param amountOutMin The minimum amounts of `crispToken` to receive from collateralization
    /// @param swap Encoded swap from `crispToken` to `outputToken`
    /// @param dustReceiver Address to receive any remaining `crispToken` dust
    function zapCollateralize(
        address outputToken,
        address crispToken,
        uint batchId,
        uint amountIn,
        uint amountOutMin,
        bytes calldata swap,
        address dustReceiver
    ) external;

    /// @notice Zap function that achieves the following:
    /// 1. Transfers `amountIn` forward credits with batch id `batchId` to this contract
    /// 2. Collateralizes the transferred forward credits via SolidWorldManager, receives `crispToken`
    /// 3. Swaps `crispToken` for `outputToken` via encoded swap
    /// 4. Transfers the `outputToken` balance of SolidZapCollateralize to `recipient`
    /// 5. Transfers remaining crisp token balance of SolidZapCollateralize to the `dustReceiver`
    /// @notice The `msg.sender` must approve this contract to spend the forward credits
    /// @param outputToken The token used for obtaining forward credits
    /// @param crispToken The intermediate token used for redeeming forward credits
    /// @param batchId The batch id of the forward credits to collateralize
    /// @param amountIn The amounts of forward credits to collateralize
    /// @param amountOutMin The minimum amounts of `crispToken` to receive from collateralization
    /// @param swap Encoded swap from `crispToken` to `outputToken`
    /// @param dustReceiver Address to receive any remaining `crispToken` dust
    /// @param recipient Address to receive the resulting `outputToken` amount
    function zapCollateralize(
        address outputToken,
        address crispToken,
        uint batchId,
        uint amountIn,
        uint amountOutMin,
        bytes calldata swap,
        address dustReceiver,
        address recipient
    ) external;
}
