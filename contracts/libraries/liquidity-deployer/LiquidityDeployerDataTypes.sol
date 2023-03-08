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

    struct TotalDeposits {
        uint token0Amount;
        uint token1Amount;
    }

    struct Depositors {
        address[] token0Depositors;
        address[] token1Depositors;
        mapping(address => bool) isToken0Depositor;
        mapping(address => bool) isToken1Depositor;
    }

    struct DeployedLiquidity {
        // Account => token0Amount
        mapping(address => uint) token0;
        // Account => token1Amount
        mapping(address => uint) token1;
    }

    /// @dev used to adjust deployable liquidity to maintain proportionality
    struct AdjustmentFactor {
        uint numerator;
        uint denominator;
    }
}
