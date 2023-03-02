// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../contracts/libraries/ReactiveTimeAppreciationMath.sol";

/// @notice Dummy wrapper over some ReactiveTimeAppreciationMath functions, such that we can make external calls to them
/// @notice and use the try/catch syntax
contract ReactiveTimeAppreciationMathWrapper {
    function computeReactiveTA(DomainDataTypes.Category memory categoryState, uint forwardCreditsAmount)
        external
        view
        returns (uint decayingMomentum, uint reactiveTA)
    {
        return ReactiveTimeAppreciationMath.computeReactiveTA(categoryState, forwardCreditsAmount);
    }

    function inferBatchTA(
        uint circulatingCBT,
        uint totalCollateralizedForwardCredits,
        uint certificationDate,
        uint cbtDecimals
    ) external view returns (uint batchTA) {
        return
            ReactiveTimeAppreciationMath.inferBatchTA(
                circulatingCBT,
                totalCollateralizedForwardCredits,
                certificationDate,
                cbtDecimals
            );
    }
}
