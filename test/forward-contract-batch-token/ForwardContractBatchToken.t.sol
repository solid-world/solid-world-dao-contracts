// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseForwardContractBatchToken.t.sol";

contract ForwardContractBatchTokenTest is BaseForwardContractBatchTokenTest {
    function testIsKYCRequired() public {
        assertFalse(forwardContractBatchToken.isKYCRequired(batchId0));
    }

    function testSetKYCRequired() public {
        forwardContractBatchToken.setKYCRequired(batchId0, true);
        assertTrue(forwardContractBatchToken.isKYCRequired(batchId0));
    }

    function testSetKYCRequired_revertsIfNotOwner() public {
        vm.prank(testAccount0);
        _expectRevertWithMessage("Ownable: caller is not the owner");
        forwardContractBatchToken.setKYCRequired(batchId0, true);
    }

    function testSetKYCRequired_emitsEvent() public {
        _expectEmit_KYCRequiredSet(batchId0, true);
        forwardContractBatchToken.setKYCRequired(batchId0, true);
    }

    function testSetVerificationRegistry_revertsIfNotOwner() public {
        address verificationRegistry = vm.addr(1);

        vm.prank(testAccount0);
        _expectRevertWithMessage("Ownable: caller is not the owner");
        forwardContractBatchToken.setVerificationRegistry(verificationRegistry);
    }

    function testSetVerificationRegistry_setsRegistry() public {
        address verificationRegistry = vm.addr(1);

        forwardContractBatchToken.setVerificationRegistry(verificationRegistry);
        assertEq(forwardContractBatchToken.getVerificationRegistry(), verificationRegistry);
    }

    function testSafeTransferFrom_revertsIfComplianceCheckFails_fromAddress() public {
        uint transferAmount = 100;

        forwardContractBatchToken.setKYCRequired(batchId0, true);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(batchId0, testAccount0);
        forwardContractBatchToken.safeTransferFrom(testAccount0, testAccount1, batchId0, transferAmount, "");

        verificationRegistry.blacklist(testAccount0);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(batchId1, testAccount0);
        forwardContractBatchToken.safeTransferFrom(testAccount0, testAccount1, batchId1, transferAmount, "");
    }

    function testSafeTransferFrom_revertsIfComplianceCheckFails_toAddress() public {
        uint transferAmount = 100;

        forwardContractBatchToken.setKYCRequired(batchId0, true);
        verificationRegistry.registerVerification(testAccount0);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(batchId0, testAccount1);
        forwardContractBatchToken.safeTransferFrom(testAccount0, testAccount1, batchId0, transferAmount, "");

        verificationRegistry.blacklist(testAccount1);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(batchId1, testAccount1);
        forwardContractBatchToken.safeTransferFrom(testAccount0, testAccount1, batchId1, transferAmount, "");
    }
}
