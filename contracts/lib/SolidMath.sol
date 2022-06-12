// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

/**
 * @dev Solid DAO Math Operations and Constants.
 */
library SolidMath {

    uint256 constant public WEEKS_IN_SECONDS = 604800;

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
        if ((_contractExpectedDueDate - _initialDate ) < WEEKS_IN_SECONDS) {
            return (true, 1);
        }
        uint256 numberOfWeeks = (_contractExpectedDueDate - _initialDate ) / WEEKS_IN_SECONDS;
        return (true, numberOfWeeks);
    }

}