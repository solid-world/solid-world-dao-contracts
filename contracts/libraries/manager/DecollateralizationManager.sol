// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./CategoryRebalancer.sol";
import "../DomainDataTypes.sol";
import "../SolidMath.sol";
import "../GPv2SafeERC20.sol";
import "../../CollateralizedBasketToken.sol";
import "../../SolidWorldManagerStorage.sol";

/// @notice Handles batch decollateralization operations.
/// @author Solid World DAO
library DecollateralizationManager {
    /// @notice Constant used as input for decollateralization simulation for ordering batches with the same category and vintage
    uint public constant DECOLLATERALIZATION_SIMULATION_INPUT = 1000e18;

    using CategoryRebalancer for SolidWorldManagerStorage.Storage;

    event TokensDecollateralized(
        uint indexed batchId,
        address indexed tokensOwner,
        uint amountIn,
        uint amountOut
    );
    event DecollateralizationFeeUpdated(uint indexed decollateralizationFee);
    event BoostedDecollateralizationFeeUpdated(uint indexed boostedDecollateralizationFee);

    error InvalidInput();
    error BatchesNotInSameCategory(uint categoryId1, uint categoryId2);
    error InvalidBatchId(uint batchId);
    error AmountOutLessThanMinimum(uint amountOut, uint minAmountOut);
    error AmountOutTooLow(uint amountOut);

    /// @dev Decollateralizes `amountIn` of ERC20 tokens and sends `amountOut` ERC1155 tokens with id `batchId` to msg.sender
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend `amountIn` ERC20 tokens
    /// @dev will trigger a rebalance of the Category
    /// @param _storage Struct containing the current state used or modified by this function
    /// @param batchId id of the batch
    /// @param amountIn ERC20 tokens to decollateralize
    /// @param amountOutMin minimum output amount of ERC1155 tokens for transaction to succeed
    function decollateralizeTokens(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external {
        _decollateralizeTokens(_storage, batchId, amountIn, amountOutMin);

        _storage.rebalanceCategory(_storage.batchCategory[batchId]);
    }

    /// @dev Bulk-decollateralizes ERC20 tokens into multiple ERC1155 tokens with specified amounts
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend `sum(amountsIn)` ERC20 tokens
    /// @dev _batchIds must belong to the same Category
    /// @dev will trigger a rebalance of the Category
    /// @param _storage Struct containing the current state used or modified by this function
    /// @param batchIds ids of the batches
    /// @param amountsIn ERC20 tokens to decollateralize
    /// @param amountsOutMin minimum output amounts of ERC1155 tokens for transaction to succeed
    function bulkDecollateralizeTokens(
        SolidWorldManagerStorage.Storage storage _storage,
        uint[] calldata batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external {
        if (batchIds.length != amountsIn.length || batchIds.length != amountsOutMin.length) {
            revert InvalidInput();
        }

        for (uint i = 1; i < batchIds.length; i++) {
            uint currentBatchCategoryId = _storage.batchCategory[batchIds[i]];
            uint previousBatchCategoryId = _storage.batchCategory[batchIds[i - 1]];

            if (currentBatchCategoryId != previousBatchCategoryId) {
                revert BatchesNotInSameCategory(currentBatchCategoryId, previousBatchCategoryId);
            }
        }

        for (uint i; i < batchIds.length; i++) {
            _decollateralizeTokens(_storage, batchIds[i], amountsIn[i], amountsOutMin[i]);
        }

        uint decollateralizedCategoryId = _storage.batchCategory[batchIds[0]];
        _storage.rebalanceCategory(decollateralizedCategoryId);
    }

    /// @dev Simulates decollateralization of `amountIn` ERC20 tokens for ERC1155 tokens with id `batchId`
    /// @param _storage Struct containing the current state used or modified by this function
    /// @param batchId id of the batch
    /// @param amountIn ERC20 tokens to decollateralize
    /// @return amountOut ERC1155 tokens to be received by msg.sender
    /// @return minAmountIn minimum amount of ERC20 tokens to decollateralize `amountOut` ERC1155 tokens with id `batchId`
    /// @return minCbtDaoCut ERC20 tokens to be received by feeReceiver for decollateralizing minAmountIn ERC20 tokens
    function simulateDecollateralization(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint amountIn
    )
        external
        view
        returns (
            uint amountOut,
            uint minAmountIn,
            uint minCbtDaoCut
        )
    {
        return _simulateDecollateralization(_storage, batchId, amountIn);
    }

    /// @dev Computes the `minCbt` ERC20 tokens that needs to be decollateralized to obtain `forwardCreditsAmount` ERC1155 tokens
    /// @param _storage Struct containing the current state used or modified by this function
    /// @param batchId id of the batch
    /// @param forwardCreditsAmount ERC1155 tokens to be received
    /// @return minCbt minimum amount of ERC20 tokens that needs to be decollateralized
    /// @return minCbtDaoCut amount of ERC20 tokens to be received by `feeReceiver` for decollateralizing `minCbt` ERC20 tokens
    function simulateReverseDecollateralization(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint forwardCreditsAmount
    ) external view returns (uint minCbt, uint minCbtDaoCut) {
        if (!_storage.batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }

        (minCbt, minCbtDaoCut) = _computeDecollateralizationMinAmountInAndDaoCut(
            _storage,
            batchId,
            forwardCreditsAmount,
            _getCollateralizedTokenForBatchId(_storage, batchId).decimals()
        );
    }

    /// @dev Computes relevant info for the decollateralization process involving batches
    /// that match the specified `projectId` and `vintage`
    /// @param _storage Struct containing the current state used or modified by this function
    /// @param projectId id of the project the batch belongs to
    /// @param vintage vintage of the batch
    /// @return result array of relevant info about matching batches
    function getBatchesDecollateralizationInfo(
        SolidWorldManagerStorage.Storage storage _storage,
        uint projectId,
        uint vintage
    ) external view returns (DomainDataTypes.TokenDecollateralizationInfo[] memory result) {
        DomainDataTypes.TokenDecollateralizationInfo[]
            memory allInfos = new DomainDataTypes.TokenDecollateralizationInfo[](_storage.batchIds.length);
        uint infoCount;

        for (uint i; i < _storage.batchIds.length; i++) {
            uint batchId = _storage.batchIds[i];
            if (
                _storage.batches[batchId].vintage != vintage ||
                _storage.batches[batchId].projectId != projectId
            ) {
                continue;
            }

            (uint amountOut, uint minAmountIn, uint minCbtDaoCut) = _simulateDecollateralization(
                _storage,
                batchId,
                DECOLLATERALIZATION_SIMULATION_INPUT
            );

            allInfos[infoCount] = DomainDataTypes.TokenDecollateralizationInfo(
                batchId,
                _storage.batches[batchId].collateralizedCredits,
                amountOut,
                minAmountIn,
                minCbtDaoCut
            );
            infoCount = infoCount + 1;
        }

        result = new DomainDataTypes.TokenDecollateralizationInfo[](infoCount);
        for (uint i; i < infoCount; i++) {
            result[i] = allInfos[i];
        }
    }

    /// @dev Computes relevant info for the decollateralization process involving batches
    /// that match the specified `projectId` and `certificationDate`
    /// @param _storage Struct containing the current state used or modified by this function
    /// @param projectId id of the project the batch belongs to
    /// @param certificationDate certification date of the batch
    /// @return result array of relevant info about matching batches
    function getBatchesDecollateralizationInfoWithCertificationDate(
        SolidWorldManagerStorage.Storage storage _storage,
        uint projectId,
        uint certificationDate
    ) external view returns (DomainDataTypes.TokenDecollateralizationInfo[] memory result) {
        DomainDataTypes.TokenDecollateralizationInfo[]
            memory allInfos = new DomainDataTypes.TokenDecollateralizationInfo[](_storage.batchIds.length);
        uint infoCount;

        for (uint i; i < _storage.batchIds.length; i++) {
            uint batchId = _storage.batchIds[i];
            if (
                _storage.batches[batchId].projectId != projectId ||
                _storage.batches[batchId].certificationDate != certificationDate
            ) {
                continue;
            }

            (uint amountOut, uint minAmountIn, uint minCbtDaoCut) = _simulateDecollateralization(
                _storage,
                batchId,
                DECOLLATERALIZATION_SIMULATION_INPUT
            );

            allInfos[infoCount] = DomainDataTypes.TokenDecollateralizationInfo(
                batchId,
                _storage.batches[batchId].collateralizedCredits,
                amountOut,
                minAmountIn,
                minCbtDaoCut
            );
            infoCount = infoCount + 1;
        }

        result = new DomainDataTypes.TokenDecollateralizationInfo[](infoCount);
        for (uint i; i < infoCount; i++) {
            result[i] = allInfos[i];
        }
    }

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param decollateralizationFee fee for decollateralizing ERC20 tokens
    function setDecollateralizationFee(
        SolidWorldManagerStorage.Storage storage _storage,
        uint16 decollateralizationFee
    ) external {
        _storage.decollateralizationFee = decollateralizationFee;

        emit DecollateralizationFeeUpdated(decollateralizationFee);
    }

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param boostedDecollateralizationFee fee for decollateralizing ERC20 tokens in case of a certified batch
    function setBoostedDecollateralizationFee(
        SolidWorldManagerStorage.Storage storage _storage,
        uint16 boostedDecollateralizationFee
    ) external {
        _storage.boostedDecollateralizationFee = boostedDecollateralizationFee;

        emit BoostedDecollateralizationFeeUpdated(boostedDecollateralizationFee);
    }

    function _simulateDecollateralization(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint amountIn
    )
        internal
        view
        returns (
            uint amountOut,
            uint minAmountIn,
            uint minCbtDaoCut
        )
    {
        if (!_storage.batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }

        uint cbtDecimals = _getCollateralizedTokenForBatchId(_storage, batchId).decimals();

        (amountOut, , ) = _computeDecollateralizationOutcome(_storage, batchId, amountIn, cbtDecimals);

        (minAmountIn, minCbtDaoCut) = _computeDecollateralizationMinAmountInAndDaoCut(
            _storage,
            batchId,
            amountOut,
            cbtDecimals
        );
    }

    /// @dev Decollateralizes `amountIn` of ERC20 tokens and sends `amountOut` ERC1155 tokens with id `batchId` to msg.sender
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend `amountIn` ERC20 tokens
    /// @param _storage Struct containing the current state used or modified by this function
    /// @param batchId id of the batch
    /// @param amountIn ERC20 tokens to decollateralize
    /// @param amountOutMin minimum output amount of ERC1155 tokens for transaction to succeed
    function _decollateralizeTokens(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) internal {
        if (amountIn == 0) {
            revert InvalidInput();
        }

        if (!_storage.batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }

        CollateralizedBasketToken cbt = _getCollateralizedTokenForBatchId(_storage, batchId);

        (uint amountOut, uint cbtDaoCut, uint cbtToBurn) = _computeDecollateralizationOutcome(
            _storage,
            batchId,
            amountIn,
            cbt.decimals()
        );

        if (amountOut == 0) {
            revert AmountOutTooLow(amountOut);
        }

        if (amountOut < amountOutMin) {
            revert AmountOutLessThanMinimum(amountOut, amountOutMin);
        }

        _performDecollateralization(_storage, cbt, batchId, amountOut, cbtToBurn, cbtDaoCut);

        emit TokensDecollateralized(batchId, msg.sender, amountIn, amountOut);
    }

    function _performDecollateralization(
        SolidWorldManagerStorage.Storage storage _storage,
        CollateralizedBasketToken cbt,
        uint batchId,
        uint releasedCredits,
        uint cbtToBurn,
        uint cbtDaoCut
    ) internal {
        cbt.burnFrom(msg.sender, cbtToBurn);
        GPv2SafeERC20.safeTransferFrom(cbt, msg.sender, _storage.feeReceiver, cbtDaoCut);

        _storage.batches[batchId].collateralizedCredits -= releasedCredits;

        _storage._forwardContractBatch.safeTransferFrom(
            address(this),
            msg.sender,
            batchId,
            releasedCredits,
            ""
        );
    }

    function _getCollateralizedTokenForBatchId(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId
    ) internal view returns (CollateralizedBasketToken) {
        uint projectId = _storage.batches[batchId].projectId;
        uint categoryId = _storage.projectCategory[projectId];

        return _storage.categoryToken[categoryId];
    }

    function _computeDecollateralizationOutcome(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint cbtAmount,
        uint cbtDecimals
    )
        internal
        view
        returns (
            uint amountOut,
            uint cbtDaoCut,
            uint cbtToBurn
        )
    {
        uint fee = _getBatchDecollateralizationFee(_storage, batchId);
        return
            SolidMath.computeDecollateralizationOutcome(
                _storage.batches[batchId].certificationDate,
                cbtAmount,
                _storage.batches[batchId].batchTA,
                fee,
                cbtDecimals
            );
    }

    function _computeDecollateralizationMinAmountInAndDaoCut(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint expectedFcbtAmount,
        uint cbtDecimals
    ) internal view returns (uint minAmountIn, uint minCbtDaoCut) {
        uint fee = _getBatchDecollateralizationFee(_storage, batchId);
        return
            SolidMath.computeDecollateralizationMinAmountInAndDaoCut(
                _storage.batches[batchId].certificationDate,
                expectedFcbtAmount,
                _storage.batches[batchId].batchTA,
                fee,
                cbtDecimals
            );
    }

    function _getBatchDecollateralizationFee(SolidWorldManagerStorage.Storage storage _storage, uint batchId)
        internal
        view
        returns (uint16)
    {
        bool isCertified = _storage.batches[batchId].certificationDate <= block.timestamp;
        if (isCertified) {
            return _storage.boostedDecollateralizationFee;
        }

        return _storage.decollateralizationFee;
    }
}
