// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Permissioned staking actions
/// @notice Contains staking methods may only be called by the owner
/// @author Solid World DAO
interface ISolidStakingOwnerActions {
    /// @dev Adds a new token to the staking contract
    /// @param token the token to add
    function addToken(address token) external;

    /// @param token to set KYC requirement for
    /// @param kycRequired whether the specified token requires msg.sender to be KYCed before staking
    function setKYCRequired(address token, bool kycRequired) external;
}
