// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./LiquidityDeployerDataTypes.sol";

/// @author Solid World
library LiquidityDeployerMath {
    error InvalidFraction(uint numerator, uint denominator);

    /// @return tokenAmountConvertedDecimals = tokenAmount * 10**newDecimals / 10**currentDecimals
    function convertTokenDecimals(
        uint currentDecimals,
        uint newDecimals,
        uint tokenAmount
    ) internal pure returns (uint tokenAmountConvertedDecimals) {
        tokenAmountConvertedDecimals = Math.mulDiv(tokenAmount, 10**newDecimals, 10**currentDecimals);
    }

    /// @return tokenConverted = tokenAmountConvertedDecimals * conversionRate / 10 ** conversionRateDecimals
    function convertTokenValue(
        uint currentDecimals,
        uint newDecimals,
        uint conversionRate,
        uint conversionRateDecimals,
        uint tokenAmount
    ) internal pure returns (uint tokenConverted) {
        if (tokenAmount == 0) {
            tokenConverted = 0;
        }

        uint tokenAmountConvertedDecimals = convertTokenDecimals(currentDecimals, newDecimals, tokenAmount);
        if (tokenAmountConvertedDecimals == 0) {
            tokenConverted = 0;
        }

        tokenConverted = Math.mulDiv(
            tokenAmountConvertedDecimals,
            conversionRate,
            10**conversionRateDecimals
        );
    }

    function neutralFraction() internal pure returns (LiquidityDeployerDataTypes.Fraction memory) {
        return LiquidityDeployerDataTypes.Fraction(1, 1);
    }

    function adjustTokenAmount(uint amount, LiquidityDeployerDataTypes.Fraction memory adjustmentFactor)
        internal
        pure
        returns (uint)
    {
        if (adjustmentFactor.denominator == 0) {
            revert InvalidFraction(adjustmentFactor.numerator, adjustmentFactor.denominator);
        }

        if (_isNeutralFraction(adjustmentFactor)) {
            return amount;
        }

        return Math.mulDiv(amount, adjustmentFactor.numerator, adjustmentFactor.denominator);
    }

    function _isNeutralFraction(LiquidityDeployerDataTypes.Fraction memory adjustmentFactor)
        private
        pure
        returns (bool)
    {
        return adjustmentFactor.numerator == adjustmentFactor.denominator;
    }
}
