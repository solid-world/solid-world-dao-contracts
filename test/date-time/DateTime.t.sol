// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseDateTime.t.sol";

contract DateTimeTest is BaseDateTime {
    function testGetYear_dateZero() public {
        uint year = DateTime.getYear(0);
        assertEq(year, 1970);
    }

    function testGetYear_concreteDates() public {
        uint[] memory timestamps = new uint[](7);
        uint[] memory expectedYears = new uint[](7);

        timestamps[0] = 1766620800; // 25-12-2025
        expectedYears[0] = 2025;

        timestamps[1] = 1798675200; // 31-12-2026
        expectedYears[1] = 2026;

        timestamps[2] = 1830124800; // 30-12-2027
        expectedYears[2] = 2027;

        timestamps[3] = 1861574400; // 28-12-2028
        expectedYears[3] = 2028;

        timestamps[4] = 1609459200; // 01-01-2021
        expectedYears[4] = 2021;

        timestamps[5] = 1798761599; // 31-12-2026 23:59:59
        expectedYears[5] = 2026;

        timestamps[6] = 1798761600; // 01-01-2027 00:00:00
        expectedYears[6] = 2027;

        for (uint i; i < timestamps.length; i++) {
            uint timestamp = timestamps[i];
            uint expectedYear = expectedYears[i];
            uint year = DateTime.getYear(timestamp);
            assertEq(year, expectedYear);
        }
    }
}
