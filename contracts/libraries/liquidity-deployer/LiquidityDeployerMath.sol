// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";

/// @author Solid World
library LiquidityDeployerMath {
    error Token0AmountTooSmall(uint amount);

    /// @return token0AmountConvertedDecimals = token0Amount * 10**token1Decimals / 10**token0Decimals
    function convertToken0DecimalsToToken1(
        uint token0Decimals,
        uint token1Decimals,
        uint token0Amount
    ) public pure returns (uint token0AmountConvertedDecimals) {
        token0AmountConvertedDecimals = Math.mulDiv(token0Amount, 10**token1Decimals, 10**token0Decimals);

        if (token0AmountConvertedDecimals == 0) {
            revert Token0AmountTooSmall(token0Amount);
        }

        return token0AmountConvertedDecimals;
    }

    /// @return token0Converted = token0AmountConvertedDecimals * conversionRate / 10 ** conversionRateDecimals
    function convertToken0ValueToToken1(
        uint token0Decimals,
        uint token1Decimals,
        uint conversionRate,
        uint conversionRateDecimals,
        uint token0Amount
    ) public pure returns (uint token0Converted) {
        uint token0AmountConvertedDecimals = convertToken0DecimalsToToken1(
            token0Decimals,
            token1Decimals,
            token0Amount
        );

        token0Converted = Math.mulDiv(
            token0AmountConvertedDecimals,
            conversionRate,
            10**conversionRateDecimals
        );

        if (token0Converted == 0) {
            revert Token0AmountTooSmall(token0Amount);
        }

        return token0Converted;
    }
}
