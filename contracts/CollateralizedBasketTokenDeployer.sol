// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./CollateralizedBasketToken.sol";

contract CollateralizedBasketTokenDeployer {
    function deploy(string calldata tokenName, string calldata tokenSymbol)
        external
        returns (CollateralizedBasketToken token)
    {
        token = new CollateralizedBasketToken(tokenName, tokenSymbol);
        token.transferOwnership(msg.sender);
    }
}
