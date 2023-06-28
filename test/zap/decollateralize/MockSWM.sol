// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./TestERC1155.sol";
import "../../liquidity-deployer/TestToken.sol";

contract MockSWM {
    TestERC1155 private fcbt;
    TestToken private crispToken;

    constructor(TestERC1155 _fcbt, TestToken _crispToken) {
        fcbt = _fcbt;
        crispToken = _crispToken;
    }

    function bulkDecollateralizeTokens(
        uint[] calldata batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external {
        for (uint i; i < batchIds.length; i++) {
            crispToken.transferFrom(msg.sender, address(this), amountsIn[i]);
            fcbt.mint(msg.sender, batchIds[i], amountsOutMin[i], "");
        }
    }
}
