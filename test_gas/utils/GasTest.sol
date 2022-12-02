pragma solidity ^0.8.0;

import "forge-std/Test.sol";

abstract contract GasTest is Test {
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

    function uintToString(uint v) internal pure returns (string memory str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }
}
