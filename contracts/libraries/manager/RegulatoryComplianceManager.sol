// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../SolidWorldManagerStorage.sol";

/// @author Solid World
library RegulatoryComplianceManager {
    error InvalidCategoryId(uint categoryId);

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
