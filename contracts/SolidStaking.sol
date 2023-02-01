// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ISolidStaking.sol";
import "./interfaces/rewards/IRewardsController.sol";
import "./PostConstruct.sol";
import "./libraries/GPv2SafeERC20.sol";

contract SolidStaking is ISolidStaking, ReentrancyGuard, Ownable, PostConstruct {
    using GPv2SafeERC20 for IERC20;

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
        if (!tokenAdded[token]) {
            revert InvalidTokenAddress(token);
        }
        _;
    }

    function setup(IRewardsController _rewardsController, address owner) external postConstruct {
        rewardsController = _rewardsController;
        transferOwnership(owner);
    }

    /// @inheritdoc ISolidStakingOwnerActions
    function addToken(address token) external override onlyOwner {
        if (tokenAdded[token]) {
            revert TokenAlreadyAdded(token);
        }

        tokens.push(token);
        tokenAdded[token] = true;

        emit TokenAdded(token);
    }

    /// @inheritdoc ISolidStakingActions
    function stake(address token, uint amount) external override nonReentrant validToken(token) {
        uint oldUserStake = _balanceOf(token, msg.sender);
        uint oldTotalStake = _totalStaked(token);

        userStake[token][msg.sender] = oldUserStake + amount;

        rewardsController.handleUserStakeChanged(token, msg.sender, oldUserStake, oldTotalStake);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit Stake(msg.sender, token, amount);
    }

    /// @inheritdoc ISolidStakingActions
    function withdraw(address token, uint amount) external override nonReentrant validToken(token) {
        _withdraw(token, amount);
    }

    /// @inheritdoc ISolidStakingActions
    function withdrawStakeAndClaimRewards(address token, uint amount)
        external
        override
        nonReentrant
        validToken(token)
    {
        _withdraw(token, amount);
        _claimRewards(token);
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

    function _withdraw(address token, uint amount) internal {
        uint oldUserStake = _balanceOf(token, msg.sender);
        uint oldTotalStake = _totalStaked(token);

        userStake[token][msg.sender] = oldUserStake - amount;

        rewardsController.handleUserStakeChanged(token, msg.sender, oldUserStake, oldTotalStake);

        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, token, amount);
    }

    function _claimRewards(address token) internal {
        address[] memory assets = new address[](1);
        assets[0] = token;
        rewardsController.claimAllRewardsOnBehalf(assets, msg.sender, msg.sender);
    }
}
