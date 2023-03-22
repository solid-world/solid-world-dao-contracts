// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/ForwardContractBatchToken.sol";
import "../../contracts/compliance/VerificationRegistry.sol";
import "../../contracts/interfaces/compliance/IVerificationRegistry.sol";

abstract contract BaseForwardContractBatchTokenTest is BaseTest, IERC1155Receiver {
    IVerificationRegistry verificationRegistry;
    ForwardContractBatchToken forwardContractBatchToken;

    address testAccount0 = vm.addr(1);
    address testAccount1 = vm.addr(2);
    address testAccount2 = vm.addr(3);

    uint batchId0 = 1;
    uint batchId1 = 2;

    event KYCRequiredSet(uint indexed batchId, bool indexed kycRequired);

    function setUp() public {
        _initVerificationRegistry();
        forwardContractBatchToken = new ForwardContractBatchToken("", address(verificationRegistry));

        _labelAccounts();
        _mintInitialTokens();
    }

    function _initVerificationRegistry() private {
        VerificationRegistry _verificationRegistry = new VerificationRegistry();
        _verificationRegistry.initialize(address(this));

        verificationRegistry = IVerificationRegistry(address(_verificationRegistry));
    }

    function _labelAccounts() private {
        vm.label(testAccount0, "testAccount0");
        vm.label(testAccount1, "testAccount1");
        vm.label(testAccount2, "testAccount2");
        vm.label(address(this), "FCBTTest");
        vm.label(address(forwardContractBatchToken), "FCBT");
        vm.label(address(verificationRegistry), "Verification Registry");
    }

    function _mintInitialTokens() private {
        forwardContractBatchToken.mint(testAccount0, batchId0, 10000, "");
        forwardContractBatchToken.mint(testAccount1, batchId0, 10000, "");
        forwardContractBatchToken.mint(testAccount2, batchId0, 10000, "");
        forwardContractBatchToken.mint(address(this), batchId0, 10000, "");

        forwardContractBatchToken.mint(testAccount0, batchId1, 10000, "");
        forwardContractBatchToken.mint(testAccount1, batchId1, 10000, "");
        forwardContractBatchToken.mint(testAccount2, batchId1, 10000, "");
        forwardContractBatchToken.mint(address(this), batchId1, 10000, "");
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

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x4e2312e0;
    }
}
