// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../DomainDataTypes.sol";
import "../SolidMath.sol";
import "../ReactiveTimeAppreciationMath.sol";
import "../../CollateralizedBasketToken.sol";
import "../../SolidWorldManagerStorage.sol";

/// @notice Handles batch collateralization operations.
/// @author Solid World DAO
library CollateralizationManager {
    event BatchCollateralized(
        uint indexed batchId,
        address indexed batchSupplier,
        uint amountIn,
        uint amountOut
    );
    event CategoryRebalanced(
        uint indexed categoryId,
        uint indexed averageTA,
        uint indexed totalCollateralized
    );
    event CollateralizationFeeUpdated(uint indexed collateralizationFee);

    error InvalidBatchId(uint batchId);
    error BatchCertified(uint batchId);
    error InvalidInput();
    error CannotCollateralizeTheWeekBeforeCertification();
    error AmountOutLessThanMinimum(uint amountOut, uint minAmountOut);

    /// @dev Collateralizes `amountIn` of ERC1155 tokens with id `batchId` for msg.sender
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend its ERC1155 tokens with id `batchId`
    /// @param _storage Struct containing the current state used or modified by this function
    /// @param batchId id of the batch
    /// @param amountIn ERC1155 tokens to collateralize
    /// @param amountOutMin minimum output amount of ERC20 tokens for transaction to succeed
    function collateralizeBatch(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external {
        if (amountIn == 0) {
            revert InvalidInput();
        }

        if (!_storage.batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }

        uint32 certificationDate = _storage.batches[batchId].certificationDate;
        if (certificationDate <= block.timestamp) {
            revert BatchCertified(batchId);
        }

        if (SolidMath.yearsBetween(block.timestamp, certificationDate) == 0) {
            revert CannotCollateralizeTheWeekBeforeCertification();
        }

        (uint decayingMomentum, uint reactiveTA) = ReactiveTimeAppreciationMath.computeReactiveTA(
            _storage.categories[_storage.batchCategory[batchId]],
            amountIn
        );

        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(
            _storage,
            batchId
        );

        (uint cbtUserCut, uint cbtDaoCut, ) = SolidMath.computeCollateralizationOutcome(
            certificationDate,
            amountIn,
            reactiveTA,
            _storage.collateralizationFee,
            collateralizedToken.decimals()
        );

        if (cbtUserCut < amountOutMin) {
            revert AmountOutLessThanMinimum(cbtUserCut, amountOutMin);
        }

        _updateBatchTA(
            _storage,
            batchId,
            reactiveTA,
            amountIn,
            cbtUserCut + cbtDaoCut,
            collateralizedToken.decimals()
        );
        _rebalanceCategory(
            _storage,
            _storage.batchCategory[batchId],
            reactiveTA,
            amountIn,
            decayingMomentum
        );

        collateralizedToken.mint(msg.sender, cbtUserCut);
        collateralizedToken.mint(_storage.feeReceiver, cbtDaoCut);

        _storage._forwardContractBatch.safeTransferFrom(
            msg.sender,
            address(this),
            batchId,
            amountIn,
            ""
        );

        emit BatchCollateralized(batchId, msg.sender, amountIn, cbtUserCut);
    }

    /// @dev Simulates collateralization of `amountIn` ERC1155 tokens with id `batchId` for msg.sender
    /// @param _storage Struct containing the current state used or modified by this function
    /// @param batchId id of the batch
    /// @param amountIn ERC1155 tokens to collateralize
    /// @return cbtUserCut ERC20 tokens to be received by msg.sender
    /// @return cbtDaoCut ERC20 tokens to be received by feeReceiver
    /// @return cbtForfeited ERC20 tokens forfeited for collateralizing the ERC1155 tokens
    function simulateBatchCollateralization(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint amountIn
    )
        external
        view
        returns (
            uint cbtUserCut,
            uint cbtDaoCut,
            uint cbtForfeited
        )
    {
        if (!_storage.batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }

        if (_storage.batches[batchId].certificationDate <= block.timestamp) {
            revert BatchCertified(batchId);
        }

        if (amountIn == 0) {
            revert InvalidInput();
        }

        DomainDataTypes.Category storage category = _storage.categories[
            _storage.batchCategory[batchId]
        ];
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(
            _storage,
            batchId
        );

        (, uint reactiveTA) = ReactiveTimeAppreciationMath.computeReactiveTA(category, amountIn);

        (cbtUserCut, cbtDaoCut, cbtForfeited) = SolidMath.computeCollateralizationOutcome(
            _storage.batches[batchId].certificationDate,
            amountIn,
            reactiveTA,
            _storage.collateralizationFee,
            collateralizedToken.decimals()
        );
    }

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param collateralizationFee fee for collateralizing ERC1155 tokens
    function setCollateralizationFee(
        SolidWorldManagerStorage.Storage storage _storage,
        uint16 collateralizationFee
    ) external {
        _storage.collateralizationFee = collateralizationFee;

        emit CollateralizationFeeUpdated(collateralizationFee);
    }

    function _updateBatchTA(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        uint reactiveTA,
        uint toBeCollateralizedForwardCredits,
        uint toBeMintedCBT,
        uint cbtDecimals
    ) internal {
        DomainDataTypes.Batch storage batch = _storage.batches[batchId];
        uint collateralizedForwardCredits = _storage._forwardContractBatch.balanceOf(
            address(this),
            batch.id
        );
        if (collateralizedForwardCredits == 0) {
            batch.batchTA = uint24(reactiveTA);
            return;
        }

        (uint circulatingCBT, , ) = SolidMath.computeCollateralizationOutcome(
            batch.certificationDate,
            collateralizedForwardCredits,
            batch.batchTA,
            0, // compute without fee
            cbtDecimals
        );

        batch.batchTA = uint24(
            ReactiveTimeAppreciationMath.inferBatchTA(
                circulatingCBT + toBeMintedCBT,
                collateralizedForwardCredits + toBeCollateralizedForwardCredits,
                batch.certificationDate,
                cbtDecimals
            )
        );
    }

    function _rebalanceCategory(
        SolidWorldManagerStorage.Storage storage _storage,
        uint categoryId,
        uint reactiveTA,
        uint currentCollateralizedAmount,
        uint decayingMomentum
    ) internal {
        DomainDataTypes.Category storage category = _storage.categories[categoryId];

        uint latestAverageTA = (category.averageTA *
            category.totalCollateralized +
            reactiveTA *
            currentCollateralizedAmount) /
            (category.totalCollateralized + currentCollateralizedAmount);

        category.averageTA = uint24(latestAverageTA);
        category.totalCollateralized += currentCollateralizedAmount;
        category.lastCollateralizationMomentum = decayingMomentum + currentCollateralizedAmount;
        category.lastCollateralizationTimestamp = uint32(block.timestamp);

        emit CategoryRebalanced(categoryId, latestAverageTA, category.totalCollateralized);
    }

    function _getCollateralizedTokenForBatchId(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId
    ) internal view returns (CollateralizedBasketToken) {
        uint projectId = _storage.batches[batchId].projectId;
        uint categoryId = _storage.projectCategory[projectId];

        return _storage.categoryToken[categoryId];
    }
}
