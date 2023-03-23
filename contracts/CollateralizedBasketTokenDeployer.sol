// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./CollateralizedBasketToken.sol";
import "./compliance/VerificationRegistry.sol";

contract CollateralizedBasketTokenDeployer {
    // TODO #310
    address verificationRegistry = address(new VerificationRegistry());

    function deploy(string calldata tokenName, string calldata tokenSymbol)
        external
        returns (CollateralizedBasketToken token)
    {
        token = new CollateralizedBasketToken(tokenName, tokenSymbol, verificationRegistry);
        token.transferOwnership(msg.sender);
    }
}
