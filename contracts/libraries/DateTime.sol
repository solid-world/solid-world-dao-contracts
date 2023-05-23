// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library DateTime {
    int public constant OFFSET_1970_01_01 = 2440588;
    uint public constant SECONDS_PER_DAY = 24 * 60 * 60;

    /// @dev Calculates the year from the number of days since 1970/01/01 using
    /// the date conversion algorithm from https://aa.usno.navy.mil/faq/JD_formula.html
    /// and adding the offset 2440588 so that 1970/01/01 is day 0.
    function getYear(uint timestamp) internal pure returns (uint year) {
        uint _days = timestamp / SECONDS_PER_DAY;
        int __days = int(_days);

        int L = __days + 68569 + OFFSET_1970_01_01;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        L = _month / 11;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
    }
}
