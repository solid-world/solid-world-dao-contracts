// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Errors thrown by the manager contract
/// @author Solid World DAO
interface ISolidWorldManagerErrors {
    error InvalidBatchId(uint batchId);
    error BatchesNotInSameCategory(uint batchId1, uint batchId2);

    error InvalidInput();

    error AmountOutLessThanMinimum(uint amountOut, uint minAmountOut);
    error AmountOutTooLow(uint amountOut);
}
