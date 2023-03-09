// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/liquidity-deployer/IUniProxy.sol";

library LiquidityDeployerDataTypes {
    struct Config {
        IERC20 token0;
        IERC20 token1;
        address gammaVault;
        IUniProxy uniProxy;
        uint conversionRate;
        uint8 conversionRateDecimals;
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
