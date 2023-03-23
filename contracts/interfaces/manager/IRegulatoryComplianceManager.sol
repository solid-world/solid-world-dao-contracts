// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @author Solid World
interface IRegulatoryComplianceManager {
    function setCategoryKYCRequired(uint categoryId, bool isKYCRequired) external;

    function setBatchKYCRequired(uint batchId, bool isKYCRequired) external;

    function setCategoryVerificationRegistry(uint categoryId, address verificationRegistry) external;

    function setForwardsVerificationRegistry(address verificationRegistry) external;
}
