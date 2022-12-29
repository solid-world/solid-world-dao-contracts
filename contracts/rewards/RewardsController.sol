// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./RewardsDistributor.sol";
import "../interfaces/rewards/IRewardsController.sol";
import "../PostConstruct.sol";
import "../libraries/GPv2SafeERC20.sol";

contract RewardsController is IRewardsController, RewardsDistributor, PostConstruct {
    /// @dev user => claimer
    mapping(address => address) internal _authorizedClaimers;

    /// @dev reward => rewardOracle
    mapping(address => IEACAggregatorProxy) internal _rewardOracle;

    /// @dev Account that secures ERC20 rewards.
    /// @dev It must approve `RewardsController` to spend the rewards it holds.
    address internal REWARDS_VAULT;

    modifier onlyAuthorizedClaimers(address claimer, address user) {
        if (_authorizedClaimers[user] != claimer && address(solidStakingViewActions) != claimer) {
            revert UnauthorizedClaimer(claimer, user);
        }
        _;
    }

    function setup(
        address _solidStakingViewActions,
        address rewardsVault,
        address emissionManager
    ) external postConstruct {
        _setSolidStaking(_solidStakingViewActions);
        _setRewardsVault(rewardsVault);
        _setEmissionManager(emissionManager);
    }

    /// @inheritdoc IRewardsController
    function getRewardsVault() external view override returns (address) {
        return REWARDS_VAULT;
    }

    /// @inheritdoc IRewardsController
    function getClaimer(address user) external view override returns (address) {
        return _authorizedClaimers[user];
    }

    /// @inheritdoc IRewardsController
    function getRewardOracle(address reward) external view override returns (address) {
        return address(_rewardOracle[reward]);
    }

    /// @inheritdoc IRewardsController
    function configureAssets(RewardsDataTypes.DistributionConfig[] memory config)
        external
        override
        onlyEmissionManager
    {
        for (uint i; i < config.length; i++) {
            config[i].totalStaked = solidStakingViewActions.totalStaked(config[i].asset);
            _setRewardOracle(config[i].reward, config[i].rewardOracle);
        }
        _configureAssets(config);
    }

    /// @inheritdoc IRewardsController
    function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle)
        external
        onlyEmissionManager
    {
        _setRewardOracle(reward, rewardOracle);
    }

    /// @inheritdoc IRewardsController
    function setClaimer(address user, address caller) external override onlyEmissionManager {
        _authorizedClaimers[user] = caller;
        emit ClaimerSet(user, caller);
    }

    /// @inheritdoc IRewardsController
    function setRewardsVault(address rewardsVault) external override onlyEmissionManager {
        _setRewardsVault(rewardsVault);
    }

    function setSolidStaking(address solidStaking) external override onlyEmissionManager {
        _setSolidStaking(solidStaking);
    }

    /// @inheritdoc IRewardsController
    function handleUserStakeChanged(
        address asset,
        address user,
        uint oldUserStake,
        uint oldTotalStaked
    ) external override {
        if (msg.sender != address(solidStakingViewActions)) {
            revert NotSolidStaking(msg.sender);
        }

        _updateAllRewardDistributionsAndUserRewardsForAsset(
            asset,
            user,
            oldUserStake,
            oldTotalStaked
        );
    }

    /// @inheritdoc IRewardsController
    function claimAllRewards(address[] calldata assets, address to)
        external
        override
        returns (address[] memory rewardsList, uint[] memory claimedAmounts)
    {
        if (to == address(0)) {
            revert InvalidInput();
        }

        return _claimAllRewards(assets, msg.sender, msg.sender, to);
    }

    /// @inheritdoc IRewardsController
    function claimAllRewardsOnBehalf(
        address[] calldata assets,
        address user,
        address to
    )
        external
        override
        onlyAuthorizedClaimers(msg.sender, user)
        returns (address[] memory rewardsList, uint[] memory claimedAmounts)
    {
        if (to == address(0) || user == address(0)) {
            revert InvalidInput();
        }

        return _claimAllRewards(assets, msg.sender, user, to);
    }

    /// @inheritdoc IRewardsController
    function claimAllRewardsToSelf(address[] calldata assets)
        external
        override
        returns (address[] memory rewardsList, uint[] memory claimedAmounts)
    {
        return _claimAllRewards(assets, msg.sender, msg.sender, msg.sender);
    }

    /// @inheritdoc RewardsDistributor
    function _getAssetStakedAmounts(address[] calldata assets, address user)
        internal
        view
        override
        returns (RewardsDataTypes.AssetStakedAmounts[] memory assetStakedAmounts)
    {
        assetStakedAmounts = new RewardsDataTypes.AssetStakedAmounts[](assets.length);
        for (uint i; i < assets.length; i++) {
            assetStakedAmounts[i].asset = assets[i];
            assetStakedAmounts[i].userStake = solidStakingViewActions.balanceOf(assets[i], user);
            assetStakedAmounts[i].totalStaked = solidStakingViewActions.totalStaked(assets[i]);
        }
        return assetStakedAmounts;
    }

    /// @dev Claims all accrued rewards for a user on behalf, for the specified asset, accumulating the pending rewards.
    /// @param assets List of assets to check eligible distributions before claiming rewards
    /// @param claimer Address of the claimer on behalf of user
    /// @param user Address to check and claim rewards
    /// @param to Address that will be receiving the rewards
    /// @return
    ///   rewardsList List of reward addresses
    ///   claimedAmount List of claimed amounts, follows "rewardsList" items order
    function _claimAllRewards(
        address[] calldata assets,
        address claimer,
        address user,
        address to
    ) internal returns (address[] memory rewardsList, uint[] memory claimedAmounts) {
        uint rewardsListLength = _rewardsList.length;
        rewardsList = new address[](rewardsListLength);
        claimedAmounts = new uint[](rewardsListLength);

        _updateAllRewardDistributionsAndUserRewardsForAssets(
            user,
            _getAssetStakedAmounts(assets, user)
        );

        for (uint i; i < assets.length; i++) {
            address asset = assets[i];
            for (uint j; j < rewardsListLength; j++) {
                if (rewardsList[j] == address(0)) {
                    rewardsList[j] = _rewardsList[j];
                }
                uint rewardAmount = _assetData[asset]
                    .rewardDistribution[rewardsList[j]]
                    .userReward[user]
                    .accrued;
                if (rewardAmount != 0) {
                    claimedAmounts[j] += rewardAmount;
                    _assetData[asset]
                        .rewardDistribution[rewardsList[j]]
                        .userReward[user]
                        .accrued = 0;
                }
            }
        }
        for (uint i; i < rewardsListLength; i++) {
            _transferRewards(to, rewardsList[i], claimedAmounts[i]);
            emit RewardsClaimed(user, rewardsList[i], to, claimer, claimedAmounts[i]);
        }
        return (rewardsList, claimedAmounts);
    }

    /// @dev Function to transfer rewards to the desired account
    /// @param to Account address to send the rewards
    /// @param reward Address of the reward token
    /// @param amount Amount of rewards to transfer
    function _transferRewards(
        address to,
        address reward,
        uint amount
    ) internal {
        GPv2SafeERC20.safeTransferFrom(IERC20(reward), REWARDS_VAULT, to, amount);
    }

    /// @dev Update the Price Oracle of a reward token. The Price Oracle must follow Chainlink IEACAggregatorProxy interface.
    /// @notice The Price Oracle of a reward is used for displaying correct data about the incentives at the UI frontend.
    /// @param reward The address of the reward token
    /// @param rewardOracle The address of the price oracle
    function _setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) internal {
        if (rewardOracle.latestAnswer() <= 0) {
            revert InvalidRewardOracle(reward, address(rewardOracle));
        }

        _rewardOracle[reward] = rewardOracle;
        emit RewardOracleUpdated(reward, address(rewardOracle));
    }

    function _setRewardsVault(address rewardsVault) internal {
        REWARDS_VAULT = rewardsVault;
        emit RewardsVaultUpdated(rewardsVault);
    }

    function _setSolidStaking(address solidStaking) internal {
        solidStakingViewActions = ISolidStakingViewActions(solidStaking);
        emit SolidStakingUpdated(solidStaking);
    }
}
