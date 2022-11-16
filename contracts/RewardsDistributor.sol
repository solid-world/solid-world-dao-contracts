// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/rewards/IRewardsDistributor.sol";
import "./libraries/RewardsDataTypes.sol";
import "./interfaces/solid-staking/ISolidStakingViewActions.sol";

abstract contract RewardsDistributor is IRewardsDistributor {
    using SafeCast for uint;

    // manager of incentives
    address internal _emissionManager;

    // asset => AssetData
    mapping(address => RewardsDataTypes.AssetData) internal _assets;

    // reward => enabled
    mapping(address => bool) internal _isRewardEnabled;

    // global rewards list
    address[] internal _rewardsList;

    //global assets list
    address[] internal _assetsList;

    /// @dev Used to fetch the total amount staked and the stake of an user for a given asset
    ISolidStakingViewActions public solidStakingViewActions;

    modifier onlyEmissionManager() {
        require(msg.sender == _emissionManager, "ONLY_EMISSION_MANAGER");
        _;
    }

    /// @inheritdoc IRewardsDistributor
    function getRewardsData(address asset, address reward)
        public
        view
        override
        returns (
            uint,
            uint,
            uint,
            uint
        )
    {
        return (
            _assets[asset].rewards[reward].index,
            _assets[asset].rewards[reward].emissionPerSecond,
            _assets[asset].rewards[reward].lastUpdateTimestamp,
            _assets[asset].rewards[reward].distributionEnd
        );
    }

    /// @inheritdoc IRewardsDistributor
    function getDistributionEnd(address asset, address reward)
        external
        view
        override
        returns (uint)
    {
        return _assets[asset].rewards[reward].distributionEnd;
    }

    /// @inheritdoc IRewardsDistributor
    function getRewardsByAsset(address asset) external view override returns (address[] memory) {
        uint128 rewardsCount = _assets[asset].availableRewardsCount;
        address[] memory availableRewards = new address[](rewardsCount);

        for (uint128 i; i < rewardsCount; i++) {
            availableRewards[i] = _assets[asset].availableRewards[i];
        }
        return availableRewards;
    }

    /// @inheritdoc IRewardsDistributor
    function getRewardsList() external view override returns (address[] memory) {
        return _rewardsList;
    }

    /// @inheritdoc IRewardsDistributor
    function getUserAssetIndex(
        address user,
        address asset,
        address reward
    ) public view override returns (uint) {
        return _assets[asset].rewards[reward].usersData[user].index;
    }

    /// @inheritdoc IRewardsDistributor
    function getUserAccruedRewards(address user, address reward)
        external
        view
        override
        returns (uint)
    {
        uint totalAccrued;
        for (uint i; i < _assetsList.length; i++) {
            totalAccrued += _assets[_assetsList[i]].rewards[reward].usersData[user].accrued;
        }

        return totalAccrued;
    }

    /// @inheritdoc IRewardsDistributor
    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view override returns (uint) {
        return _getUserReward(user, reward, _getUserAssetBalances(assets, user));
    }

    /// @inheritdoc IRewardsDistributor
    function getAllUserRewards(address[] calldata assets, address user)
        external
        view
        override
        returns (address[] memory rewardsList, uint[] memory unclaimedAmounts)
    {
        RewardsDataTypes.UserAssetBalance[] memory userAssetBalances = _getUserAssetBalances(
            assets,
            user
        );
        rewardsList = new address[](_rewardsList.length);
        unclaimedAmounts = new uint[](rewardsList.length);

        // Add unrealized rewards from user to unclaimedRewards
        for (uint i; i < userAssetBalances.length; i++) {
            for (uint r; r < rewardsList.length; r++) {
                rewardsList[r] = _rewardsList[r];
                unclaimedAmounts[r] += _assets[userAssetBalances[i].asset]
                    .rewards[rewardsList[r]]
                    .usersData[user]
                    .accrued;

                if (userAssetBalances[i].userStake == 0) {
                    continue;
                }
                unclaimedAmounts[r] += _getPendingRewards(
                    user,
                    rewardsList[r],
                    userAssetBalances[i]
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
    ) external override onlyEmissionManager {
        uint oldDistributionEnd = _assets[asset].rewards[reward].distributionEnd;
        _assets[asset].rewards[reward].distributionEnd = newDistributionEnd;

        emit AssetConfigUpdated(
            asset,
            reward,
            _assets[asset].rewards[reward].emissionPerSecond,
            _assets[asset].rewards[reward].emissionPerSecond,
            oldDistributionEnd,
            newDistributionEnd,
            _assets[asset].rewards[reward].index
        );
    }

    /// @inheritdoc IRewardsDistributor
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external override onlyEmissionManager {
        require(rewards.length == newEmissionsPerSecond.length, "INVALID_INPUT");
        for (uint i; i < rewards.length; i++) {
            RewardsDataTypes.AssetData storage assetConfig = _assets[asset];
            RewardsDataTypes.RewardData storage rewardConfig = _assets[asset].rewards[rewards[i]];
            uint decimals = assetConfig.decimals;
            require(
                decimals != 0 && rewardConfig.lastUpdateTimestamp != 0,
                "DISTRIBUTION_DOES_NOT_EXIST"
            );

            (uint newIndex, ) = _updateRewardData(
                rewardConfig,
                solidStakingViewActions.totalStaked(asset),
                10**decimals
            );

            uint oldEmissionPerSecond = rewardConfig.emissionPerSecond;
            rewardConfig.emissionPerSecond = newEmissionsPerSecond[i];

            emit AssetConfigUpdated(
                asset,
                rewards[i],
                oldEmissionPerSecond,
                newEmissionsPerSecond[i],
                rewardConfig.distributionEnd,
                rewardConfig.distributionEnd,
                newIndex
            );
        }
    }

    /// @inheritdoc IRewardsDistributor
    function getAssetDecimals(address asset) external view returns (uint8) {
        return _assets[asset].decimals;
    }

    /// @inheritdoc IRewardsDistributor
    function getEmissionManager() external view returns (address) {
        return _emissionManager;
    }

    /// @inheritdoc IRewardsDistributor
    function setEmissionManager(address emissionManager) external onlyEmissionManager {
        _setEmissionManager(emissionManager);
    }

    /**
     * @dev Configure the _assets for a specific emission
     * @param rewardsInput The array of each asset configuration
     **/
    function _configureAssets(RewardsDataTypes.RewardsConfigInput[] memory rewardsInput) internal {
        for (uint i; i < rewardsInput.length; i++) {
            if (_assets[rewardsInput[i].asset].decimals == 0) {
                //never initialized before, adding to the list of assets
                _assetsList.push(rewardsInput[i].asset);
            }

            uint decimals = _assets[rewardsInput[i].asset].decimals = IERC20Metadata(
                rewardsInput[i].asset
            ).decimals();

            RewardsDataTypes.RewardData storage rewardConfig = _assets[rewardsInput[i].asset]
                .rewards[rewardsInput[i].reward];

            // Add reward address to asset available rewards if latestUpdateTimestamp is zero
            if (rewardConfig.lastUpdateTimestamp == 0) {
                _assets[rewardsInput[i].asset].availableRewards[
                    _assets[rewardsInput[i].asset].availableRewardsCount
                ] = rewardsInput[i].reward;
                _assets[rewardsInput[i].asset].availableRewardsCount++;
            }

            // Add reward address to global rewards list if still not enabled
            if (_isRewardEnabled[rewardsInput[i].reward] == false) {
                _isRewardEnabled[rewardsInput[i].reward] = true;
                _rewardsList.push(rewardsInput[i].reward);
            }

            // Due emissions is still zero, updates only latestUpdateTimestamp
            (uint newIndex, ) = _updateRewardData(
                rewardConfig,
                rewardsInput[i].totalStaked,
                10**decimals
            );

            // Configure emission and distribution end of the reward per asset
            uint88 oldEmissionsPerSecond = rewardConfig.emissionPerSecond;
            uint32 oldDistributionEnd = rewardConfig.distributionEnd;
            rewardConfig.emissionPerSecond = rewardsInput[i].emissionPerSecond;
            rewardConfig.distributionEnd = rewardsInput[i].distributionEnd;

            emit AssetConfigUpdated(
                rewardsInput[i].asset,
                rewardsInput[i].reward,
                oldEmissionsPerSecond,
                rewardsInput[i].emissionPerSecond,
                oldDistributionEnd,
                rewardsInput[i].distributionEnd,
                newIndex
            );
        }
    }

    /**
     * @dev Accrues all the rewards of the assets specified in the userAssetBalances list
     * @param user The address of the user
     * @param userAssetBalances List of structs with the user balance and total supply of a set of assets
     **/
    function _updateDataMultiple(
        address user,
        RewardsDataTypes.UserAssetBalance[] memory userAssetBalances
    ) internal {
        for (uint i; i < userAssetBalances.length; i++) {
            _updateData(
                userAssetBalances[i].asset,
                user,
                userAssetBalances[i].userStake,
                userAssetBalances[i].totalStaked
            );
        }
    }

    /**
     * @dev Iterates and accrues all the rewards for asset of the specific user
     * @dev When call origin is (un)staking, `userStake` and `totalStaked` are prior to the (un)stake action
     * @dev When call origin is rewards claiming, `userStake` and `totalStaked` are current values
     * @param asset The address of the reference asset of the distribution
     * @param user The user address
     * @param userStake The amount of assets staked by the user
     * @param totalStaked The total amount staked of the asset
     **/
    function _updateData(
        address asset,
        address user,
        uint userStake,
        uint totalStaked
    ) internal {
        uint assetUnit;
        uint numAvailableRewards = _assets[asset].availableRewardsCount;
        unchecked {
            assetUnit = 10**_assets[asset].decimals;
        }

        if (numAvailableRewards == 0) {
            return;
        }
        unchecked {
            for (uint128 r; r < numAvailableRewards; r++) {
                address reward = _assets[asset].availableRewards[r];
                RewardsDataTypes.RewardData storage rewardData = _assets[asset].rewards[reward];

                (uint newAssetIndex, bool rewardDataUpdated) = _updateRewardData(
                    rewardData,
                    totalStaked,
                    assetUnit
                );

                (uint rewardsAccrued, bool userDataUpdated) = _updateUserData(
                    rewardData,
                    user,
                    userStake,
                    newAssetIndex,
                    assetUnit
                );

                if (rewardDataUpdated || userDataUpdated) {
                    emit Accrued(asset, reward, user, newAssetIndex, newAssetIndex, rewardsAccrued);
                }
            }
        }
    }

    /**
     * @dev Updates the state of the distribution for the specified reward
     * @param rewardData Storage pointer to the distribution reward config
     * @param totalStaked The total amount staked of the asset
     * @param assetUnit One unit of asset (10**decimals)
     * @return The new distribution index
     * @return True if the index was updated, false otherwise
     **/
    function _updateRewardData(
        RewardsDataTypes.RewardData storage rewardData,
        uint totalStaked,
        uint assetUnit
    ) internal returns (uint, bool) {
        (uint oldIndex, uint newIndex) = _getAssetIndex(rewardData, totalStaked, assetUnit);
        bool indexUpdated;
        if (newIndex != oldIndex) {
            require(newIndex <= type(uint104).max, "INDEX_OVERFLOW");
            indexUpdated = true;

            //optimization: storing one after another saves one SSTORE
            rewardData.index = uint104(newIndex);
            rewardData.lastUpdateTimestamp = block.timestamp.toUint32();
        } else {
            rewardData.lastUpdateTimestamp = block.timestamp.toUint32();
        }

        return (newIndex, indexUpdated);
    }

    /**
     * @dev Updates the state of the distribution for the specific user
     * @param rewardData Storage pointer to the distribution reward config
     * @param user The address of the user
     * @param userStake The amount of assets staked by the user
     * @param newAssetIndex The new index of the asset distribution
     * @param assetUnit One unit of asset (10**decimals)
     * @return The rewards accrued since the last update
     **/
    function _updateUserData(
        RewardsDataTypes.RewardData storage rewardData,
        address user,
        uint userStake,
        uint newAssetIndex,
        uint assetUnit
    ) internal returns (uint, bool) {
        uint userIndex = rewardData.usersData[user].index;
        uint rewardsAccrued;
        bool dataUpdated;
        if ((dataUpdated = userIndex != newAssetIndex)) {
            // already checked for overflow in _updateRewardData
            rewardData.usersData[user].index = uint104(newAssetIndex);
            if (userStake != 0) {
                rewardsAccrued = _getRewards(userStake, newAssetIndex, userIndex, assetUnit);

                rewardData.usersData[user].accrued += rewardsAccrued.toUint128();
            }
        }
        return (rewardsAccrued, dataUpdated);
    }

    /**
     * @dev Return the accrued unclaimed amount of a reward from a user over a list of distribution
     * @param user The address of the user
     * @param reward The address of the reward token
     * @param userAssetBalances List of structs with the user balance and total supply of a set of assets
     * @return unclaimedRewards The accrued rewards for the user until the moment
     **/
    function _getUserReward(
        address user,
        address reward,
        RewardsDataTypes.UserAssetBalance[] memory userAssetBalances
    ) internal view returns (uint unclaimedRewards) {
        // Add unrealized rewards
        for (uint i; i < userAssetBalances.length; i++) {
            if (userAssetBalances[i].userStake == 0) {
                unclaimedRewards += _assets[userAssetBalances[i].asset]
                    .rewards[reward]
                    .usersData[user]
                    .accrued;
            } else {
                unclaimedRewards +=
                    _getPendingRewards(user, reward, userAssetBalances[i]) +
                    _assets[userAssetBalances[i].asset].rewards[reward].usersData[user].accrued;
            }
        }

        return unclaimedRewards;
    }

    /**
     * @dev Calculates the pending (not yet accrued) rewards since the last user action
     * @param user The address of the user
     * @param reward The address of the reward token
     * @param userAssetBalance struct with the user balance and total supply of the incentivized asset
     * @return The pending rewards for the user since the last user action
     **/
    function _getPendingRewards(
        address user,
        address reward,
        RewardsDataTypes.UserAssetBalance memory userAssetBalance
    ) internal view returns (uint) {
        RewardsDataTypes.RewardData storage rewardData = _assets[userAssetBalance.asset].rewards[
            reward
        ];
        uint assetUnit = 10**_assets[userAssetBalance.asset].decimals;
        (, uint nextIndex) = _getAssetIndex(rewardData, userAssetBalance.totalStaked, assetUnit);

        return
            _getRewards(
                userAssetBalance.userStake,
                nextIndex,
                rewardData.usersData[user].index,
                assetUnit
            );
    }

    /**
     * @dev Internal function for the calculation of user's rewards on a distribution
     * @param userStake The amount of assets staked by the user on a distribution
     * @param reserveIndex Current index of the distribution
     * @param userIndex Index stored for the user, representation his staking moment
     * @param assetUnit One unit of asset (10**decimals)
     * @return The rewards
     **/
    function _getRewards(
        uint userStake,
        uint reserveIndex,
        uint userIndex,
        uint assetUnit
    ) internal pure returns (uint) {
        uint result = userStake * (reserveIndex - userIndex);
        assembly {
            result := div(result, assetUnit)
        }
        return result;
    }

    /**
     * @dev Calculates the next value of an specific distribution index, with validations
     * @param totalStaked The total amount staked of the asset
     * @param assetUnit One unit of asset (10**decimals)
     * @return The new index.
     **/
    function _getAssetIndex(
        RewardsDataTypes.RewardData storage rewardData,
        uint totalStaked,
        uint assetUnit
    ) internal view returns (uint, uint) {
        uint oldIndex = rewardData.index;
        uint distributionEnd = rewardData.distributionEnd;
        uint emissionPerSecond = rewardData.emissionPerSecond;
        uint lastUpdateTimestamp = rewardData.lastUpdateTimestamp;

        if (
            emissionPerSecond == 0 ||
            totalStaked == 0 ||
            lastUpdateTimestamp == block.timestamp ||
            lastUpdateTimestamp >= distributionEnd
        ) {
            return (oldIndex, oldIndex);
        }

        uint currentTimestamp = block.timestamp > distributionEnd
            ? distributionEnd
            : block.timestamp;
        uint timeDelta = currentTimestamp - lastUpdateTimestamp;
        uint firstTerm = emissionPerSecond * timeDelta * assetUnit;
        assembly {
            firstTerm := div(firstTerm, totalStaked)
        }
        return (oldIndex, (firstTerm + oldIndex));
    }

    /**
     * @dev Get user balances and total supply of all the assets specified by the assets parameter
     * @param assets List of assets to retrieve user balance and total supply
     * @param user Address of the user
     * @return userAssetBalances contains a list of structs with user balance and total supply of the given assets
     */
    function _getUserAssetBalances(address[] calldata assets, address user)
        internal
        view
        virtual
        returns (RewardsDataTypes.UserAssetBalance[] memory userAssetBalances);

    /**
     * @dev Updates the address of the emission manager
     * @param emissionManager The address of the new EmissionManager
     */
    function _setEmissionManager(address emissionManager) internal {
        address previousEmissionManager = _emissionManager;
        _emissionManager = emissionManager;
        emit EmissionManagerUpdated(previousEmissionManager, emissionManager);
    }
}
