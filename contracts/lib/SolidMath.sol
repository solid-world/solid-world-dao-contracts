// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

/**
 * @dev Solid DAO Math Operations and Constants.
 */
abstract contract SolidMath {

    uint256 constant public WEEKS_IN_SECONDS = 604800;

    /**
    @notice BASIS define in which basis value the interest rate per week must be informed
    */
    uint256 constant BASIS = 1000000;

    /**
     * @dev Calculates the number of weeks between a period
     * @param _initialDate uint256 initial date to be informed in seconds
     * @param _contractExpectedDueDate uint256 the carbon credit contract expected due date to be informed in seconds
     */
    function weeksInThePeriod(uint256 _initialDate, uint256 _contractExpectedDueDate) public pure returns(bool, uint256) {
        if (_contractExpectedDueDate < WEEKS_IN_SECONDS) {
            return (false, 0);
        }
        if (_initialDate < WEEKS_IN_SECONDS) {
            return (false, 0);
        }
        if (_contractExpectedDueDate < _initialDate) {
            return (false, 0);
        }
        uint256 numberOfWeeks = (_contractExpectedDueDate - _initialDate ) / WEEKS_IN_SECONDS;
        uint256 remainder = (_contractExpectedDueDate - _initialDate ) % WEEKS_IN_SECONDS;
        if (remainder >= 5) {
            numberOfWeeks++;
        }
        return (true, numberOfWeeks);
    }

    /**
     * @param _numWeeks uint256
     * @param _rate uint256 1% = 10000, 0.0984% = 984
     */
    function calcBasicValue(uint256 _numWeeks, uint256 _rate) pure public returns (uint256) {
        uint256 invertDiscountRate = BASIS - _rate;
        uint256 basicValue = invertDiscountRate;
        for (uint16 i=1; i < _numWeeks; ) {
            basicValue = (basicValue * invertDiscountRate) / BASIS;
            unchecked { i++; }
        }
        return basicValue;
    }

    /**
     * @param _numWeeks uint256
     * @param _totalToken uint256
     * @param _rate uint256 1% = 10000, 0.0984% = 984
     * @param _daoFee uint256 1% = 1
     * @param _ctDecimals uint8
     */
    function payout(
        uint256 _numWeeks,
        uint256 _totalToken,
        uint256 _rate,
        uint256 _daoFee,
        uint8 _ctDecimals
    ) pure public returns (uint256, uint256, uint256) {
        uint256 basicValue = calcBasicValue(_numWeeks, _rate);
        uint256 coefficient = BASIS * 100;
        uint256 totalBasicValue = _totalToken * basicValue * 10 ** _ctDecimals;
        uint256 userResult = (totalBasicValue * (100-_daoFee)) / coefficient;
        uint256 daoResult = (totalBasicValue * _daoFee) / coefficient;
        return (basicValue, userResult, daoResult);
    }
}
