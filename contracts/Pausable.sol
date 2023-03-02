// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World DAO
/// @dev Base contract which allows children to implement an emergency stop mechanism.
abstract contract Pausable {
    event Pause();
    event Unpause();

    error NotPaused();
    error Paused();

    bool public paused;

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        if (paused) {
            revert Paused();
        }
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        if (!paused) {
            revert NotPaused();
        }
        _;
    }

    /// @dev triggers stopped state
    function pause() public virtual whenNotPaused {
        paused = true;
        emit Pause();
    }

    /// @dev returns to normal state
    function unpause() public virtual whenPaused {
        paused = false;
        emit Unpause();
    }
}
