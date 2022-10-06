// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ABDKMath64x64.sol";

/**
 * @notice Solid World DAO Math Operations and Constants.
 * @author Solid World DAO
 */
library SolidMath {
    /**
     * @dev The basis value in which the `interest rate per week` must be expressed
     * @dev 100% = 1_000_000
     */
    uint constant BASIS = 1_000_000;

    uint constant HALF_A_WEEK = 3 days + 12 hours;

    /**
     * @dev Computes the number of weeks between two dates
     * @param startDate start date expressed in seconds
     * @param endDate end date expressed in seconds
     */
    function weeksBetween(uint startDate, uint endDate) public pure returns (bool, uint) {
        if (startDate < 1 weeks || endDate < 1 weeks || endDate < startDate) {
            return (false, 0);
        }

        uint secondsBetweenDates = endDate - startDate;
        uint weeksBetweenDates = secondsBetweenDates / 1 weeks;
        uint remainder = secondsBetweenDates % 1 weeks;
        if (remainder >= HALF_A_WEEK) {
            weeksBetweenDates++;
        }

        return (true, weeksBetweenDates);
    }

    /**
     * @dev Computes discount with `interestRate` after `numWeeks` weeks
     * @param numWeeks number of weeks until delivery
     * @param interestRate 1% = 10000, 0.0984% = 984
     */
    function computeDiscount(uint interestRate, uint numWeeks) public pure returns (uint) {
        uint discountRatePoints = BASIS - interestRate;

        if (numWeeks <= 1) {
            return discountRatePoints;
        }

        int128 discountRate = ABDKMath64x64.div(discountRatePoints, BASIS);
        int128 totalDiscount = ABDKMath64x64.pow(discountRate, (numWeeks - 1));

        return ABDKMath64x64.mulu(totalDiscount, discountRatePoints);
    }

    /**
     * @dev Computes the amount of ERC-20 tokens to be payed out to user and DAO
     * @param numWeeks number of weeks until project delivery
     * @param totalToken amount of ERC-1155 forward contract batch tokens
     * @param interestRate 1% = 10000, 0.0984% = 984
     * @param daoFee 1% = 1
     * @param ctDecimals commodity token number of decimals
     */
    function payout(
        uint numWeeks,
        uint totalToken,
        uint interestRate,
        uint daoFee,
        uint8 ctDecimals
    ) public pure returns (uint, uint) {
        uint coefficient = BASIS * 100;
        uint discount = computeDiscount(interestRate, numWeeks);
        uint tokensToPayout = totalToken * discount * 10**ctDecimals;

        uint userPayout = (tokensToPayout * (100 - daoFee)) / coefficient;
        uint daoPayout = (tokensToPayout * daoFee) / coefficient;

        return (userPayout, daoPayout);
    }
}
