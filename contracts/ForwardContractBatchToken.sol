// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./compliance/RegulatoryCompliant.sol";

/// @notice ERC-1155 for working with forward contract batch tokens
/// @author Solid World DAO
contract ForwardContractBatchToken is ERC1155, Ownable, RegulatoryCompliant {
    /// @dev batchId => requires KYC
    mapping(uint => bool) private kycRequired;

    error NotRegulatoryCompliant(uint batchId, address subject);
    error Blacklisted(address subject);

    event KYCRequiredSet(uint indexed batchId, bool indexed kycRequired);

    modifier regulatoryCompliant(uint batchId, address subject) {
        _checkValidCounterparty(batchId, subject);
        _;
    }

    modifier batchRegulatoryCompliant(uint[] memory batchIds, address subject) {
        for (uint i; i < batchIds.length; i++) {
            _checkValidCounterparty(batchIds[i], subject);
        }
        _;
    }

    modifier notBlacklisted(address subject) {
        bool _kycRequired = false;
        if (!isValidCounterparty(subject, _kycRequired)) {
            revert Blacklisted(subject);
        }
        _;
    }

    constructor(string memory uri, address _verificationRegistry)
        ERC1155(uri)
        RegulatoryCompliant(_verificationRegistry)
    {}

    function setVerificationRegistry(address _verificationRegistry) public override onlyOwner {
        super.setVerificationRegistry(_verificationRegistry);
    }

    function setKYCRequired(uint batchId, bool _kycRequired) external onlyOwner {
        kycRequired[batchId] = _kycRequired;

        emit KYCRequiredSet(batchId, _kycRequired);
    }

    function isKYCRequired(uint batchId) external view returns (bool) {
        return kycRequired[batchId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        notBlacklisted(msg.sender)
        notBlacklisted(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        override
        regulatoryCompliant(id, msg.sender)
        regulatoryCompliant(id, from)
        regulatoryCompliant(id, to)
    {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        override
        batchRegulatoryCompliant(ids, msg.sender)
        batchRegulatoryCompliant(ids, from)
        batchRegulatoryCompliant(ids, to)
    {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function mint(
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) public onlyOwner regulatoryCompliant(id, to) {
        _mint(to, id, amount, data);
    }

    function burn(
        address from,
        uint id,
        uint amount
    ) public onlyOwner {
        _burn(from, id, amount);
    }

    function _checkValidCounterparty(uint batchId, address subject) private view {
        // owner is whitelisted
        if (subject == owner()) {
            return;
        }

        if (!isValidCounterparty(subject, kycRequired[batchId])) {
            revert NotRegulatoryCompliant(batchId, subject);
        }
    }
}
