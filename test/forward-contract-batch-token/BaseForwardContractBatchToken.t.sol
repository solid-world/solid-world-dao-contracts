// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/ForwardContractBatchToken.sol";
import "../../contracts/compliance/VerificationRegistry.sol";
import "../../contracts/interfaces/compliance/IVerificationRegistry.sol";

abstract contract BaseForwardContractBatchTokenTest is BaseTest {
    IVerificationRegistry verificationRegistry;
    ForwardContractBatchToken forwardContractBatchToken;

    address testAccount0 = vm.addr(1);
    address testAccount1 = vm.addr(2);

    uint batchId0 = 1;
    uint batchId1 = 2;

    event KYCRequiredSet(uint indexed batchId, bool indexed kycRequired);

    function setUp() public {
        _initVerificationRegistry();
        forwardContractBatchToken = new ForwardContractBatchToken("", address(verificationRegistry));

        _mintInitialTokens();
    }

    function _initVerificationRegistry() private {
        VerificationRegistry _verificationRegistry = new VerificationRegistry();
        _verificationRegistry.initialize(address(this));

        verificationRegistry = IVerificationRegistry(address(_verificationRegistry));
    }

    function _mintInitialTokens() private {
        forwardContractBatchToken.mint(testAccount0, batchId0, 10000, "");
        forwardContractBatchToken.mint(testAccount1, batchId0, 10000, "");

        forwardContractBatchToken.mint(testAccount0, batchId1, 10000, "");
        forwardContractBatchToken.mint(testAccount1, batchId1, 10000, "");
    }

    function _expectEmit_KYCRequiredSet(uint batchId, bool _kycRequired) internal {
        vm.expectEmit(true, true, true, false, address(forwardContractBatchToken));
        emit KYCRequiredSet(batchId, _kycRequired);
    }

    function _expectRevert_NotRegulatoryCompliant(uint batchId, address subject) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                ForwardContractBatchToken.NotRegulatoryCompliant.selector,
                batchId,
                subject
            )
        );
    }
}
