// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestERC1155 is ERC1155 {
    constructor(string memory uri_) ERC1155(uri_) {}

    function mint(
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) public {
        _mint(to, id, amount, data);
    }
}
