// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/rewards/IRewardsDistributor.sol";
import "../libraries/RewardsDataTypes.sol";
import "../interfaces/staking/ISolidStakingViewActions.sol";

abstract contract RewardsDistributor is IRewardsDistributor {
    using SafeCast for uint;

    // asset => AssetData
    mapping(address => RewardsDataTypes.AssetData) internal _assetData;
    // reward => enabled
    mapping(address => bool) internal _isRewardEnabled;

    address[] internal _rewardsList;
    address[] internal _assetsList;
    address internal _emissionManager;

    /// @dev Used to fetch the total amount staked and the stake of an user for a given asset
    ISolidStakingViewActions public solidStakingViewActions;

    modifier onlyEmissionManager() {
        if (msg.sender != _emissionManager) {
            revert NotEmissionManager(msg.sender);
        }
        _;
    }

    modifier distributionExists(address asset, address reward) {
        RewardsDataTypes.RewardDistribution storage rewardDistribution = _assetData[asset].rewardDistribution[
            reward
        ];
        uint decimals = _assetData[asset].decimals;
        if (decimals == 0 || rewardDistribution.lastUpdateTimestamp == 0) {
            revert DistributionNonExistent(asset, reward);
        }
        _;
    }

    /// @inheritdoc IRewardsDistributor
    function getRewardDistribution(address asset, address reward)
        public
        view
        returns (
            uint,
            uint,
            uint,
            uint
        )
    {
        return (
            _assetData[asset].rewardDistribution[reward].index,
            _assetData[asset].rewardDistribution[reward].emissionPerSecond,
            _assetData[asset].rewardDistribution[reward].lastUpdateTimestamp,
            _assetData[asset].rewardDistribution[reward].distributionEnd
        );
    }

    /// @inheritdoc IRewardsDistributor
    function getDistributionEnd(address asset, address reward) external view returns (uint) {
        return _assetData[asset].rewardDistribution[reward].distributionEnd;
    }

    /// @inheritdoc IRewardsDistributor
    function getRewardsByAsset(address asset) external view returns (address[] memory) {
        uint128 rewardsCount = _assetData[asset].availableRewardsCount;
        address[] memory rewards = new address[](rewardsCount);

        for (uint128 i; i < rewardsCount; i++) {
            rewards[i] = _assetData[asset].availableRewards[i];
        }
        return rewards;
    }

    /// @inheritdoc IRewardsDistributor
    function getAllRewards() external view returns (address[] memory) {
        return _rewardsList;
    }

    /// @inheritdoc IRewardsDistributor
    function getUserIndex(
        address user,
        address asset,
        address reward
    ) public view returns (uint) {
        return _assetData[asset].rewardDistribution[reward].userReward[user].index;
    }

    /// @inheritdoc IRewardsDistributor
    function getAccruedRewardAmountForUser(address user, address reward) external view returns (uint) {
        uint totalAccrued;
        for (uint i; i < _assetsList.length; i++) {
            totalAccrued += _assetData[_assetsList[i]].rewardDistribution[reward].userReward[user].accrued;
        }

        return totalAccrued;
    }

    /// @inheritdoc IRewardsDistributor
    function getUnclaimedRewardAmountForUserAndAssets(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint unclaimedAmount) {
        RewardsDataTypes.AssetStakedAmounts[] memory assetStakedAmounts = _getAssetStakedAmounts(
            assets,
            user
        );

        for (uint i; i < assetStakedAmounts.length; i++) {
            if (assetStakedAmounts[i].userStake == 0) {
                unclaimedAmount += _assetData[assetStakedAmounts[i].asset]
                    .rewardDistribution[reward]
                    .userReward[user]
                    .accrued;
            } else {
                unclaimedAmount +=
                    _computePendingRewardAmountForUser(user, reward, assetStakedAmounts[i]) +
                    _assetData[assetStakedAmounts[i].asset]
                        .rewardDistribution[reward]
                        .userReward[user]
                        .accrued;
            }
        }

        return unclaimedAmount;
    }

    /// @inheritdoc IRewardsDistributor
    function getAllUnclaimedRewardAmountsForUserAndAssets(address[] calldata assets, address user)
        external
        view
        returns (address[] memory rewardsList, uint[] memory unclaimedAmounts)
    {
        RewardsDataTypes.AssetStakedAmounts[] memory assetStakedAmounts = _getAssetStakedAmounts(
            assets,
            user
        );
        rewardsList = new address[](_rewardsList.length);
        unclaimedAmounts = new uint[](rewardsList.length);

        for (uint i; i < assetStakedAmounts.length; i++) {
            for (uint r; r < rewardsList.length; r++) {
                rewardsList[r] = _rewardsList[r];
                unclaimedAmounts[r] += _assetData[assetStakedAmounts[i].asset]
                    .rewardDistribution[rewardsList[r]]
                    .userReward[user]
                    .accrued;

                if (assetStakedAmounts[i].userStake == 0) {
                    continue;
                }
                unclaimedAmounts[r] += _computePendingRewardAmountForUser(
                    user,
                    rewardsList[r],
                    assetStakedAmounts[i]
                );
            }
        }
        return (rewardsList, unclaimedAmounts);
    }

    /// @inheritdoc IRewardsDistributor
    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external onlyEmissionManager distributionExists(asset, reward) {
        uint oldDistributionEnd = _setDistributionEnd(asset, reward, newDistributionEnd);
        uint index = _assetData[asset].rewardDistribution[reward].index;

        emit AssetConfigUpdated(
            asset,
            reward,
            _assetData[asset].rewardDistribution[reward].emissionPerSecond,
            _assetData[asset].rewardDistribution[reward].emissionPerSecond,
            oldDistributionEnd,
            newDistributionEnd,
            index
        );
    }

    /// @inheritdoc IRewardsDistributor
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external onlyEmissionManager {
        if (rewards.length != newEmissionsPerSecond.length) {
            revert InvalidInput();
        }

        for (uint i; i < rewards.length; i++) {
            (uint oldEmissionPerSecond, uint newIndex, uint distributionEnd) = _setEmissionPerSecond(
                asset,
                rewards[i],
                newEmissionsPerSecond[i]
            );

            emit AssetConfigUpdated(
                asset,
                rewards[i],
                oldEmissionPerSecond,
                newEmissionsPerSecond[i],
                distributionEnd,
                distributionEnd,
                newIndex
            );
        }
    }

    /// @inheritdoc IRewardsDistributor
    function updateCarbonRewardDistribution(
        address[] calldata assets,
        address[] calldata rewards,
        uint[] calldata rewardAmounts
    ) external onlyEmissionManager {
        if (assets.length != rewards.length || rewards.length != rewardAmounts.length) {
            revert InvalidInput();
        }

        for (uint i; i < assets.length; i++) {
            if (!_canUpdateCarbonRewardDistribution(assets[i], rewards[i])) {
                revert UpdateDistributionNotApplicable(assets[i], rewards[i]);
            }

            uint32 newDistributionEnd = _computeNewCarbonRewardDistributionEnd(assets[i], rewards[i]);
            uint88 newEmissionsPerSecond = uint88(rewardAmounts[i] / (newDistributionEnd - block.timestamp));

            (uint oldEmissionPerSecond, uint newIndex, ) = _setEmissionPerSecond(
                assets[i],
                rewards[i],
                newEmissionsPerSecond
            );
            uint oldDistributionEnd = _setDistributionEnd(assets[i], rewards[i], newDistributionEnd);
            emit AssetConfigUpdated(
                assets[i],
                rewards[i],
                oldEmissionPerSecond,
                newEmissionsPerSecond,
                oldDistributionEnd,
                newDistributionEnd,
                newIndex
            );
        }
    }

    /// @inheritdoc IRewardsDistributor
    function getAssetDecimals(address asset) external view returns (uint8) {
        return _assetData[asset].decimals;
    }

    /// @inheritdoc IRewardsDistributor
    function getEmissionManager() external view returns (address) {
        return _emissionManager;
    }

    /// @inheritdoc IRewardsDistributor
    function setEmissionManager(address emissionManager) external onlyEmissionManager {
        _setEmissionManager(emissionManager);
    }

    /// @inheritdoc IRewardsDistributor
    function canUpdateCarbonRewardDistribution(address asset, address reward)
        external
        view
        distributionExists(asset, reward)
        returns (bool)
    {
        return _canUpdateCarbonRewardDistribution(asset, reward);
    }

    function _canUpdateCarbonRewardDistribution(address asset, address reward) internal view returns (bool) {
        uint32 currentDistributionEnd = _assetData[asset].rewardDistribution[reward].distributionEnd;
        uint32 nextDistributionEnd = _computeNewCarbonRewardDistributionEnd(asset, reward);

        bool isInitializedDistribution = currentDistributionEnd != 0;
        bool isBetweenDistributions = block.timestamp >= currentDistributionEnd &&
            block.timestamp < nextDistributionEnd;

        return isInitializedDistribution && isBetweenDistributions;
    }

    function _computeNewCarbonRewardDistributionEnd(address asset, address reward)
        internal
        view
        returns (uint32 newDistributionEnd)
    {
        uint32 currentDistributionEnd = _assetData[asset].rewardDistribution[reward].distributionEnd;

        newDistributionEnd = currentDistributionEnd + 1 weeks;
    }

    /// @dev Configure the _assetData for a specific emission
    /// @param distributionConfig The array of each asset configuration
    function _configureAssets(RewardsDataTypes.DistributionConfig[] memory distributionConfig) internal {
        for (uint i; i < distributionConfig.length; i++) {
            uint8 decimals = IERC20Metadata(distributionConfig[i].asset).decimals();

            if (decimals == 0) {
                revert InvalidAssetDecimals(distributionConfig[i].asset);
            }

            if (_assetData[distributionConfig[i].asset].decimals == 0) {
                _assetsList.push(distributionConfig[i].asset);
            }

            _assetData[distributionConfig[i].asset].decimals = decimals;

            RewardsDataTypes.RewardDistribution storage rewardDistribution = _assetData[
                distributionConfig[i].asset
            ].rewardDistribution[distributionConfig[i].reward];

            if (rewardDistribution.lastUpdateTimestamp == 0) {
                uint128 rewardCount = _assetData[distributionConfig[i].asset].availableRewardsCount;
                _assetData[distributionConfig[i].asset].availableRewards[rewardCount] = distributionConfig[i]
                    .reward;
                _assetData[distributionConfig[i].asset].availableRewardsCount++;
            }

            if (_isRewardEnabled[distributionConfig[i].reward] == false) {
                _isRewardEnabled[distributionConfig[i].reward] = true;
                _rewardsList.push(distributionConfig[i].reward);
            }

            (uint newAssetIndex, ) = _updateRewardDistribution(
                rewardDistribution,
                distributionConfig[i].totalStaked,
                10**decimals
            );

            uint88 oldEmissionsPerSecond = rewardDistribution.emissionPerSecond;
            uint32 oldDistributionEnd = rewardDistribution.distributionEnd;
            rewardDistribution.emissionPerSecond = distributionConfig[i].emissionPerSecond;
            rewardDistribution.distributionEnd = distributionConfig[i].distributionEnd;

            emit AssetConfigUpdated(
                distributionConfig[i].asset,
                distributionConfig[i].reward,
                oldEmissionsPerSecond,
                distributionConfig[i].emissionPerSecond,
                oldDistributionEnd,
                distributionConfig[i].distributionEnd,
                newAssetIndex
            );
        }
    }

    /// @dev Updates rewards distribution and user rewards for all rewards configured for the specified assets
    /// @param user The address of the user
    /// @param assetStakedAmounts List of structs with the user stake and total staked of a set of assets
    function _updateAllRewardDistributionsAndUserRewardsForAssets(
        address user,
        RewardsDataTypes.AssetStakedAmounts[] memory assetStakedAmounts
    ) internal {
        for (uint i; i < assetStakedAmounts.length; i++) {
            _updateAllRewardDistributionsAndUserRewardsForAsset(
                assetStakedAmounts[i].asset,
                user,
                assetStakedAmounts[i].userStake,
                assetStakedAmounts[i].totalStaked
            );
        }
    }

    /// @dev Updates rewards distribution and user rewards for all rewards configured for the specified asset
    /// @dev When call origin is (un)staking, `userStake` and `totalStaked` are prior to the (un)stake action
    /// @dev When call origin is rewards claiming, `userStake` and `totalStaked` are current values
    /// @param asset The address of the incentivized asset
    /// @param user The user address
    /// @param userStake The amount of assets staked by the user
    /// @param totalStaked The total amount staked of the asset
    function _updateAllRewardDistributionsAndUserRewardsForAsset(
        address asset,
        address user,
        uint userStake,
        uint totalStaked
    ) internal {
        uint assetUnit;
        uint numAvailableRewards = _assetData[asset].availableRewardsCount;
        unchecked {
            assetUnit = 10**_assetData[asset].decimals;
        }

        if (numAvailableRewards == 0) {
            return;
        }
        unchecked {
            for (uint128 r; r < numAvailableRewards; r++) {
                address reward = _assetData[asset].availableRewards[r];
                RewardsDataTypes.RewardDistribution storage rewardDistribution = _assetData[asset]
                    .rewardDistribution[reward];

                (uint newAssetIndex, bool rewardDistributionUpdated) = _updateRewardDistribution(
                    rewardDistribution,
                    totalStaked,
                    assetUnit
                );

                (uint rewardsAccrued, bool userRewardUpdated) = _updateUserReward(
                    rewardDistribution,
                    user,
                    userStake,
                    newAssetIndex,
                    assetUnit
                );

                if (rewardDistributionUpdated || userRewardUpdated) {
                    emit Accrued(asset, reward, user, newAssetIndex, newAssetIndex, rewardsAccrued);
                }
            }
        }
    }

    /// @dev Updates the state of the distribution for the specified reward
    /// @param rewardDistribution Storage pointer to the distribution reward config
    /// @param totalStaked The total amount staked of the asset
    /// @param assetUnit One unit of asset (10**decimals)
    /// @return The new distribution index
    /// @return True if the index was updated, false otherwise
    function _updateRewardDistribution(
        RewardsDataTypes.RewardDistribution storage rewardDistribution,
        uint totalStaked,
        uint assetUnit
    ) internal returns (uint, bool) {
        (uint oldIndex, uint newIndex) = _computeNewAssetIndex(rewardDistribution, totalStaked, assetUnit);
        bool indexUpdated;
        if (newIndex != oldIndex) {
            if (newIndex > type(uint104).max) {
                revert IndexOverflow(newIndex);
            }

            indexUpdated = true;

            rewardDistribution.index = uint104(newIndex);
            rewardDistribution.lastUpdateTimestamp = block.timestamp.toUint32();
        } else {
            rewardDistribution.lastUpdateTimestamp = block.timestamp.toUint32();
        }

        return (newIndex, indexUpdated);
    }

    /// @dev Updates the state of the distribution for the specific user
    /// @param rewardDistribution Storage pointer to the distribution reward config
    /// @param user The address of the user
    /// @param userStake The amount of assets staked by the user
    /// @param newAssetIndex The new index of the asset distribution
    /// @param assetUnit One unit of asset (10**decimals)
    /// @return The rewards accrued since the last update
    function _updateUserReward(
        RewardsDataTypes.RewardDistribution storage rewardDistribution,
        address user,
        uint userStake,
        uint newAssetIndex,
        uint assetUnit
    ) internal returns (uint, bool) {
        uint userIndex = rewardDistribution.userReward[user].index;
        uint rewardsAccrued;
        bool dataUpdated;
        if ((dataUpdated = userIndex != newAssetIndex)) {
            if (newAssetIndex > type(uint104).max) {
                revert IndexOverflow(newAssetIndex);
            }

            rewardDistribution.userReward[user].index = uint104(newAssetIndex);
            if (userStake != 0) {
                rewardsAccrued = _computeAccruedRewardAmount(userStake, newAssetIndex, userIndex, assetUnit);

                rewardDistribution.userReward[user].accrued += rewardsAccrued.toUint128();
            }
        }
        return (rewardsAccrued, dataUpdated);
    }

    /// @dev Calculates the pending (not yet accrued) reward amount since the last user action
    /// @param user The address of the user
    /// @param reward The address of the reward token
    /// @param assetStakedAmounts struct with the user stake and total staked of the incentivized asset
    /// @return The pending rewards for the user since the last user action
    function _computePendingRewardAmountForUser(
        address user,
        address reward,
        RewardsDataTypes.AssetStakedAmounts memory assetStakedAmounts
    ) internal view returns (uint) {
        RewardsDataTypes.RewardDistribution storage rewardDistribution = _assetData[assetStakedAmounts.asset]
            .rewardDistribution[reward];
        uint assetUnit = 10**_assetData[assetStakedAmounts.asset].decimals;
        (, uint nextIndex) = _computeNewAssetIndex(
            rewardDistribution,
            assetStakedAmounts.totalStaked,
            assetUnit
        );

        return
            _computeAccruedRewardAmount(
                assetStakedAmounts.userStake,
                nextIndex,
                rewardDistribution.userReward[user].index,
                assetUnit
            );
    }

    /// @dev Internal function for the calculation of user's rewards on a distribution
    /// @param userStake The amount of assets staked by the user on a distribution
    /// @param assetIndex Current index of the asset reward distribution
    /// @param userIndex Index stored for the user, representing his staking moment
    /// @param assetUnit One unit of asset (10**decimals)
    /// @return accruedRewardAmount The accrued reward amount
    function _computeAccruedRewardAmount(
        uint userStake,
        uint assetIndex,
        uint userIndex,
        uint assetUnit
    ) internal pure returns (uint accruedRewardAmount) {
        accruedRewardAmount = userStake * (assetIndex - userIndex);

        assembly {
            accruedRewardAmount := div(accruedRewardAmount, assetUnit)
        }
    }

    /// @dev Calculates the next value of an specific distribution index, with validations
    /// @param totalStaked The total amount staked of the asset
    /// @param assetUnit One unit of asset (10**decimals)
    /// @return The new index.
    function _computeNewAssetIndex(
        RewardsDataTypes.RewardDistribution storage rewardDistribution,
        uint totalStaked,
        uint assetUnit
    ) internal view returns (uint, uint) {
        uint oldIndex = rewardDistribution.index;
        uint distributionEnd = rewardDistribution.distributionEnd;
        uint emissionPerSecond = rewardDistribution.emissionPerSecond;
        uint lastUpdateTimestamp = rewardDistribution.lastUpdateTimestamp;

        if (
            emissionPerSecond == 0 ||
            totalStaked == 0 ||
            lastUpdateTimestamp == block.timestamp ||
            lastUpdateTimestamp >= distributionEnd
        ) {
            return (oldIndex, oldIndex);
        }

        uint currentTimestamp = block.timestamp > distributionEnd ? distributionEnd : block.timestamp;
        uint timeDelta = currentTimestamp - lastUpdateTimestamp;
        uint firstTerm = emissionPerSecond * timeDelta * assetUnit;
        assembly {
            firstTerm := div(firstTerm, totalStaked)
        }
        return (oldIndex, (firstTerm + oldIndex));
    }

    /// @dev Get user stake and total staked of all the assets specified by the assets parameter
    /// @param assets List of assets to retrieve user stake and total staked
    /// @param user Address of the user
    /// @return assetStakedAmounts contains a list of structs with user stake and total staked of the given assets
    function _getAssetStakedAmounts(address[] calldata assets, address user)
        internal
        view
        virtual
        returns (RewardsDataTypes.AssetStakedAmounts[] memory assetStakedAmounts);

    /// @dev Updates the address of the emission manager
    /// @param emissionManager The address of the new EmissionManager
    function _setEmissionManager(address emissionManager) internal {
        address previousEmissionManager = _emissionManager;
        _emissionManager = emissionManager;
        emit EmissionManagerUpdated(previousEmissionManager, emissionManager);
    }

    function _setEmissionPerSecond(
        address asset,
        address reward,
        uint88 newEmissionsPerSecond
    )
        internal
        returns (
            uint oldEmissionPerSecond,
            uint newIndex,
            uint distributionEnd
        )
    {
        RewardsDataTypes.AssetData storage assetConfig = _assetData[asset];
        RewardsDataTypes.RewardDistribution storage rewardDistribution = _assetData[asset].rewardDistribution[
            reward
        ];
        uint decimals = assetConfig.decimals;
        if (decimals == 0 || rewardDistribution.lastUpdateTimestamp == 0) {
            revert DistributionNonExistent(asset, reward);
        }

        distributionEnd = rewardDistribution.distributionEnd;

        (newIndex, ) = _updateRewardDistribution(
            rewardDistribution,
            solidStakingViewActions.totalStaked(asset),
            10**decimals
        );

        oldEmissionPerSecond = rewardDistribution.emissionPerSecond;
        rewardDistribution.emissionPerSecond = newEmissionsPerSecond;
    }

    function _setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) internal returns (uint oldDistributionEnd) {
        oldDistributionEnd = _assetData[asset].rewardDistribution[reward].distributionEnd;
        _assetData[asset].rewardDistribution[reward].distributionEnd = newDistributionEnd;
    }
}
