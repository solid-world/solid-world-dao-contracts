// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./LiquidityDeployerDataTypes.sol";

/// @author Solid World
library LiquidityDeployerMath {
    error TokenAmountTooSmall(uint amount);
    error InvalidAdjustmentFactor(uint numerator, uint denominator);

    /// @return tokenAmountConvertedDecimals = tokenAmount * 10**newDecimals / 10**currentDecimals
    function convertTokenDecimals(
        uint currentDecimals,
        uint newDecimals,
        uint tokenAmount
    ) internal pure returns (uint tokenAmountConvertedDecimals) {
        tokenAmountConvertedDecimals = Math.mulDiv(tokenAmount, 10**newDecimals, 10**currentDecimals);

        if (tokenAmountConvertedDecimals == 0) {
            revert TokenAmountTooSmall(tokenAmount);
        }

        return tokenAmountConvertedDecimals;
    }

    /// @return tokenConverted = tokenAmountConvertedDecimals * conversionRate / 10 ** conversionRateDecimals
    function convertTokenValue(
        uint currentDecimals,
        uint newDecimals,
        uint conversionRate,
        uint conversionRateDecimals,
        uint tokenAmount
    ) internal pure returns (uint tokenConverted) {
        uint tokenAmountConvertedDecimals = convertTokenDecimals(currentDecimals, newDecimals, tokenAmount);

        tokenConverted = Math.mulDiv(
            tokenAmountConvertedDecimals,
            conversionRate,
            10**conversionRateDecimals
        );

        if (tokenConverted == 0) {
            revert TokenAmountTooSmall(tokenAmount);
        }

        return tokenConverted;
    }

    function neutralAdjustmentFactor()
        internal
        pure
        returns (LiquidityDeployerDataTypes.AdjustmentFactor memory)
    {
        return LiquidityDeployerDataTypes.AdjustmentFactor(1, 1);
    }

    function adjustTokenAmount(
        uint amount,
        LiquidityDeployerDataTypes.AdjustmentFactor memory adjustmentFactor
    ) internal pure returns (uint) {
        if (adjustmentFactor.denominator == 0) {
            revert InvalidAdjustmentFactor(adjustmentFactor.numerator, adjustmentFactor.denominator);
        }

        if (_isNeutralAdjustmentFactor(adjustmentFactor)) {
            return amount;
        }

        return Math.mulDiv(amount, adjustmentFactor.numerator, adjustmentFactor.denominator);
    }

    function _isNeutralAdjustmentFactor(LiquidityDeployerDataTypes.AdjustmentFactor memory adjustmentFactor)
        private
        pure
        returns (bool)
    {
        return adjustmentFactor.numerator == adjustmentFactor.denominator;
    }
}
