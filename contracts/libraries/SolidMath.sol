// SPDX-License-Identifier: UNLICENSED
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
     * @return number of weeks between the two dates
     */
    function weeksBetween(uint startDate, uint endDate) internal pure returns (uint) {
        if (startDate < 1 weeks || endDate < 1 weeks || endDate < startDate) {
            revert IncorrectDates(startDate, endDate);
        }

        return (endDate - startDate) / 1 weeks;
    }

    /**
     * @dev Computes discount for given `timeAppreciation` and project `expectedCertificationDate`
     * @dev (1 - timeAppreciation) ** weeksUntilCertification
     * @param timeAppreciation 1% = 10000, 0.0984% = 984
     * @param expectedCertificationDate expected date for project certification
     * @return discount in basis points
     */
    function computeTimeAppreciationDiscount(uint timeAppreciation, uint expectedCertificationDate)
        internal
        view
        returns (uint)
    {
        uint weeksUntilCertification = weeksBetween(block.timestamp, expectedCertificationDate);

        uint discountRatePoints = TIME_APPRECIATION_BASIS_POINTS - timeAppreciation;

        if (weeksUntilCertification <= 1) {
            return discountRatePoints;
        }

        int128 discountRate = ABDKMath64x64.div(discountRatePoints, TIME_APPRECIATION_BASIS_POINTS);
        int128 totalDiscount = ABDKMath64x64.pow(discountRate, (weeksUntilCertification - 1));

        return ABDKMath64x64.mulu(totalDiscount, discountRatePoints);
    }

    /**
     * @dev Computes the amount of ERC20 tokens to be minted to the stakeholder and DAO,
     * @dev and the amount forfeited when collateralizing `fcbtAmount` of ERC1155 tokens
     * @dev cbtUserCut = erc1155 * 10e18 * (1 - fee) * (1 - timeAppreciation) ** weeksUntilCertification
     * @param expectedCertificationDate expected date for project certification
     * @param fcbtAmount amount of ERC1155 tokens to be collateralized
     * @param timeAppreciation 1% = 10000, 0.0984% = 984
     * @param collateralizationFee 0.01% = 1
     * @param cbtDecimals collateralized basket token number of decimals
     * @return amount of ERC20 tokens to be minted to the stakeholder
     * @return amount of ERC20 tokens to be minted to the DAO
     * @return amount of ERC20 tokens forfeited for collateralizing the ERC1155 tokens
     */
    function computeCollateralizationOutcome(
        uint expectedCertificationDate,
        uint fcbtAmount,
        uint timeAppreciation,
        uint collateralizationFee,
        uint cbtDecimals
    )
        internal
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        uint timeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );
        uint mintableCbtAmount = Math.mulDiv(
            fcbtAmount * timeAppreciationDiscount,
            10**cbtDecimals,
            TIME_APPRECIATION_BASIS_POINTS
        );

        uint cbtDaoCut = Math.mulDiv(mintableCbtAmount, collateralizationFee, FEE_BASIS_POINTS);
        uint cbtUserCut = mintableCbtAmount - cbtDaoCut;
        uint cbtForfeited = fcbtAmount * 10**cbtDecimals - mintableCbtAmount;

        return (cbtUserCut, cbtDaoCut, cbtForfeited);
    }

    /**
     * @dev Computes the amount of ERC1155 tokens redeemable by the stakeholder, amount of ERC20 tokens
     * @dev charged by the DAO and to be burned when decollateralizing `cbtAmount` of ERC20 tokens
     * @dev erc1155 = erc20 / 10e18 * (1 - fee) / (1 - timeAppreciation) ** weeksUntilCertification
     * @param expectedCertificationDate expected date for project certification
     * @param cbtAmount amount of ERC20 tokens to be decollateralized
     * @param timeAppreciation 1% = 10000, 0.0984% = 984
     * @param decollateralizationFee 0.01% = 1
     * @param cbtDecimals collateralized basket token number of decimals
     * @return amount of ERC1155 tokens redeemable by the stakeholder
     * @return amount of ERC20 tokens charged by the DAO
     * @return amount of ERC20 tokens to be burned from the stakeholder
     */
    function computeDecollateralizationOutcome(
        uint expectedCertificationDate,
        uint cbtAmount,
        uint timeAppreciation,
        uint decollateralizationFee,
        uint cbtDecimals
    )
        internal
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        uint cbtDaoCut = Math.mulDiv(cbtAmount, decollateralizationFee, FEE_BASIS_POINTS);
        uint cbtToBurn = cbtAmount - cbtDaoCut;

        uint timeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );

        uint fcbtAmount = Math.mulDiv(
            cbtToBurn,
            TIME_APPRECIATION_BASIS_POINTS,
            timeAppreciationDiscount
        );

        return (fcbtAmount / 10**cbtDecimals, cbtDaoCut, cbtToBurn);
    }

    /**
     * @dev Computes the minimum amount of ERC20 tokens to decollateralize in order to redeem `fcbtAmount`
     * @dev and the amount of ERC20 tokens charged by the DAO for decollateralizing the minimum amount of ERC20 tokens
     * @param expectedCertificationDate expected date for project certification
     * @param expectedFcbtAmount amount of ERC1155 tokens to be redeemed
     * @param timeAppreciation 1% = 10000, 0.0984% = 984
     * @param decollateralizationFee 0.01% = 1
     * @param cbtDecimals collateralized basket token number of decimals
     * @return minAmountIn minimum amount of ERC20 tokens to decollateralize in order to redeem `fcbtAmount`
     * @return minCbtDaoCut amount of ERC20 tokens charged by the DAO for decollateralizing minAmountIn ERC20 tokens
     */
    function computeDecollateralizationMinAmountInAndDaoCut(
        uint expectedCertificationDate,
        uint expectedFcbtAmount,
        uint timeAppreciation,
        uint decollateralizationFee,
        uint cbtDecimals
    ) internal view returns (uint minAmountIn, uint minCbtDaoCut) {
        uint timeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );

        uint minAmountInAfterFee = Math.mulDiv(
            expectedFcbtAmount * timeAppreciationDiscount,
            10**cbtDecimals,
            TIME_APPRECIATION_BASIS_POINTS
        );

        minAmountIn = Math.mulDiv(
            minAmountInAfterFee,
            FEE_BASIS_POINTS,
            FEE_BASIS_POINTS - decollateralizationFee
        );

        minCbtDaoCut = Math.mulDiv(minAmountIn, decollateralizationFee, FEE_BASIS_POINTS);
    }

    /// @dev Computes the amount of ERC20 tokens to be rewarded over the next 7 days
    /// @dev erc1155 * 10e18 * ((1 - timeApn) ** weeks - (1 - timeApn) ** (weeks + 1))
    /// @param expectedCertificationDate expected date for project certification
    /// @param availableCredits amount of ERC1155 tokens backing the reward
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param decimals reward token number of decimals
    /// @return rewardAmount ERC20 reward amount
    function computeWeeklyBatchReward(
        uint expectedCertificationDate,
        uint availableCredits,
        uint timeAppreciation,
        uint decimals
    ) internal view returns (uint rewardAmount) {
        rewardAmount = 0;

        uint currentTimeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate
        );

        uint previousTimeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            expectedCertificationDate + 1 weeks
        );

        rewardAmount = Math.mulDiv(
            availableCredits * (currentTimeAppreciationDiscount - previousTimeAppreciationDiscount),
            10**decimals,
            TIME_APPRECIATION_BASIS_POINTS
        );
    }
}
