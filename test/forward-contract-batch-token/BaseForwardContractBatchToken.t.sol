// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/ForwardContractBatchToken.sol";
import "../../contracts/compliance/VerificationRegistry.sol";
import "../../contracts/interfaces/compliance/IVerificationRegistry.sol";

abstract contract BaseForwardContractBatchTokenTest is BaseTest {
    IVerificationRegistry verificationRegistry;
    ForwardContractBatchToken forwardContractBatchToken;

    address testAccount = vm.addr(1);

    event KYCRequiredSet(uint indexed batchId, bool indexed kycRequired);

    function setUp() public {
        _initVerificationRegistry();
        forwardContractBatchToken = new ForwardContractBatchToken("", address(verificationRegistry));
    }

    function _initVerificationRegistry() private {
        VerificationRegistry _verificationRegistry = new VerificationRegistry();
        _verificationRegistry.initialize(address(this));

        verificationRegistry = IVerificationRegistry(address(_verificationRegistry));
    }

    function _expectEmit_KYCRequiredSet(uint batchId, bool _kycRequired) internal {
        vm.expectEmit(true, true, true, false, address(forwardContractBatchToken));
        emit KYCRequiredSet(batchId, _kycRequired);
    }
}
