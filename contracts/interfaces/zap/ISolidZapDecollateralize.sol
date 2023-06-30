// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @author Solid World
interface ISolidZapDecollateralize {
    event ZapDecollateralize(
        address indexed receiver,
        address indexed inputToken,
        uint indexed inputAmount,
        uint dust,
        address dustReceiver,
        uint categoryId
    );

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
    /// 2. Decollateralizes resulting tokens to forward credits via SolidWorldManager
    /// 3. Transfers resulting forward credits to `msg.sender`
    /// 4. Transfers remaining crisp token balance of SolidZapDecollateralize to the `dustReceiver`
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
    /// 2. Decollateralizes resulting tokens to forward credits via SolidWorldManager
    /// 3. Transfers resulting forward credits to `recipient`
    /// 4. Transfers remaining crisp token balance of SolidZapDecollateralize to the `dustReceiver`
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
    /// @param recipient The address to receive forward credits
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
