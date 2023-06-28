// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @author Solid World
interface ISolidZapDecollateralize {
    event ZapDecollateralize();

    struct DecollateralizeParams {
        uint[] batchIds;
        uint[] amountsIn;
        uint[] amountsOutMin;
    }

    function router() external view returns (address);

    function weth() external view returns (address);

    function swManager() external view returns (address);

    function forwardContractBatch() external view returns (address);

    /// @notice Zap function that achieves the following:
    /// 1. Swaps `inputToken` to `crispToken` via encoded swap
    /// 2. Resulting tokens are decollateralized to forward credits via SolidWorldManager
    /// 3. The resulting forward credits are transferred to `msg.sender`
    /// 4. Any remaining crisp token balance of SolidZapDecollateralize will be transferred to the `dustReceiver`
    /// @notice The `msg.sender` must own `inputAmount` and approve this contract to spend `inputToken`
    /// @param inputToken The token used for obtaining forward credits
    /// @param inputAmount The amount of `inputToken` to use
    /// @param crispToken The intermediate token used for redeeming forward credits
    /// @param swap Encoded swap from `inputToken` to `crispToken`
    /// @param dustReceiver Address to receive any remaining crisp tokens dust
    /// @param decollateralizeParams Parameters for decollateralization
    ///  batchIds The batch ids of the forward credits to redeem
    ///  amountsIn The amounts of `crispToken` to used to redeem forward credits
    ///  amountsOutMin The minimum amounts of forward credits to receive
    function zapDecollateralize(
        address inputToken,
        uint inputAmount,
        address crispToken,
        bytes calldata swap,
        address dustReceiver,
        DecollateralizeParams calldata decollateralizeParams
    ) external;

    /// @notice Zap function that achieves the following:
    /// 1. Swaps `inputToken` to `crispToken` via encoded swap
    /// 2. Resulting tokens are decollateralized to forward credits via SolidWorldManager
    /// 3. The resulting forward credits are transferred to `recipient`
    /// 4. Any remaining crisp token balance of SolidZapDecollateralize will be transferred to the `dustReceiver`
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @param inputToken The token used for obtaining forward credits
    /// @param inputAmount The amount of `inputToken` to use
    /// @param crispToken The intermediate token used for redeeming forward credits
    /// @param swap Encoded swap from `inputToken` to `crispToken`
    /// @param dustReceiver Address to receive any remaining crisp tokens dust
    /// @param decollateralizeParams Parameters for decollateralization
    ///  batchIds The batch ids of the forward credits to redeem
    ///  amountsIn The amounts of `crispToken` to used to redeem forward credits
    ///  amountsOutMin The minimum amounts of forward credits to receive
    /// @param recipient The address to receive the crisp tokens dust
    function zapDecollateralize(
        address inputToken,
        uint inputAmount,
        address crispToken,
        bytes calldata swap,
        address dustReceiver,
        DecollateralizeParams calldata decollateralizeParams,
        address recipient
    ) external;
}
