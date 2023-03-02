// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../DomainDataTypes.sol";
import "../../SolidWorldManagerStorage.sol";

/// @author Solid World
library CategoryRebalancer {
    event CategoryRebalanced(
        uint indexed categoryId,
        uint indexed averageTA,
        uint indexed totalCollateralized
    );

    function rebalanceCategory(
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
            currentCollateralizedAmount) / (category.totalCollateralized + currentCollateralizedAmount);

        category.averageTA = uint24(latestAverageTA);
        category.totalCollateralized += currentCollateralizedAmount;
        category.lastCollateralizationMomentum = decayingMomentum + currentCollateralizedAmount;
        category.lastCollateralizationTimestamp = uint32(block.timestamp);

        emit CategoryRebalanced(categoryId, latestAverageTA, category.totalCollateralized);
    }

    function rebalanceCategory(SolidWorldManagerStorage.Storage storage _storage, uint categoryId) internal {
        uint totalQuantifiedForwardCredits;
        uint totalCollateralizedForwardCredits;

        uint[] storage projectIds = _storage.categoryProjects[categoryId];
        for (uint i; i < projectIds.length; i++) {
            uint projectId = projectIds[i];
            uint[] storage batchIds = _storage.projectBatches[projectId];
            uint numOfBatches = batchIds.length;
            for (uint j; j < numOfBatches; ) {
                DomainDataTypes.Batch storage batch = _storage.batches[batchIds[j]];
                uint collateralizedForwardCredits = batch.collateralizedCredits;
                if (
                    collateralizedForwardCredits == 0 ||
                    _isBatchCertified(_storage, batch.id) ||
                    !batch.isAccumulating
                ) {
                    unchecked {
                        j++;
                    }
                    continue;
                }

                totalQuantifiedForwardCredits += batch.batchTA * collateralizedForwardCredits;
                totalCollateralizedForwardCredits += collateralizedForwardCredits;

                unchecked {
                    j++;
                }
            }
        }

        if (totalCollateralizedForwardCredits == 0) {
            _storage.categories[categoryId].totalCollateralized = 0;
            emit CategoryRebalanced(categoryId, _storage.categories[categoryId].averageTA, 0);
            return;
        }

        uint latestAverageTA = totalQuantifiedForwardCredits / totalCollateralizedForwardCredits;
        _storage.categories[categoryId].averageTA = uint24(latestAverageTA);
        _storage.categories[categoryId].totalCollateralized = totalCollateralizedForwardCredits;

        emit CategoryRebalanced(categoryId, latestAverageTA, totalCollateralizedForwardCredits);
    }

    function _isBatchCertified(SolidWorldManagerStorage.Storage storage _storage, uint batchId)
        private
        view
        returns (bool)
    {
        return _storage.batches[batchId].certificationDate <= block.timestamp;
    }
}
