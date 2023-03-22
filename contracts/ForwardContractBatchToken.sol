// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./compliance/RegulatoryCompliant.sol";

/// @notice ERC-1155 for working with forward contract batch tokens
/// @author Solid World DAO
contract ForwardContractBatchToken is ERC1155, Ownable, RegulatoryCompliant {
    constructor(string memory uri, address _verificationRegistry)
        ERC1155(uri)
        RegulatoryCompliant(_verificationRegistry)
    {}

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
}
