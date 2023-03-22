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

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override regulatoryCompliant(id, from) regulatoryCompliant(id, to) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override batchRegulatoryCompliant(ids, from) batchRegulatoryCompliant(ids, to) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @dev only owner
    /// @param to address of the owner of new token
    /// @param id id of new token
    /// @param amount amount of new token
    /// @param data external data
    function mint(
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) public onlyOwner {
        _mint(to, id, amount, data);
    }

    /// @dev only owner
    /// @param account address of the owner of token what is burned
    /// @param id id of token what is burned
    /// @param amount amount of token what is burned
    function burn(
        address account,
        uint id,
        uint amount
    ) public onlyOwner {
        _burn(account, id, amount);
    }

    function _checkValidCounterparty(uint batchId, address subject) private view {
        if (!isValidCounterparty(subject, kycRequired[batchId])) {
            revert NotRegulatoryCompliant(batchId, subject);
        }
    }
}
