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

    function factorial(uint256 _num) pure public returns (uint256) {
        if (_num ==0 || _num==1) {
            return 1;
        } 
        return _num*factorial(_num-1);
    }

    function productReverse(uint256 _num) pure public returns (uint256[] memory) {
        uint256 prod = 1;
        uint8 numOfElementInSeries = 10; 
        uint256[] memory reverse = new uint256[](numOfElementInSeries);
        reverse[0] = 1;
        
        for (uint256 i = _num; i>0; i--) {           
            prod = prod * i;
            reverse[_num-(i-1)] = prod;
        }

        if (_num < numOfElementInSeries) {
            for (uint256 i = numOfElementInSeries-1; i >_num; i--) {
                reverse[i] = 0;
            }
        }

        return reverse;
    }

    function factorialReverse(uint256 _num) pure public returns (uint256[] memory) {
        uint256[] memory reverse = new uint256[](_num+1);
        for (uint256 i=0; i<=_num; i++) {
            reverse[i] = factorial(_num)/factorial(i);
        }
        return reverse;
    }

    function calcDigits(uint256 _numerator, uint256 _denominator) pure public returns (uint256 digits, uint256 exponent) {
        uint256 a = _numerator;
        uint256 b = _denominator;
        uint256 decimals = 8;
        for (uint256 i=0; i<(decimals*2); i++) {
            uint256 tmp = a/b;
            if (tmp == 0) {
                a = 10*a;
            } else {
                digits = 10*digits + (a/b);
                a = a-tmp*b;
                exponent++;
            }
        }
        return (digits, exponent-1);
    }

    function preCalc(uint256 _rate, uint256 _rateExponent) pure public returns (uint256, uint256) {
        uint8 numOfElementInSeries = 10;
        int256 sum = 0;
        uint256[] memory prodReverse = productReverse(1);
        uint256[] memory fatReverse = factorialReverse(numOfElementInSeries);
        for (uint256 i=0; i<numOfElementInSeries; i++) {
            sum = sum + ((-1)**i) * int256(prodReverse[i] * fatReverse[i] * 10**(_rateExponent*(numOfElementInSeries-i)) * (_rate**i));
        }
        return (uint256(sum), factorial(numOfElementInSeries)*10**(_rateExponent*numOfElementInSeries));
    }


    function calcBasicValuePerPeriod(uint256 _totalToken, uint256 _preCalcSum, uint256 _preCalcDenominator) pure public returns (uint256, uint256) {        
        (uint256 amountToProject, uint256 decimals) = calcDigits(_preCalcSum*_totalToken, _preCalcDenominator);
        return (amountToProject, decimals);
    }

    function severalWeeksSimulator(uint256 _numWeeks, uint256 _rate, uint256 _rateExponent, uint256 _totalToken, uint256 _daoFee) pure public returns (uint256 toProjectOwner, uint256 toDAO) {
        (uint256 sum, uint256 denominator) = preCalc(_rate, _rateExponent);
        toProjectOwner = _totalToken;
        for (uint8 i = 0; i < _numWeeks; i++) {
            (uint256 tmp, uint256 decimals) = calcBasicValuePerPeriod(toProjectOwner, sum, denominator);
            toProjectOwner = tmp / 10**decimals;
        }  
        uint256 result = toProjectOwner;
        toProjectOwner = (result * (100-_daoFee))/100;      
        toDAO = (result*_daoFee)/100;
        return (toProjectOwner, toDAO);
    }

    function weekSimulator(uint256 _rate, uint256 _rateExponent, uint256 _totalToken, uint256 _daoFee) pure public returns (uint256 toProjectOwner, uint256 toDAO) {        
        (uint256 sum, uint256 denominator) = preCalc(_rate, _rateExponent);
        (uint256 tmp, uint256 decimals) = calcBasicValuePerPeriod(_totalToken, sum, denominator);
        tmp = tmp / 10**decimals;
        toProjectOwner = (tmp * (100-_daoFee))/100;
        toDAO = (tmp*_daoFee)/100;
        return (toProjectOwner, toDAO);
    }
}