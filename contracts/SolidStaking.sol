// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ISolidStaking.sol";
import "./interfaces/rewards/IRewardsController.sol";
import "./PostConstruct.sol";

contract SolidStaking is ISolidStaking, ReentrancyGuard, Ownable, PostConstruct {
    /// @dev All stakable lp tokens.
    address[] public tokens;

    /// @dev Mapping with added tokens.
    mapping(address => bool) public tokenAdded;

    /// @dev Mapping with the staked amount of each account for each token.
    /// @dev token => user => amount
    mapping(address => mapping(address => uint)) public userStake;

    /// @dev Main contract used for interacting with rewards mechanism.
    IRewardsController public rewardsController;

    modifier validToken(address token) {
        require(tokenAdded[token], "SolidStaking: Invalid token address");
        _;
    }

    function setup(IRewardsController _rewardsController, address owner) external postConstruct {
        rewardsController = _rewardsController;
        transferOwnership(owner);
    }

    /// @inheritdoc ISolidStakingOwnerActions
    function addToken(address token) external override onlyOwner {
        require(!tokenAdded[token], "SolidStaking: Token already added");

        tokens.push(token);
        tokenAdded[token] = true;

        emit TokenAdded(token);
    }

    /// @inheritdoc ISolidStakingActions
    function stake(address token, uint amount) external override nonReentrant validToken(token) {
        uint oldUserStake = _balanceOf(token, msg.sender);
        uint oldTotalStake = _totalStaked(token);

        userStake[token][msg.sender] = oldUserStake + amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        rewardsController.handleAction(token, msg.sender, oldUserStake, oldTotalStake);

        emit Stake(msg.sender, token, amount);
    }

    /// @inheritdoc ISolidStakingActions
    function withdraw(address token, uint amount) external override nonReentrant validToken(token) {
        uint oldUserStake = _balanceOf(token, msg.sender);
        uint oldTotalStake = _totalStaked(token);

        userStake[token][msg.sender] = oldUserStake - amount;
        IERC20(token).transfer(msg.sender, amount);

        rewardsController.handleAction(token, msg.sender, oldUserStake, oldTotalStake);

        emit Withdraw(msg.sender, token, amount);
    }

    /// @inheritdoc ISolidStakingViewActions
    function balanceOf(address token, address account)
        external
        view
        override
        validToken(token)
        returns (uint)
    {
        return _balanceOf(token, account);
    }

    /// @inheritdoc ISolidStakingViewActions
    function totalStaked(address token) external view override validToken(token) returns (uint) {
        return _totalStaked(token);
    }

    /// @inheritdoc ISolidStakingViewActions
    function getTokens() external view override returns (address[] memory _tokens) {
        _tokens = tokens;
    }

    function _balanceOf(address token, address account) internal view returns (uint) {
        return userStake[token][account];
    }

    function _totalStaked(address token) internal view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }
}
