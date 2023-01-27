// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library DomainDataTypes {
    /// @notice Structure that holds necessary information for minting collateralized basket tokens (ERC-20).
    /// @param id ID of the batch in the database
    /// @param projectId Project ID this batch belongs to
    /// @param supplier Address who receives forward contract batch tokens (ERC-1155)
    /// @param certificationDate When the batch is about to be delivered; affects on how many collateralized basket tokens (ERC-20) may be minted
    /// @param vintage The year an emission reduction occurred or the offset was issued. The older the vintage, the cheaper the price per credit.
    /// @param status Status for the batch (ex. CAN_BE_DEPOSITED | IS_ACCUMULATING | READY_FOR_DELIVERY etc.)
    /// @param batchTA Coefficient that affects on how many collateralized basket tokens (ERC-20) may be minted / ton
    /// depending on market conditions. Forward is worth less than spot.
    /// @param isAccumulating if true, the batch accepts deposits
    /// @param collateralizedCredits Amount of forward credits that have been provided as collateral for getting collateralized basket tokens (ERC-20)
    struct Batch {
        uint id;
        uint projectId;
        address supplier;
        uint32 certificationDate;
        uint16 vintage;
        uint8 status;
        uint24 batchTA;
        bool isAccumulating;
        uint collateralizedCredits;
    }

    /// @notice Structure that holds state of a category of forward carbon credits. Used for computing collateralization.
    /// @param volumeCoefficient controls how much impact does erc1155 input size have on the TA being offered.
    /// The higher, the more you have to input to raise the TA.
    /// @param decayPerSecond controls how fast the built momentum drops over time.
    /// The bigger, the faster the momentum drops.
    /// @param maxDepreciation controls how much the reactive TA can drop from the averageTA value. Quantified per year.
    /// @param averageTA is the average time appreciation of the category.
    /// @param totalCollateralized is the total amount of collateralized tokens for this category.
    /// @param lastCollateralizationTimestamp the timestamp of the last collateralization.
    /// @param lastCollateralizationMomentum the value of the momentum at the last collateralization.
    struct Category {
        uint volumeCoefficient;
        uint40 decayPerSecond;
        uint16 maxDepreciation;
        uint24 averageTA;
        uint totalCollateralized;
        uint32 lastCollateralizationTimestamp;
        uint lastCollateralizationMomentum;
    }

    /// @notice Structure that holds necessary information for decollateralizing ERC20 tokens to ERC1155 tokens with id `batchId`
    /// @param batchId id of the batch
    /// @param availableBatchTokens Amount of ERC1155 tokens with id `batchId` that are available to be redeemed
    /// @param amountOut ERC1155 tokens with id `batchId` to be received by msg.sender
    /// @param minAmountIn minimum amount of ERC20 tokens to decollateralize `amountOut` ERC1155 tokens with id `batchId`
    /// @param minCbtDaoCut ERC20 tokens to be received by feeReceiver for decollateralizing minAmountIn ERC20 tokens
    struct TokenDecollateralizationInfo {
        uint batchId;
        uint availableBatchTokens;
        uint amountOut;
        uint minAmountIn;
        uint minCbtDaoCut;
    }
}
