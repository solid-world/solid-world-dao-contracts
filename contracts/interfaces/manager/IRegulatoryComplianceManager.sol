// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @author Solid World
interface IRegulatoryComplianceManager {
    function setCategoryKYCRequired(uint categoryId, bool isKYCRequired) external;
}
