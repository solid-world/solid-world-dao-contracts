// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "./DomainDataTypes.sol";
import "./SolidMath.sol";

library ReactiveTimeAppreciationMath {
    /// @dev Basis points in which the `decayPerSecond` must be expressed
    uint constant DECAY_BASIS_POINTS = 100_000_000_000;

    /// @dev Basis points in which the `maxDepreciation` must be expressed
    uint constant DEPRECIATION_BASIS_POINTS = 10;

    error ReactiveTAMathBroken(uint factor1, uint factor2);

    /// @dev Computes a time appreciation value that is reactive to market conditions
    /// @dev The reactive time appreciation starts at averageTA - maxDepreciation and increases with momentum and input amount
    /// @dev assume categoryState won't be a source of math over/underflow or division by zero errors
    /// @dev if forwardCreditsAmount is too large, it will cause overflow / ReactiveTAMathBroken error
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
        uint reactiveFactor = Math.mulDiv(
            volume,
            SolidMath.TIME_APPRECIATION_BASIS_POINTS,
            categoryState.volumeCoefficient * 100
        );
        reactiveTA =
            categoryState.averageTA -
            taQuantifiedDepreciation(categoryState.maxDepreciation) +
            reactiveFactor;

        if (reactiveTA >= SolidMath.TIME_APPRECIATION_BASIS_POINTS) {
            revert ReactiveTAMathBroken(
                forwardCreditsAmount,
                categoryState.lastCollateralizationMomentum
            );
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
    /// @dev Computes: 1 - (circulatingCBT / totalCollateralizedBatchForwardCredits) ** (1 / yearsTillCertification)
    /// @param circulatingCBT The circulating CBT amount minted for the batch. Assume <= 2**122.
    /// @param totalCollateralizedForwardCredits The total collateralized batch forward credits. Assume <= circulatingCBT / 1e18.
    /// @param certificationDate The batch certification date
    /// @param cbtDecimals Collateralized basket token number of decimals
    function inferBatchTA(
        uint circulatingCBT,
        uint totalCollateralizedForwardCredits,
        uint certificationDate,
        uint cbtDecimals
    ) internal view returns (uint batchTA) {
        assert(circulatingCBT != 0 && totalCollateralizedForwardCredits != 0);

        int128 yearsTillCertification = SolidMath.yearsBetween(block.timestamp, certificationDate);
        assert(yearsTillCertification != 0);

        int128 aggregateDiscount = ABDKMath64x64.div(
            circulatingCBT,
            totalCollateralizedForwardCredits * 10**cbtDecimals
        );
        int128 aggregatedYearlyDiscount = ABDKMath64x64.pow(
            aggregateDiscount,
            ABDKMath64x64.inv(yearsTillCertification)
        );
        uint aggregatedYearlyDiscountPoints = ABDKMath64x64.mulu(
            aggregatedYearlyDiscount,
            SolidMath.TIME_APPRECIATION_BASIS_POINTS
        );

        if (aggregatedYearlyDiscountPoints >= SolidMath.TIME_APPRECIATION_BASIS_POINTS) {
            revert ReactiveTAMathBroken(circulatingCBT, totalCollateralizedForwardCredits);
        }

        batchTA = SolidMath.TIME_APPRECIATION_BASIS_POINTS - aggregatedYearlyDiscountPoints;
    }

    /// @dev Determines the momentum for the specified Category based on current state and the new params
    /// @param category The category to compute the momentum for
    /// @param newVolumeCoefficient The new volume coefficient of the category
    /// @param newMaxDepreciation The new max depreciation for the category. Quantified per year.
    function inferMomentum(
        DomainDataTypes.Category memory category,
        uint newVolumeCoefficient,
        uint newMaxDepreciation
    ) internal view returns (uint) {
        if (category.volumeCoefficient == 0 || category.decayPerSecond == 0) {
            return computeInitialMomentum(newVolumeCoefficient, newMaxDepreciation);
        }

        return computeAdjustedMomentum(category, newVolumeCoefficient, newMaxDepreciation);
    }

    /// @dev Computes the initial value of momentum with the specified parameters
    /// @param volumeCoefficient The volume coefficient of the category
    /// @param maxDepreciation how much the reactive TA can drop from the averageTA value, quantified per year
    /// @return initialMomentum The initial momentum value
    function computeInitialMomentum(uint volumeCoefficient, uint maxDepreciation)
        internal
        pure
        returns (uint initialMomentum)
    {
        initialMomentum = Math.mulDiv(
            volumeCoefficient,
            maxDepreciation,
            DEPRECIATION_BASIS_POINTS
        );
    }

    /// @dev Computes the adjusted value of momentum for a category when category update event occurs
    /// @param category The category to compute the adjusted momentum for
    /// @param newVolumeCoefficient The new volume coefficient of the category
    /// @param newMaxDepreciation The new max depreciation for the category. Quantified per year.
    /// @return adjustedMomentum The adjusted momentum value
    function computeAdjustedMomentum(
        DomainDataTypes.Category memory category,
        uint newVolumeCoefficient,
        uint newMaxDepreciation
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

        int depreciationDiff = int(newMaxDepreciation) - int(uint(category.maxDepreciation));
        if (depreciationDiff > 0) {
            adjustedMomentum += Math.mulDiv(
                newVolumeCoefficient,
                uint(depreciationDiff),
                DEPRECIATION_BASIS_POINTS
            );
        }
    }

    /// @return the depreciation expressed in terms of TA basis points
    function taQuantifiedDepreciation(uint16 depreciation) internal pure returns (uint) {
        return
            (depreciation * SolidMath.TIME_APPRECIATION_BASIS_POINTS) /
            DEPRECIATION_BASIS_POINTS /
            100;
    }
}
