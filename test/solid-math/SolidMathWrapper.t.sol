// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../contracts/libraries/SolidMath.sol";

/// @notice Dummy wrapper over some SolidMath functions, such that we can make external calls to them
/// @notice and use the try/catch syntax
contract SolidMathWrapper {
    function computeTimeAppreciationDiscount(uint timeAppreciation, uint certificationDate)
        external
        view
        returns (uint)
    {
        return SolidMath.computeTimeAppreciationDiscount(timeAppreciation, certificationDate);
    }

    function computeCollateralizationOutcome(
        uint certificationDate,
        uint fcbtAmount,
        uint timeAppreciation,
        uint collateralizationFee,
        uint cbtDecimals
    )
        external
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return
            SolidMath.computeCollateralizationOutcome(
                certificationDate,
                fcbtAmount,
                timeAppreciation,
                collateralizationFee,
                cbtDecimals
            );
    }

    function computeDecollateralizationOutcome(
        uint certificationDate,
        uint cbtAmount,
        uint timeAppreciation,
        uint decollateralizationFee,
        uint cbtDecimals
    )
        external
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return
            SolidMath.computeDecollateralizationOutcome(
                certificationDate,
                cbtAmount,
                timeAppreciation,
                decollateralizationFee,
                cbtDecimals
            );
    }

    function computeDecollateralizationMinAmountInAndDaoCut(
        uint certificationDate,
        uint expectedFcbtAmount,
        uint timeAppreciation,
        uint decollateralizationFee,
        uint cbtDecimals
    ) external view returns (uint minAmountIn, uint minCbtDaoCut) {
        return
            SolidMath.computeDecollateralizationMinAmountInAndDaoCut(
                certificationDate,
                expectedFcbtAmount,
                timeAppreciation,
                decollateralizationFee,
                cbtDecimals
            );
    }

    function computeWeeklyBatchReward(
        uint certificationDate,
        uint availableCredits,
        uint timeAppreciation,
        uint rewardsFee,
        uint decimals
    ) external view returns (uint netRewardAmount, uint feeAmount) {
        return
            SolidMath.computeWeeklyBatchReward(
                certificationDate,
                availableCredits,
                timeAppreciation,
                rewardsFee,
                decimals
            );
    }
}
