// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../SolidWorldManagerStorage.sol";

/// @author Solid World
library RegulatoryComplianceManager {
    error InvalidCategoryId(uint categoryId);
    error InvalidBatchId(uint batchId);

    function setCategoryKYCRequired(
        SolidWorldManagerStorage.Storage storage _storage,
        uint categoryId,
        bool isKYCRequired
    ) external {
        if (!_storage.categoryCreated[categoryId]) {
            revert InvalidCategoryId(categoryId);
        }

        _storage.categoryToken[categoryId].setKYCRequired(isKYCRequired);
    }

    function setBatchKYCRequired(
        SolidWorldManagerStorage.Storage storage _storage,
        uint batchId,
        bool isKYCRequired
    ) external {
        if (!_storage.batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }

        _storage._forwardContractBatch.setKYCRequired(batchId, isKYCRequired);
    }

    function setCategoryVerificationRegistry(
        SolidWorldManagerStorage.Storage storage _storage,
        uint categoryId,
        address verificationRegistry
    ) external {
        if (!_storage.categoryCreated[categoryId]) {
            revert InvalidCategoryId(categoryId);
        }

        _storage.categoryToken[categoryId].setVerificationRegistry(verificationRegistry);
    }
}
