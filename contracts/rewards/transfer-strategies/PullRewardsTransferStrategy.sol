// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/rewards/IPullRewardsTransferStrategy.sol";
import "./TransferStrategyBase.sol";

/**
 * @title PullRewardsTransferStrategy
 * @notice Transfer strategy that pulls ERC20 rewards from an external account to the user address.
 * The external account could be a smart contract or EOA that must approve to the PullRewardsTransferStrategy contract address.
 * @author Aave
 **/
contract PullRewardsTransferStrategy is TransferStrategyBase, IPullRewardsTransferStrategy {
    using GPv2SafeERC20 for IERC20;

    address internal immutable REWARDS_VAULT;

    constructor(
        address incentivesController,
        address rewardsAdmin,
        address rewardsVault
    ) TransferStrategyBase(incentivesController, rewardsAdmin) {
        REWARDS_VAULT = rewardsVault;
    }

    /// @inheritdoc TransferStrategyBase
    function performTransfer(
        address to,
        address reward,
        uint256 amount
    )
        external
        override(TransferStrategyBase, ITransferStrategyBase)
        onlyIncentivesController
        returns (bool)
    {
        IERC20(reward).safeTransferFrom(REWARDS_VAULT, to, amount);

        return true;
    }

    /// @inheritdoc IPullRewardsTransferStrategy
    function getRewardsVault() external view returns (address) {
        return REWARDS_VAULT;
    }
}
