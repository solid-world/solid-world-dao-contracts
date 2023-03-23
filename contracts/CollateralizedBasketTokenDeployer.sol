// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CollateralizedBasketToken.sol";
import "./compliance/VerificationRegistry.sol";

contract CollateralizedBasketTokenDeployer is Ownable, RegulatoryCompliant {
    constructor(address _verificationRegistry) RegulatoryCompliant(_verificationRegistry) {}

    function setVerificationRegistry(address _verificationRegistry) public override onlyOwner {
        super.setVerificationRegistry(_verificationRegistry);
    }

    function deploy(string calldata tokenName, string calldata tokenSymbol)
        external
        returns (CollateralizedBasketToken token)
    {
        token = new CollateralizedBasketToken(tokenName, tokenSymbol, getVerificationRegistry());
        token.transferOwnership(msg.sender);
    }
}
