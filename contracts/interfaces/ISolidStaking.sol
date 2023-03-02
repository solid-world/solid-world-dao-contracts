// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./staking/ISolidStakingOwnerActions.sol";
import "./staking/ISolidStakingEvents.sol";
import "./staking/ISolidStakingActions.sol";
import "./staking/ISolidStakingViewActions.sol";
import "./staking/ISolidStakingErrors.sol";

/// @title The interface for the Solid World staking contract
/// @notice The staking contract facilitates (un)staking of ERC20 tokens
/// @author Solid World DAO
/// @dev The interface is broken up into smaller pieces
interface ISolidStaking is
    ISolidStakingActions,
    ISolidStakingEvents,
    ISolidStakingOwnerActions,
    ISolidStakingViewActions,
    ISolidStakingErrors
{

}
