// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "./DomainDataTypes.sol";

library ReactiveTimeAppreciationMath {
    /// @dev Basis points in which the `decayPerSecond` must be expressed
    uint constant DECAY_BASIS_POINTS = 100_000_000_000;

    function computeReactiveTA(DomainDataTypes.Category memory categoryState, uint fcbtAmount)
        internal
        view
        returns (uint decayingMomentum, uint24 reactiveTA)
    {
        decayingMomentum = computeDecayingMomentum(
            categoryState.decayPerSecond,
            categoryState.lastCollateralizationMomentum,
            categoryState.lastCollateralizationTimestamp
        );
    }

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
}
