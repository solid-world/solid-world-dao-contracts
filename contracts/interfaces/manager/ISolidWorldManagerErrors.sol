// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Errors thrown by the manager contract
/// @author Solid World DAO
interface ISolidWorldManagerErrors {
    error BatchAlreadyExists(uint batchId);
    error InvalidBatchId(uint batchId);
    error InvalidBatchSupplier();
    error BatchCertificationDateInThePast(uint32 dueDate);
    error BatchesNotInSameCategory(uint batchId1, uint batchId2);

    error CategoryAlreadyExists(uint categoryId);
    error InvalidCategoryId(uint categoryId);

    error ProjectAlreadyExists(uint projectId);
    error InvalidProjectId(uint projectId);

    error InvalidInput();

    error AmountOutLessThanMinimum(uint amountOut, uint minAmountOut);
    error AmountOutTooLow(uint amountOut);

    error BatchCertified(uint batchId);
}
