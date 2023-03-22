// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseForwardContractBatchToken.t.sol";

contract ForwardContractBatchTokenTest is BaseForwardContractBatchTokenTest {
    function testIsKYCRequired() public {
        uint batchId = 1;
        assertFalse(forwardContractBatchToken.isKYCRequired(batchId));
    }

    function testSetKYCRequired() public {
        uint batchId = 1;

        forwardContractBatchToken.setKYCRequired(batchId, true);
        assertTrue(forwardContractBatchToken.isKYCRequired(batchId));
    }

    function testSetKYCRequired_revertsIfNotOwner() public {
        uint batchId = 1;

        vm.prank(testAccount);
        _expectRevertWithMessage("Ownable: caller is not the owner");
        forwardContractBatchToken.setKYCRequired(batchId, true);
    }

    function testSetKYCRequired_emitsEvent() public {
        uint batchId = 1;

        _expectEmit_KYCRequiredSet(batchId, true);
        forwardContractBatchToken.setKYCRequired(batchId, true);
    }

    function testSetVerificationRegistry_revertsIfNotOwner() public {
        address verificationRegistry = vm.addr(1);

        vm.prank(testAccount);
        _expectRevertWithMessage("Ownable: caller is not the owner");
        forwardContractBatchToken.setVerificationRegistry(verificationRegistry);
    }

    function testSetVerificationRegistry_setsRegistry() public {
        address verificationRegistry = vm.addr(1);

        forwardContractBatchToken.setVerificationRegistry(verificationRegistry);
        assertEq(forwardContractBatchToken.getVerificationRegistry(), verificationRegistry);
    }
}
