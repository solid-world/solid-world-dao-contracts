// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Errors thrown by the manager contract
/// @author Solid World DAO
interface ISolidWorldManagerErrors {
    error BatchAlreadyExists(uint batchId);
    error InvalidBatchId(uint batchId);
    error InvalidBatchOwner();
    error BatchDueDateInThePast(uint32 dueDate);

    error CategoryAlreadyExists(uint categoryId);
    error InvalidCategoryId(uint categoryId);

    error ProjectAlreadyExists(uint projectId);
    error InvalidProjectId(uint projectId);

    error InvalidInput();

    error AmountOutLessThanMinimum(uint amountOut, uint minAmountOut);
    error AmountOutTooLow(uint amountOut);

    error BatchCertified(uint batchId);
}
