// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ISolidStaking.sol";
import "./interfaces/rewards/IRewardsController.sol";
import "./PostConstruct.sol";
import "./libraries/GPv2SafeERC20.sol";
import "./compliance/RegulatoryCompliant.sol";

/// @author Solid World
contract SolidStaking is ISolidStaking, ReentrancyGuard, Ownable, PostConstruct, RegulatoryCompliant {
    using GPv2SafeERC20 for IERC20;

    /// @dev All stakable lp tokens.
    address[] public tokens;

    mapping(address => bool) public tokenAdded;

    /// @dev Mapping with the staked amount of each account for each token.
    /// @dev token => user => amount
    mapping(address => mapping(address => uint)) public userStake;

    /// @dev token => requires KYC
    mapping(address => bool) private kycRequired;

    /// @dev Main contract used for interacting with rewards mechanism.
    IRewardsController public rewardsController;

    /// @dev Address controlling timelocked functions (e.g. KYC requirement changes)
    address internal immutable timelockController;

    modifier onlyTimelockController() {
        if (msg.sender != timelockController) {
            revert NotTimelockController(msg.sender);
        }
        _;
    }

    modifier validToken(address token) {
        if (!tokenAdded[token]) {
            revert InvalidTokenAddress(token);
        }
        _;
    }

    modifier regulatoryCompliant(address token, address subject) {
        if (!isValidCounterparty(subject, kycRequired[token])) {
            revert NotRegulatoryCompliant(token, subject);
        }
        _;
    }

    modifier notBlacklisted(address subject) {
        if (!isValidCounterparty(subject, false)) {
            revert Blacklisted(subject);
        }
        _;
    }

    constructor(address _verificationRegistry, address _timelockController)
        RegulatoryCompliant(_verificationRegistry)
    {
        timelockController = _timelockController;
    }

    function setup(IRewardsController _rewardsController, address owner) external postConstruct {
        rewardsController = _rewardsController;
        transferOwnership(owner);
    }

    /// @inheritdoc ISolidStakingOwnerActions
    function addToken(address token) external onlyOwner {
        if (tokenAdded[token]) {
            revert TokenAlreadyAdded(token);
        }

        tokens.push(token);
        tokenAdded[token] = true;

        emit TokenAdded(token);
    }

    /// @inheritdoc ISolidStakingOwnerActions
    function setKYCRequired(address token, bool _kycRequired) external onlyTimelockController {
        kycRequired[token] = _kycRequired;

        emit KYCRequiredSet(token, _kycRequired);
    }

    function setVerificationRegistry(address _verificationRegistry) public override onlyOwner {
        super.setVerificationRegistry(_verificationRegistry);
    }

    /// @inheritdoc ISolidStakingActions
    function stake(address token, uint amount)
        external
        nonReentrant
        validToken(token)
        regulatoryCompliant(token, msg.sender)
    {
        _stake(token, amount, msg.sender);
    }

    /// @inheritdoc ISolidStakingActions
    function stake(
        address token,
        uint amount,
        address recipient
    )
        external
        nonReentrant
        validToken(token)
        notBlacklisted(msg.sender)
        regulatoryCompliant(token, recipient)
    {
        _stake(token, amount, recipient);
    }

    /// @inheritdoc ISolidStakingActions
    function withdraw(address token, uint amount) external nonReentrant validToken(token) {
        _withdraw(token, amount);
    }

    /// @inheritdoc ISolidStakingActions
    function withdrawStakeAndClaimRewards(address token, uint amount)
        external
        nonReentrant
        validToken(token)
        regulatoryCompliant(token, msg.sender)
    {
        _withdraw(token, amount);
        _claimRewards(token);
    }

    /// @inheritdoc ISolidStakingViewActions
    function getTimelockController() external view returns (address) {
        return timelockController;
    }

    /// @inheritdoc ISolidStakingViewActions
    function balanceOf(address token, address account) external view validToken(token) returns (uint) {
        return _balanceOf(token, account);
    }

    /// @inheritdoc ISolidStakingViewActions
    function totalStaked(address token) external view validToken(token) returns (uint) {
        return _totalStaked(token);
    }

    /// @inheritdoc ISolidStakingViewActions
    function getTokens() external view returns (address[] memory _tokens) {
        _tokens = tokens;
    }

    /// @inheritdoc ISolidStakingViewActions
    function isKYCRequired(address token) external view returns (bool) {
        return kycRequired[token];
    }

    function _balanceOf(address token, address account) internal view returns (uint) {
        return userStake[token][account];
    }

    function _totalStaked(address token) internal view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function _stake(
        address token,
        uint amount,
        address recipient
    ) internal {
        uint oldUserStake = _balanceOf(token, recipient);
        uint oldTotalStake = _totalStaked(token);

        userStake[token][recipient] = oldUserStake + amount;

        rewardsController.handleUserStakeChanged(token, recipient, oldUserStake, oldTotalStake);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit Stake(recipient, token, amount);
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
