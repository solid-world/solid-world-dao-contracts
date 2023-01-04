// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @notice Handles batch collateralization operations.
/// @author Solid World DAO
interface ICollateralizationManager {
    /// @dev Collateralizes `amountIn` of ERC1155 tokens with id `batchId` for msg.sender
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend its ERC1155 tokens with id `batchId`
    /// @dev nonReentrant, to avoid possible reentrancy after calling safeTransferFrom
    /// @param batchId id of the batch
    /// @param amountIn ERC1155 tokens to collateralize
    /// @param amountOutMin minimum output amount of ERC20 tokens for transaction to succeed
    function collateralizeBatch(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external;

    /// @dev Simulates collateralization of `amountIn` ERC1155 tokens with id `batchId` for msg.sender
    /// @param batchId id of the batch
    /// @param amountIn ERC1155 tokens to collateralize
    /// @return cbtUserCut ERC20 tokens to be received by msg.sender
    /// @return cbtDaoCut ERC20 tokens to be received by feeReceiver
    /// @return cbtForfeited ERC20 tokens forfeited for collateralizing the ERC1155 tokens
    function simulateBatchCollateralization(uint batchId, uint amountIn)
        external
        view
        returns (
            uint cbtUserCut,
            uint cbtDaoCut,
            uint cbtForfeited
        );

    /// @param collateralizationFee fee for collateralizing ERC1155 tokens
    function setCollateralizationFee(uint16 collateralizationFee) external;
}
