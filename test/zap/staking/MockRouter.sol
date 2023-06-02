// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "../../liquidity-deployer/TestToken.sol";
import "./RouterBehaviour.sol";

contract MockRouter {
    TestToken public immutable token0;
    TestToken public immutable token1;

    constructor(address _token0, address _token1) {
        token0 = TestToken(_token0);
        token1 = TestToken(_token1);
    }

    function swap(uint behaviour, uint acquiredAmount) external {
        if (behaviour == uint(RouterBehaviour.MINTS_TOKEN0)) {
            token0.mint(msg.sender, acquiredAmount);
        } else if (behaviour == uint(RouterBehaviour.MINTS_TOKEN1)) {
            token1.mint(msg.sender, acquiredAmount);
        } else if (behaviour == uint(RouterBehaviour.REVERTS_NO_REASON)) {
            revert();
        } else if (behaviour == uint(RouterBehaviour.REVERTS_WITH_REASON)) {
            revert("invalid_swap");
        }
    }
}
