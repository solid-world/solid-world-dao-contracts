// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract MockUniswapV3Pool {
    function observe(uint32[] calldata)
        external
        pure
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s)
    {
        tickCumulatives = new int56[](2);
        tickCumulatives[0] = 0;
        tickCumulatives[1] = 300;

        secondsPerLiquidityCumulativeX128s = new uint160[](2);
        secondsPerLiquidityCumulativeX128s[0] = 100;
        secondsPerLiquidityCumulativeX128s[1] = 200;
    }
}
