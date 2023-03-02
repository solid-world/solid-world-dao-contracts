// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../test/BaseTest.sol";

abstract contract GasTest is BaseTest {
    string private checkpointLabel;
    uint private checkpointGasLeft = 1; // Start the slot warm.

    function startMeasuringGas(string memory label) internal virtual {
        checkpointLabel = label;

        checkpointGasLeft = gasleft();
    }

    function stopMeasuringGas() internal virtual {
        uint currentGasLeft = gasleft();

        // Subtract 100 to account for the warm SLOAD in startMeasuringGas.
        uint gasDelta = checkpointGasLeft - currentGasLeft - 100;

        emit log_named_uint(string(abi.encodePacked(checkpointLabel, " Gas")), gasDelta);
    }
}
