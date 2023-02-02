// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract MockUniswapV3Factory {
    address public immutable pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function getPool(
        address,
        address,
        uint24
    ) external view returns (address) {
        return pool;
    }
}
