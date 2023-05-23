// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../libraries/DomainDataTypes.sol";

/// @notice Handles batch decollateralization operations.
/// @author Solid World DAO
interface IDecollateralizationManager {
    event TokensDecollateralized(
        uint indexed batchId,
        address indexed tokensOwner,
        uint amountIn,
        uint amountOut
    );
    event DecollateralizationFeeUpdated(uint indexed decollateralizationFee);
    event BoostedDecollateralizationFeeUpdated(uint indexed boostedDecollateralizationFee);

    /// @dev Decollateralizes `amountIn` of ERC20 tokens and sends `amountOut` ERC1155 tokens with id `batchId` to msg.sender
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend `amountIn` ERC20 tokens
    /// @dev nonReentrant (_decollateralizeTokens), to avoid possible reentrancy after calling safeTransferFrom
    /// @dev will trigger a rebalance of the Category
    /// @param batchId id of the batch
    /// @param amountIn ERC20 tokens to decollateralize
    /// @param amountOutMin minimum output amount of ERC1155 tokens for transaction to succeed
    function decollateralizeTokens(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external;

    /// @dev Bulk-decollateralizes ERC20 tokens into multiple ERC1155 tokens with specified amounts
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend `sum(amountsIn)` ERC20 tokens
    /// @dev nonReentrant (_decollateralizeTokens), to avoid possible reentrancy after calling safeTransferFrom
    /// @dev _batchIds must belong to the same Category
    /// @dev will trigger a rebalance of the Category
    /// @param batchIds ids of the batches
    /// @param amountsIn ERC20 tokens to decollateralize
    /// @param amountsOutMin minimum output amounts of ERC1155 tokens for transaction to succeed
    function bulkDecollateralizeTokens(
        uint[] calldata batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external;

    /// @dev Simulates decollateralization of `amountIn` ERC20 tokens for ERC1155 tokens with id `batchId`
    /// @param batchId id of the batch
    /// @param amountIn ERC20 tokens to decollateralize
    /// @return amountOut ERC1155 tokens to be received
    /// @return minAmountIn minimum amount of ERC20 tokens to decollateralize `amountOut` ERC1155 tokens with id `batchId`
    /// @return minCbtDaoCut ERC20 tokens to be received by `feeReceiver` for decollateralizing `minAmountIn` ERC20 tokens
    function simulateDecollateralization(uint batchId, uint amountIn)
        external
        view
        returns (
            uint amountOut,
            uint minAmountIn,
            uint minCbtDaoCut
        );

    /// @dev Computes the `minCbt` ERC20 tokens that needs to be decollateralized to obtain `forwardCreditsAmount` ERC1155 tokens
    /// @param batchId id of the batch
    /// @param forwardCreditsAmount ERC1155 tokens to be received
    /// @return minCbt minimum amount of ERC20 tokens that needs to be decollateralized
    /// @return minCbtDaoCut amount of ERC20 tokens to be received by `feeReceiver` for decollateralizing `minCbt` ERC20 tokens
    function simulateReverseDecollateralization(uint batchId, uint forwardCreditsAmount)
        external
        view
        returns (uint minCbt, uint minCbtDaoCut);

    /// @dev Computes relevant info for the decollateralization process involving batches
    /// that match the specified `projectId` and `vintage`
    /// @param projectId id of the project the batch belongs to
    /// @param vintage vintage of the batch
    /// @return result array of relevant info about matching batches
    function getBatchesDecollateralizationInfo(uint projectId, uint vintage)
        external
        view
        returns (DomainDataTypes.TokenDecollateralizationInfo[] memory result);

    /// @dev Computes relevant info for the decollateralization process involving batches
    /// that match the specified `projectId` and `certificationYear`
    /// @param projectId id of the project the batch belongs to
    /// @param certificationYear certification year of the batch
    /// @return result array of relevant info about matching batches
    function getBatchesDecollateralizationInfoWithCertificationYear(uint projectId, uint certificationYear)
        external
        view
        returns (DomainDataTypes.TokenDecollateralizationInfo[] memory result);

    /// @param decollateralizationFee fee for decollateralizing ERC20 tokens
    function setDecollateralizationFee(uint16 decollateralizationFee) external;

    /// @param boostedDecollateralizationFee fee for decollateralizing ERC20 tokens in case of certified batches
    function setBoostedDecollateralizationFee(uint16 boostedDecollateralizationFee) external;
}
