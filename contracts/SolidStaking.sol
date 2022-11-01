// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISolidStaking.sol";
import "./interfaces/rewards/IRewardsController.sol";

contract SolidStaking is ISolidStaking, ReentrancyGuard {
    /// @dev All stakable lp tokens.
    IERC20[] public tokens;

    /// @dev Mapping with added tokens.
    mapping(IERC20 => bool) public tokensAdded;

    /// @dev Mapping with the staked amount of each account for each token.
    /// @dev token => user => amount
    mapping(IERC20 => mapping(address => uint)) public userStake;

    /// @dev Rewards controller used for interacting with rewards mechanism.
    IRewardsController public immutable rewardsController;

    modifier validToken(IERC20 token) {
        require(tokensAdded[token], "SolidStaking: Invalid token address");
        _;
    }

    constructor(IRewardsController _rewardsController) {
        rewardsController = _rewardsController;
    }

    /// @inheritdoc ISolidStakingActions
    function stake(IERC20 token, uint amount) external override nonReentrant validToken(token) {
        uint oldUserStake = userStake[token][msg.sender];
        uint oldTotalStake = token.balanceOf(address(this));

        userStake[token][msg.sender] = oldUserStake + amount;
        token.transferFrom(msg.sender, address(this), amount);

        rewardsController.handleAction(msg.sender, oldUserStake, oldTotalStake);

        emit Stake(msg.sender, token, amount);
    }

    /// @inheritdoc ISolidStakingActions
    function withdraw(IERC20 token, uint amount) external override nonReentrant validToken(token) {
        uint oldUserStake = userStake[token][msg.sender];
        uint oldTotalStake = token.balanceOf(address(this));

        userStake[token][msg.sender] = oldUserStake - amount;
        token.transferFrom(address(this), msg.sender, amount);

        rewardsController.handleAction(msg.sender, oldUserStake, oldTotalStake);

        emit Withdraw(msg.sender, token, amount);
    }

    /// @inheritdoc ISolidStakingActions
    function balanceOf(IERC20 token, address account)
        external
        view
        override
        validToken(token)
        returns (uint)
    {
        return userStake[token][account];
    }

    /// @inheritdoc ISolidStakingActions
    function getTokens() external view override returns (IERC20[] memory _tokens) {
        _tokens = tokens;
    }

    /// @inheritdoc ISolidStakingOwnerActions
    function addToken(IERC20 token) external override {
        require(!tokensAdded[token], "SolidStaking: Token already added");

        tokens.push(token);
        tokensAdded[token] = true;

        emit TokenAdded(token);
    }
}
