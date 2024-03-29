// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./CategoryRebalancer.sol";
import "../DomainDataTypes.sol";
import "../SolidMath.sol";
import "../ReactiveTimeAppreciationMath.sol";
import "../../CollateralizedBasketToken.sol";
import "../../SolidWorldManagerStorage.sol";

/// @notice Handles batch collateralization operations.
/// @author Solid World DAO
library CollateralizationManager {
    using CategoryRebalancer for SolidWorldManagerStorage.Storage;

    event BatchCollateralized(
        uint indexed batchId,
        address indexed batchSupplier,
        uint amountIn,
        uint amountOut
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
        if (certificationDate <= block.timestamp || !_storage.batches[batchId].isAccumulating) {
            revert BatchCertified(batchId);
        }

        if (SolidMath.yearsBetween(block.timestamp, certificationDate) == 0) {
            revert CannotCollateralizeTheWeekBeforeCertification();
        }

        (uint decayingMomentum, uint reactiveTA) = ReactiveTimeAppreciationMath.computeReactiveTA(
            _storage.categories[_storage.batchCategory[batchId]],
            amountIn
        );

        CollateralizedBasketToken cbt = _getCollateralizedTokenForBatchId(_storage, batchId);

        (uint cbtUserCut, uint cbtDaoCut, ) = SolidMath.computeCollateralizationOutcome(
            certificationDate,
            amountIn,
            reactiveTA,
            _storage.collateralizationFee,
            cbt.decimals()
        );

        if (cbtUserCut < amountOutMin) {
            revert AmountOutLessThanMinimum(cbtUserCut, amountOutMin);
        }

        _updateBatchTA(_storage, batchId, reactiveTA, amountIn, cbtUserCut + cbtDaoCut, cbt.decimals());
        _storage.rebalanceCategory(_storage.batchCategory[batchId], reactiveTA, amountIn, decayingMomentum);

        _performCollateralization(_storage, cbt, batchId, amountIn, cbtUserCut, cbtDaoCut);

        emit BatchCollateralized(batchId, msg.sender, amountIn, cbtUserCut);
    }

    function _performCollateralization(
        SolidWorldManagerStorage.Storage storage _storage,
        CollateralizedBasketToken cbt,
        uint batchId,
        uint collateralizedCredits,
        uint cbtUserCut,
        uint cbtDaoCut
    ) internal {
        cbt.mint(msg.sender, cbtUserCut);
        cbt.mint(_storage.feeReceiver, cbtDaoCut);

        _storage.batches[batchId].collateralizedCredits += collateralizedCredits;

        _storage._forwardContractBatch.safeTransferFrom(
            msg.sender,
            address(this),
            batchId,
            collateralizedCredits,
            ""
        );
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
        if (amountIn == 0) {
            revert InvalidInput();
        }

        if (!_storage.batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }

        uint32 certificationDate = _storage.batches[batchId].certificationDate;
        if (certificationDate <= block.timestamp || !_storage.batches[batchId].isAccumulating) {
            revert BatchCertified(batchId);
        }

        if (SolidMath.yearsBetween(block.timestamp, certificationDate) == 0) {
            revert CannotCollateralizeTheWeekBeforeCertification();
        }

        DomainDataTypes.Category storage category = _storage.categories[_storage.batchCategory[batchId]];
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(_storage, batchId);

        (, uint reactiveTA) = ReactiveTimeAppreciationMath.computeReactiveTA(category, amountIn);

        (cbtUserCut, cbtDaoCut, cbtForfeited) = SolidMath.computeCollateralizationOutcome(
            certificationDate,
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

    /// @param _storage Struct containing the current state used or modified by this function
    /// @param categoryId id of the category whose parameters are used to compute the reactiveTA
    /// @param forwardCreditsAmount ERC1155 tokens amount to be collateralized
    function getReactiveTA(
        SolidWorldManagerStorage.Storage storage _storage,
        uint categoryId,
        uint forwardCreditsAmount
    ) external view returns (uint reactiveTA) {
        DomainDataTypes.Category storage category = _storage.categories[categoryId];
        (, reactiveTA) = ReactiveTimeAppreciationMath.computeReactiveTA(category, forwardCreditsAmount);
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
        uint collateralizedForwardCredits = _storage.batches[batchId].collateralizedCredits;
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

    function _getCollateralizedTokenForBatchId(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId
    ) internal view returns (CollateralizedBasketToken) {
        uint projectId = _storage.batches[batchId].projectId;
        uint categoryId = _storage.projectCategory[projectId];

        return _storage.categoryToken[categoryId];
    }
}
