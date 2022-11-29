//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract MockUniswapV3Factory {
    address public immutable pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address) {
        return pool;
    }
}
