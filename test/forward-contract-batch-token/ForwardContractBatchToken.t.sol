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
        _expectRevert_NotOwner();
        forwardContractBatchToken.setKYCRequired(batchId0, true);
    }

    function testSetKYCRequired_emitsEvent() public {
        _expectEmit_KYCRequiredSet(batchId0, true);
        forwardContractBatchToken.setKYCRequired(batchId0, true);
    }

    function testSetVerificationRegistry_revertsIfNotOwner() public {
        address verificationRegistry = vm.addr(1);

        vm.prank(testAccount0);
        _expectRevert_NotOwner();
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
        verificationRegistry.registerVerification(testAccount0);
        verificationRegistry.registerVerification(testAccount2);

        vm.prank(testAccount1);
        forwardContractBatchToken.setApprovalForAll(testAccount0, true);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(batchId0, testAccount1);
        forwardContractBatchToken.safeTransferFrom(testAccount1, testAccount2, batchId0, transferAmount, "");
    }

    function testSafeTransferFrom_revertsIfComplianceCheckFails_toAddress() public {
        uint transferAmount = 100;

        forwardContractBatchToken.setKYCRequired(batchId0, true);
        verificationRegistry.registerVerification(testAccount0);
        verificationRegistry.registerVerification(testAccount1);

        vm.prank(testAccount1);
        forwardContractBatchToken.setApprovalForAll(testAccount0, true);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(batchId0, testAccount2);
        forwardContractBatchToken.safeTransferFrom(testAccount1, testAccount2, batchId0, transferAmount, "");
    }

    function testSafeTransferFrom_revertsIfComplianceCheckFails_spender() public {
        uint transferAmount = 100;

        forwardContractBatchToken.setKYCRequired(batchId0, true);
        verificationRegistry.registerVerification(testAccount1);
        verificationRegistry.registerVerification(testAccount2);

        vm.prank(testAccount1);
        forwardContractBatchToken.setApprovalForAll(testAccount0, true);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(batchId0, testAccount0);
        forwardContractBatchToken.safeTransferFrom(testAccount1, testAccount2, batchId0, transferAmount, "");
    }

    function testSafeBatchTransferFrom_revertsIfComplianceCheckFails_fromAddress() public {
        uint[] memory batchIds = _toArray(batchId0);
        uint[] memory transferAmounts = _toArray(100);

        forwardContractBatchToken.setKYCRequired(batchId0, true);
        verificationRegistry.registerVerification(testAccount0);
        verificationRegistry.registerVerification(testAccount2);

        vm.prank(testAccount1);
        forwardContractBatchToken.setApprovalForAll(testAccount0, true);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(batchId0, testAccount1);
        forwardContractBatchToken.safeBatchTransferFrom(
            testAccount1,
            testAccount2,
            batchIds,
            transferAmounts,
            ""
        );
    }

    function testSafeBatchTransferFrom_revertsIfComplianceCheckFails_toAddress() public {
        uint[] memory batchIds = _toArray(batchId0);
        uint[] memory transferAmounts = _toArray(100);

        forwardContractBatchToken.setKYCRequired(batchId0, true);
        verificationRegistry.registerVerification(testAccount0);
        verificationRegistry.registerVerification(testAccount1);

        vm.prank(testAccount1);
        forwardContractBatchToken.setApprovalForAll(testAccount0, true);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(batchId0, testAccount2);
        forwardContractBatchToken.safeBatchTransferFrom(
            testAccount1,
            testAccount2,
            batchIds,
            transferAmounts,
            ""
        );
    }

    function testSafeBatchTransferFrom_revertsIfComplianceCheckFails_spender() public {
        uint[] memory batchIds = _toArray(batchId0);
        uint[] memory transferAmounts = _toArray(100);

        forwardContractBatchToken.setKYCRequired(batchId0, true);
        verificationRegistry.registerVerification(testAccount1);
        verificationRegistry.registerVerification(testAccount2);

        vm.prank(testAccount1);
        forwardContractBatchToken.setApprovalForAll(testAccount0, true);

        vm.prank(testAccount0);
        _expectRevert_NotRegulatoryCompliant(batchId0, testAccount0);
        forwardContractBatchToken.safeBatchTransferFrom(
            testAccount1,
            testAccount2,
            batchIds,
            transferAmounts,
            ""
        );
    }

    function testMint_revertsIfComplianceCheckFails_toAddress() public {
        uint amount = 100;

        forwardContractBatchToken.setKYCRequired(batchId0, true);

        _expectRevert_NotRegulatoryCompliant(batchId0, testAccount0);
        forwardContractBatchToken.mint(testAccount0, batchId0, amount, "");

        verificationRegistry.blacklist(testAccount0);

        _expectRevert_NotRegulatoryCompliant(batchId1, testAccount0);
        forwardContractBatchToken.mint(testAccount0, batchId1, amount, "");
    }

    function testSetApprovalForAll_revertsIfComplianceCheckFails_caller() public {
        verificationRegistry.blacklist(testAccount0);

        vm.prank(testAccount0);
        _expectRevert_Blacklisted(testAccount0);
        forwardContractBatchToken.setApprovalForAll(testAccount1, true);
    }

    function testSetApprovalForAll_revertsIfComplianceCheckFails_operator() public {
        verificationRegistry.blacklist(testAccount1);

        vm.prank(testAccount0);
        _expectRevert_Blacklisted(testAccount1);
        forwardContractBatchToken.setApprovalForAll(testAccount1, true);
    }

    function testCompliance_ownerIsWhitelisted() public {
        forwardContractBatchToken.setKYCRequired(batchId0, true);
        verificationRegistry.registerVerification(testAccount0);

        forwardContractBatchToken.safeTransferFrom(address(this), testAccount0, batchId0, 100, "");

        verificationRegistry.blacklist(address(this));

        forwardContractBatchToken.safeBatchTransferFrom(
            address(this),
            testAccount0,
            _toArray(batchId0),
            _toArray(100),
            ""
        );
    }
}
