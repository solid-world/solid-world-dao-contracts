// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "./DomainDataTypes.sol";
import "./SolidMath.sol";

library ReactiveTimeAppreciationMath {
    /// @dev Basis points in which the `decayPerSecond` must be expressed
    uint constant DECAY_BASIS_POINTS = 100_000_000_000;

    /// @dev Basis points in which the `maxDepreciationPerYear` must be expressed
    uint constant DEPRECIATION_BASIS_POINTS = 10;

    error ForwardCreditsInputAmountTooLarge(uint forwardCreditsAmount);

    /// @dev Computes a time appreciation value that is reactive to market conditions
    /// @dev The reactive time appreciation starts at averageTA - maxDepreciation and increases with momentum and input amount
    /// @param categoryState The current state of the category to compute the time appreciation for
    /// @param forwardCreditsAmount The size of the forward credits to be collateralized
    /// @return decayingMomentum The current decaying momentum of the category
    /// @return reactiveTA The time appreciation value influenced by current market conditions
    function computeReactiveTA(
        DomainDataTypes.Category memory categoryState,
        uint forwardCreditsAmount
    ) internal view returns (uint decayingMomentum, uint reactiveTA) {
        if (categoryState.volumeCoefficient == 0) {
            return (0, categoryState.averageTA);
        }

        decayingMomentum = computeDecayingMomentum(
            categoryState.decayPerSecond,
            categoryState.lastCollateralizationMomentum,
            categoryState.lastCollateralizationTimestamp
        );

        uint volume = decayingMomentum + forwardCreditsAmount / 2;
        uint reactiveFactorAnnually = Math.mulDiv(
            volume,
            SolidMath.TIME_APPRECIATION_BASIS_POINTS,
            categoryState.volumeCoefficient * 100
        );
        if (reactiveFactorAnnually >= SolidMath.TIME_APPRECIATION_BASIS_POINTS) {
            revert ForwardCreditsInputAmountTooLarge(forwardCreditsAmount);
        }

        uint reactiveFactorWeekly = toWeeklyRate(reactiveFactorAnnually);
        reactiveTA = categoryState.averageTA - categoryState.maxDepreciation + reactiveFactorWeekly;

        if (reactiveTA >= SolidMath.TIME_APPRECIATION_BASIS_POINTS) {
            revert ForwardCreditsInputAmountTooLarge(forwardCreditsAmount);
        }
    }

    /// @dev Decays the `lastCollateralizationMomentum` with the `decayPerSecond` rate since the `lastCollateralizationTimestamp`
    /// @dev e.g a momentum of 100 with a decay of 5% per day will decay to 95 after 1 day
    /// @dev The minimum decaying momentum is 0
    /// @param decayPerSecond The rate at which the `lastCollateralizationMomentum` decays per second
    /// @param lastCollateralizationMomentum The last collateralization momentum
    /// @param lastCollateralizationTimestamp The last collateralization timestamp
    /// @return decayingMomentum The decaying momentum value
    function computeDecayingMomentum(
        uint decayPerSecond,
        uint lastCollateralizationMomentum,
        uint lastCollateralizationTimestamp
    ) internal view returns (uint decayingMomentum) {
        uint secondsPassedSinceLastCollateralization = block.timestamp -
            lastCollateralizationTimestamp;

        int decayMultiplier = int(DECAY_BASIS_POINTS) -
            int(secondsPassedSinceLastCollateralization * decayPerSecond);
        decayMultiplier = SignedMath.max(0, decayMultiplier);

        decayingMomentum = Math.mulDiv(
            lastCollateralizationMomentum,
            uint(decayMultiplier),
            DECAY_BASIS_POINTS
        );
    }

    /// @dev Derives what the time appreciation should be for a batch based on ERC20 in circulation, underlying ERC1155
    ///      amount and its certification date
    /// @dev Computes: 1 - (circulatingCBT / totalCollateralizedBatchForwardCredits) ** (1 / weeksTillCertification)
    /// @dev Taking form: 1 - e ** (ln(circulatingCBT / totalCollateralizedBatchForwardCredits) * (1 / weeksTillCertification))
    /// @param circulatingCBT The circulating CBT amount minted for the batch
    /// @param totalCollateralizedForwardCredits The total collateralized batch forward credits
    /// @param certificationDate The batch certification date
    /// @param cbtDecimals Collateralized basket token number of decimals
    function inferBatchTA(
        uint circulatingCBT,
        uint totalCollateralizedForwardCredits,
        uint certificationDate,
        uint cbtDecimals
    ) internal view returns (uint batchTA) {
        assert(circulatingCBT != 0 && totalCollateralizedForwardCredits != 0);

        uint weeksTillCertification = SolidMath.weeksBetween(block.timestamp, certificationDate);

        if (weeksTillCertification == 0) {
            return 0;
        }

        int128 weeksTillCertificationInverse = ABDKMath64x64.inv(
            ABDKMath64x64.fromUInt(weeksTillCertification)
        );
        int128 aggregateDiscount = ABDKMath64x64.div(
            circulatingCBT,
            totalCollateralizedForwardCredits * 10**cbtDecimals
        );

        int128 aggregateDiscountLN = ABDKMath64x64.ln(aggregateDiscount);
        int128 aggregatedWeeklyDiscount = ABDKMath64x64.exp(
            ABDKMath64x64.mul(aggregateDiscountLN, weeksTillCertificationInverse)
        );
        uint aggregatedWeeklyDiscountPoints = ABDKMath64x64.mulu(
            aggregatedWeeklyDiscount,
            SolidMath.TIME_APPRECIATION_BASIS_POINTS
        );

        batchTA = SolidMath.TIME_APPRECIATION_BASIS_POINTS - aggregatedWeeklyDiscountPoints;
    }

    /// @dev Computes the initial value of momentum with the specified parameters
    /// @param volumeCoefficient The volume coefficient of the category
    /// @param maxDepreciationPerYear how much the reactive TA can drop from the averageTA value, quantified per year
    /// @return initialMomentum The initial momentum value
    function computeInitialMomentum(uint volumeCoefficient, uint maxDepreciationPerYear)
        internal
        pure
        returns (uint initialMomentum)
    {
        initialMomentum = Math.mulDiv(
            volumeCoefficient,
            maxDepreciationPerYear,
            DEPRECIATION_BASIS_POINTS
        );
    }

    /// @dev Computes the adjusted value of momentum for a category when category update event occurs
    /// @param category The category to compute the adjusted momentum for
    /// @param newVolumeCoefficient The new volume coefficient of the category
    /// @param newMaxDepreciationPerYear The new max depreciation per year of the category
    /// @return adjustedMomentum The adjusted momentum value
    function computeAdjustedMomentum(
        DomainDataTypes.Category storage category,
        uint newVolumeCoefficient,
        uint newMaxDepreciationPerYear
    ) internal view returns (uint adjustedMomentum) {
        adjustedMomentum = computeDecayingMomentum(
            category.decayPerSecond,
            category.lastCollateralizationMomentum,
            category.lastCollateralizationTimestamp
        );

        adjustedMomentum = Math.mulDiv(
            adjustedMomentum,
            newVolumeCoefficient,
            category.volumeCoefficient
        );

        int depreciationDiff = int(newMaxDepreciationPerYear) -
            int(uint(category.maxDepreciationPerYear));
        if (depreciationDiff > 0) {
            adjustedMomentum += Math.mulDiv(
                newVolumeCoefficient,
                uint(depreciationDiff),
                DEPRECIATION_BASIS_POINTS
            );
        }
    }

    /// @dev Converts a rate quantified per year to a rate quantified per week
    /// @dev Computes: 1 - (1 - annualRate) ** (1/52.1)
    /// @dev Taking form: 1 - e ** (ln(1 - annualRate) * (1/52.1))
    /// @param annualRate 1% = 10000, 0.0984% = 984
    /// @return weeklyRate the rate quantified per week
    function toWeeklyRate(uint annualRate) internal pure returns (uint weeklyRate) {
        uint annualDiscountPoints = SolidMath.TIME_APPRECIATION_BASIS_POINTS - annualRate;
        int128 annualDiscount = ABDKMath64x64.div(
            annualDiscountPoints,
            SolidMath.TIME_APPRECIATION_BASIS_POINTS
        );

        int128 annualDiscountLN = ABDKMath64x64.ln(annualDiscount);
        int128 weeksInYearInverse = ABDKMath64x64.inv(weeksInYear());
        int128 weeklyDiscount = ABDKMath64x64.exp(
            ABDKMath64x64.mul(annualDiscountLN, weeksInYearInverse)
        );
        uint weeklyDiscountPoints = ABDKMath64x64.mulu(
            weeklyDiscount,
            SolidMath.TIME_APPRECIATION_BASIS_POINTS
        );

        weeklyRate = SolidMath.TIME_APPRECIATION_BASIS_POINTS - weeklyDiscountPoints;
    }

    function weeksInYear() internal pure returns (int128) {
        return ABDKMath64x64.div(521, 10);
    }
}
