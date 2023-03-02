// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Errors thrown by the staking contract
/// @author Solid World DAO
interface ISolidStakingErrors {
    error InvalidTokenAddress(address token);
    error TokenAlreadyAdded(address token);
}
