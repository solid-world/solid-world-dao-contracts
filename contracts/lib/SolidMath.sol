// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @notice Solid World DAO Math Operations and Constants.
 * @author Solid World DAO
 */
library SolidMath {
    /**
     * @dev Basis points in which the `time appreciation` must be expressed
     * @dev 100% = 1_000_000; 1% = 10_000; 0.0984% = 984
     */
    uint constant TIME_APPRECIATION_BASIS_POINTS = 1_000_000;

    /**
     * @dev Basis points used to express various DAO fees
     * @dev 100% = 10_000; 0.01% = 1
     */
    uint constant FEE_BASIS_POINTS = 10_000;

    error IncorrectDates(uint startDate, uint endDate);

    /**
     * @dev Computes the number of weeks between two dates
     * @param startDate start date expressed in seconds
     * @param endDate end date expressed in seconds
     */
    function weeksBetween(uint startDate, uint endDate) internal pure returns (uint) {
        if (startDate < 1 weeks || endDate < 1 weeks || endDate < startDate) {
            revert IncorrectDates(startDate, endDate);
        }

        return (endDate - startDate) / 1 weeks;
    }

    /**
     * @dev Computes discount with `timeAppreciation` after `weeksUntilCertification` weeks
     * @dev (1 - timeAppreciation) ^ weeksUntilCertification
     * @param timeAppreciation 1% = 10000, 0.0984% = 984
     * @param weeksUntilCertification number of weeks until project certification
     */
    function computeCollateralizationDiscount(uint timeAppreciation, uint weeksUntilCertification)
        internal
        pure
        returns (uint)
    {
        uint discountRatePoints = TIME_APPRECIATION_BASIS_POINTS - timeAppreciation;

        if (weeksUntilCertification <= 1) {
            return discountRatePoints;
        }

        int128 discountRate = ABDKMath64x64.div(discountRatePoints, TIME_APPRECIATION_BASIS_POINTS);
        int128 totalDiscount = ABDKMath64x64.pow(discountRate, (weeksUntilCertification - 1));

        return ABDKMath64x64.mulu(totalDiscount, discountRatePoints);
    }

    /**
     * @dev Computes the amount of ERC20 tokens to be minted to the stakeholder and DAO when collateralizing `fcbtAmount` of ERC1155 tokens
     * @param expectedCertificationDate expected date for project certification
     * @param fcbtAmount amount of ERC1155 tokens to be collateralized
     * @param timeAppreciation 1% = 10000, 0.0984% = 984
     * @param collateralizationFee 0.01% = 1
     * @param cbtDecimals collateralized basket token number of decimals
     */
    function computeCollateralizationOutcome(
        uint expectedCertificationDate,
        uint fcbtAmount,
        uint timeAppreciation,
        uint collateralizationFee,
        uint cbtDecimals
    ) internal view returns (uint, uint) {
        uint weeksUntilCertification = weeksBetween(block.timestamp, expectedCertificationDate);

        uint collateralizationDiscount = computeCollateralizationDiscount(
            timeAppreciation,
            weeksUntilCertification
        );
        uint cbtAmount = Math.mulDiv(
            fcbtAmount * collateralizationDiscount,
            10**cbtDecimals,
            TIME_APPRECIATION_BASIS_POINTS
        );

        uint cbtDaoCut = Math.mulDiv(cbtAmount, collateralizationFee, FEE_BASIS_POINTS);
        uint cbtUserCut = cbtAmount - cbtDaoCut;

        return (cbtUserCut, cbtDaoCut);
    }
}
