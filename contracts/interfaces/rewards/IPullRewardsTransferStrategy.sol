// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ITransferStrategyBase.sol";

/**
 * @title IPullRewardsTransferStrategy
 * @author Aave
 **/
interface IPullRewardsTransferStrategy is ITransferStrategyBase {
    /**
     * @return Address of the rewards vault
     */
    function getRewardsVault() external view returns (address);
}
