pragma solidity ^0.8.0;

import "./interfaces/ISolidStaking.sol";

contract SolidStaking is ISolidStaking {
    /// @inheritdoc ISolidStakingActions
    function stake(IERC20 token, uint amount) external {}

    /// @inheritdoc ISolidStakingActions
    function withdraw(IERC20 token, uint amount) external {}

    /// @inheritdoc ISolidStakingActions
    function balanceOf(IERC20 token, address account) external view returns (uint) {
        return 0;
    }

    /// @inheritdoc ISolidStakingActions
    function getTokens() external view returns (IERC20[] memory) {
        return new IERC20[](0);
    }

    /// @inheritdoc ISolidStakingOwnerActions
    function addToken(IERC20 token) external {}
}
