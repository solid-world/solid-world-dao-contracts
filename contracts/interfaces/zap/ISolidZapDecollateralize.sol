// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @author Solid World
interface ISolidZapDecollateralize {
    event ZapDecollateralize(
        address indexed receiver,
        address indexed inputToken,
        uint indexed inputAmount,
        uint dust,
        address dustRecipient,
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
    /// 4. Transfers remaining crisp token balance of SolidZapDecollateralize to the `dustRecipient`
    /// 5. Transfers any remaining input token balance of SolidZapDecollateralize to `msg.sender`
    /// @notice The `msg.sender` must own `inputAmount` and approve this contract to spend `inputToken`
    /// @param inputToken The token used for redeeming forward credits
    /// @param inputAmount The amount of `inputToken` to use
    /// @param crispToken The intermediate token used for redeeming forward credits
    /// @param swap Encoded swap from `inputToken` to `crispToken`
    /// @param dustRecipient Address to receive any remaining crisp tokens dust
    /// @param decollateralizeParams Parameters for decollateralization
    ///  batchIds The batch ids of the forward credits to redeem
    ///  amountsIn The amounts of `crispToken` to used to redeem forward credits
    ///  amountsOutMin The minimum amounts of forward credits to receive
    function zapDecollateralize(
        address inputToken,
        uint inputAmount,
        address crispToken,
        bytes calldata swap,
        address dustRecipient,
        DecollateralizeParams calldata decollateralizeParams
    ) external;

    /// @notice Zap function that achieves the following:
    /// 1. Swaps `inputToken` to `crispToken` via encoded swap
    /// 2. Decollateralizes resulting tokens to forward credits via SolidWorldManager
    /// 3. Transfers resulting forward credits to `zapRecipient`
    /// 4. Transfers remaining crisp token balance of SolidZapDecollateralize to the `dustRecipient`
    /// 5. Transfers any remaining input token balance of SolidZapDecollateralize to `zapRecipient`
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @param inputToken The token used for redeeming forward credits
    /// @param inputAmount The amount of `inputToken` to use
    /// @param crispToken The intermediate token used for redeeming forward credits
    /// @param swap Encoded swap from `inputToken` to `crispToken`
    /// @param dustRecipient Address to receive any remaining crisp tokens dust
    /// @param decollateralizeParams Parameters for decollateralization
    ///  batchIds The batch ids of the forward credits to redeem
    ///  amountsIn The amounts of `crispToken` to used to redeem forward credits
    ///  amountsOutMin The minimum amounts of forward credits to receive
    /// @param zapRecipient The address to receive forward credits
    function zapDecollateralize(
        address inputToken,
        uint inputAmount,
        address crispToken,
        bytes calldata swap,
        address dustRecipient,
        DecollateralizeParams calldata decollateralizeParams,
        address zapRecipient
    ) external;

    /// @notice Zap function that achieves the following:
    /// 1. Wraps `msg.value` to WETH
    /// 2. Swaps `WETH` to `crispToken` via encoded swap
    /// 3. Decollateralizes resulting tokens to forward credits via SolidWorldManager
    /// 4. Transfers resulting forward credits to `msg.sender`
    /// 5. Transfers remaining crisp token balance of SolidZapDecollateralize to the `dustRecipient`
    /// 6. Withdraws any remaining WETH balance of SolidZapDecollateralize and transfers the ETH to `msg.sender`
    /// @param crispToken The intermediate token used for redeeming forward credits
    /// @param swap Encoded swap from `inputToken` to `crispToken`
    /// @param dustRecipient Address to receive any remaining crisp tokens dust
    /// @param decollateralizeParams Parameters for decollateralization
    ///  batchIds The batch ids of the forward credits to redeem
    ///  amountsIn The amounts of `crispToken` to used to redeem forward credits
    ///  amountsOutMin The minimum amounts of forward credits to receive
    function zapDecollateralizeETH(
        address crispToken,
        bytes calldata swap,
        address dustRecipient,
        DecollateralizeParams calldata decollateralizeParams
    ) external payable;

    /// @notice Zap function that achieves the following:
    /// 1. Wraps `msg.value` to WETH
    /// 2. Swaps `WETH` to `crispToken` via encoded swap
    /// 3. Decollateralizes resulting tokens to forward credits via SolidWorldManager
    /// 4. Transfers resulting forward credits to `zapRecipient`
    /// 5. Transfers remaining crisp token balance of SolidZapDecollateralize to the `dustRecipient`
    /// 6. Withdraws any remaining WETH balance of SolidZapDecollateralize and transfers the ETH to `zapRecipient`
    /// @param crispToken The intermediate token used for redeeming forward credits
    /// @param swap Encoded swap from `inputToken` to `crispToken`
    /// @param dustRecipient Address to receive any remaining crisp tokens dust
    /// @param decollateralizeParams Parameters for decollateralization
    ///  batchIds The batch ids of the forward credits to redeem
    ///  amountsIn The amounts of `crispToken` to used to redeem forward credits
    ///  amountsOutMin The minimum amounts of forward credits to receive
    /// @param zapRecipient The address to receive forward credits
    function zapDecollateralizeETH(
        address crispToken,
        bytes calldata swap,
        address dustRecipient,
        DecollateralizeParams calldata decollateralizeParams,
        address zapRecipient
    ) external payable;
}
