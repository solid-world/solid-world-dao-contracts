// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./compliance/RegulatoryCompliant.sol";

/// @notice ERC-20 for working with forward commodity tokens
/// @author Solid World DAO
contract CollateralizedBasketToken is ERC20Burnable, Ownable, RegulatoryCompliant {
    constructor(
        string memory name,
        string memory symbol,
        address _verificationRegistry
    ) ERC20(name, symbol) RegulatoryCompliant(_verificationRegistry) {}

    function mint(address account, uint amount) public onlyOwner {
        _mint(account, amount);
    }
}
