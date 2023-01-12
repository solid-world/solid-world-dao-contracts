// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice Solid World DAO Math Operations and Constants.
/// @author Solid World DAO
library SolidMath {
    /// @dev Basis points in which the `time appreciation` must be expressed
    /// @dev 100% = 1_000_000; 1% = 10_000; 0.0984% = 984
    uint constant TIME_APPRECIATION_BASIS_POINTS = 1_000_000;

    uint constant DAYS_IN_YEAR = 365;

    /// @dev Basis points used to express various DAO fees
    /// @dev 100% = 10_000; 0.01% = 1
    uint constant FEE_BASIS_POINTS = 10_000;

    error IncorrectDates(uint startDate, uint endDate);
    error InvalidTADiscount();

    /// @dev Computes the number of weeks between two dates
    /// @param startDate start date expressed in seconds
    /// @param endDate end date expressed in seconds
    /// @return number of weeks between the two dates. Returns 0 if result is negative
    function weeksBetween(uint startDate, uint endDate) internal pure returns (uint) {
        if (startDate == 0 || endDate == 0) {
            revert IncorrectDates(startDate, endDate);
        }

        if (endDate <= startDate) {
            return 0;
        }

        return (endDate - startDate) / 1 weeks;
    }

    /// @dev Computes the number of years between two dates. E.g. 6.54321 years.
    /// @param startDate start date expressed in seconds
    /// @param endDate end date expressed in seconds
    /// @return number of years between the two dates. Returns 0 if result is negative
    function yearsBetween(uint startDate, uint endDate) internal pure returns (int128) {
        if (startDate == 0 || endDate == 0) {
            revert IncorrectDates(startDate, endDate);
        }

        if (endDate <= startDate) {
            return 0;
        }

        return toYears(endDate - startDate);
    }

    /// @dev Computes discount for given `timeAppreciation` and project `certificationDate`
    /// @dev Computes: (1 - timeAppreciation) ** yearsTillCertification
    /// @dev Taking form: e ** (ln(1 - timeAppreciation) * yearsTillCertification)
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param certificationDate expected date for project certification
    /// @return timeAppreciationDiscountPoints discount in basis points
    function computeTimeAppreciationDiscount(uint timeAppreciation, uint certificationDate)
        internal
        view
        returns (uint timeAppreciationDiscountPoints)
    {
        int128 yearsTillCertification = yearsBetween(block.timestamp, certificationDate);
        if (yearsTillCertification == 0) {
            return TIME_APPRECIATION_BASIS_POINTS;
        }

        int128 discount = ABDKMath64x64.div(
            TIME_APPRECIATION_BASIS_POINTS - timeAppreciation,
            TIME_APPRECIATION_BASIS_POINTS
        );
        int128 discountLN = ABDKMath64x64.ln(discount);
        int128 timeAppreciationDiscount = ABDKMath64x64.exp(
            ABDKMath64x64.mul(discountLN, yearsTillCertification)
        );
        timeAppreciationDiscountPoints = ABDKMath64x64.mulu(
            timeAppreciationDiscount,
            SolidMath.TIME_APPRECIATION_BASIS_POINTS
        );

        if (timeAppreciationDiscountPoints == 0) {
            revert InvalidTADiscount();
        }
    }

    /// @dev Computes the amount of ERC20 tokens to be minted to the stakeholder and DAO,
    /// @dev and the amount forfeited when collateralizing `fcbtAmount` of ERC1155 tokens
    /// @dev cbtUserCut = erc1155 * 10e18 * (1 - fee) * (1 - timeAppreciation) ** yearsTillCertification
    /// @dev we assume fcbtAmount is less than type(uint256).max / 1e18
    /// @param certificationDate expected date for project certification. Must not be in the past.
    /// @param fcbtAmount amount of ERC1155 tokens to be collateralized
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param collateralizationFee 0.01% = 1
    /// @param cbtDecimals collateralized basket token number of decimals
    /// @return amount of ERC20 tokens to be minted to the stakeholder
    /// @return amount of ERC20 tokens to be minted to the DAO
    /// @return amount of ERC20 tokens forfeited for collateralizing the ERC1155 tokens
    function computeCollateralizationOutcome(
        uint certificationDate,
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
        assert(certificationDate > block.timestamp);

        uint timeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            certificationDate
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

    /// @dev Computes the amount of ERC1155 tokens redeemable by the stakeholder, amount of ERC20 tokens
    /// @dev charged by the DAO and to be burned when decollateralizing `cbtAmount` of ERC20 tokens
    /// @dev erc1155 = erc20 / 10e18 * (1 - fee) / (1 - timeAppreciation) ** yearsTillCertification
    /// @dev we assume cbtAmount is less than type(uint256).max / SolidMath.TIME_APPRECIATION_BASIS_POINTS
    /// @param certificationDate expected date for project certification
    /// @param cbtAmount amount of ERC20 tokens to be decollateralized
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param decollateralizationFee 0.01% = 1
    /// @param cbtDecimals collateralized basket token number of decimals
    /// @return amount of ERC1155 tokens redeemable by the stakeholder
    /// @return amount of ERC20 tokens charged by the DAO
    /// @return amount of ERC20 tokens to be burned from the stakeholder
    function computeDecollateralizationOutcome(
        uint certificationDate,
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
            certificationDate
        );

        uint fcbtAmount = Math.mulDiv(
            cbtToBurn,
            TIME_APPRECIATION_BASIS_POINTS,
            timeAppreciationDiscount
        );

        return (fcbtAmount / 10**cbtDecimals, cbtDaoCut, cbtToBurn);
    }

    /// @dev Computes the minimum amount of ERC20 tokens to decollateralize in order to redeem `expectedFcbtAmount`
    /// @dev and the amount of ERC20 tokens charged by the DAO for decollateralizing the minimum amount of ERC20 tokens
    /// @param certificationDate expected date for project certification
    /// @param expectedFcbtAmount amount of ERC1155 tokens to be redeemed
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param decollateralizationFee 0.01% = 1
    /// @param cbtDecimals collateralized basket token number of decimals
    /// @return minAmountIn minimum amount of ERC20 tokens to decollateralize in order to redeem `expectedFcbtAmount`
    /// @return minCbtDaoCut amount of ERC20 tokens charged by the DAO for decollateralizing minAmountIn ERC20 tokens
    function computeDecollateralizationMinAmountInAndDaoCut(
        uint certificationDate,
        uint expectedFcbtAmount,
        uint timeAppreciation,
        uint decollateralizationFee,
        uint cbtDecimals
    ) internal view returns (uint minAmountIn, uint minCbtDaoCut) {
        uint timeAppreciationDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            certificationDate
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
    /// @param certificationDate expected date for project certification
    /// @param availableCredits amount of ERC1155 tokens backing the reward
    /// @param timeAppreciation 1% = 10000, 0.0984% = 984
    /// @param rewardsFee fee charged by DAO on the weekly carbon rewards
    /// @param decimals reward token number of decimals
    /// @return netRewardAmount ERC20 reward amount. Returns 0 if `certificationDate` is in the past
    /// @return feeAmount fee amount charged by the DAO. Returns 0 if `certificationDate` is in the past
    function computeWeeklyBatchReward(
        uint certificationDate,
        uint availableCredits,
        uint timeAppreciation,
        uint rewardsFee,
        uint decimals
    ) internal view returns (uint netRewardAmount, uint feeAmount) {
        if (certificationDate <= block.timestamp) {
            return (0, 0);
        }

        uint oldDiscount = computeTimeAppreciationDiscount(
            timeAppreciation,
            certificationDate + 1 weeks
        );
        uint newDiscount = computeTimeAppreciationDiscount(timeAppreciation, certificationDate);

        uint grossRewardAmount = Math.mulDiv(
            availableCredits * (newDiscount - oldDiscount),
            10**decimals,
            TIME_APPRECIATION_BASIS_POINTS
        );

        feeAmount = Math.mulDiv(grossRewardAmount, rewardsFee, FEE_BASIS_POINTS);
        netRewardAmount = grossRewardAmount - feeAmount;
    }

    function toYears(uint seconds_) internal pure returns (int128) {
        uint weeks_ = seconds_ / 1 weeks;
        if (weeks_ == 0) {
            return 0;
        }

        uint days_ = weeks_ * 7;

        return ABDKMath64x64.div(days_, DAYS_IN_YEAR);
    }
}
