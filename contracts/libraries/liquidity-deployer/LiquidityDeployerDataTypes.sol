// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library LiquidityDeployerDataTypes {
    struct Config {
        address token0;
        address token1;
        address gammaVault;
        address uniProxy;
        /// @dev 1 token0 = ? token1
        uint conversionRate;
        uint minConvertibleToken0Amount;
        uint8 conversionRateDecimals;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    struct Depositors {
        address[] tokenDepositors;
        /// @dev Depositor => IsDepositor
        mapping(address => bool) isDepositor;
    }

    /// @dev used to adjust deployable liquidity to maintain proportionality
    struct Fraction {
        uint numerator;
        uint denominator;
    }
}
