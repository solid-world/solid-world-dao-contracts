// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./CTERC20.sol";

contract Erc20Deployer {
    function deploy(
        address owner,
        string memory name,
        string memory symbol
    ) external returns (address) {
        CTERC20TokenTemplate token = new CTERC20TokenTemplate(name, symbol);
        token.initialize(owner);
        return address(token);
    }
}
