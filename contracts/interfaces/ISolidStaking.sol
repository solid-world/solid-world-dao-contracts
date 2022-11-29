// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./solid-staking/ISolidStakingOwnerActions.sol";
import "./solid-staking/ISolidStakingEvents.sol";
import "./solid-staking/ISolidStakingActions.sol";
import "./solid-staking/ISolidStakingViewActions.sol";
import "./solid-staking/ISolidStakingErrors.sol";

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
