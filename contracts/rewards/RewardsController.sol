// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./RewardsDistributor.sol";
import "../interfaces/rewards/IRewardsController.sol";
import "../PostConstruct.sol";
import "../libraries/GPv2SafeERC20.sol";

contract RewardsController is IRewardsController, RewardsDistributor, PostConstruct {
    // This mapping allows whitelisted addresses to claim on behalf of others
    // useful for contracts that hold tokens to be rewarded but don't have any native logic to claim Liquidity Mining rewards
    mapping(address => address) internal _authorizedClaimers;

    // This mapping contains the price oracle per reward.
    // A price oracle is enforced for integrators to be able to show incentives at
    // the current Aave UI without the need to setup an external price registry
    // At the moment of reward configuration, the Incentives Controller performs
    // a check to see if the provided reward oracle contains `latestAnswer`.
    mapping(address => IEACAggregatorProxy) internal _rewardOracle;

    /// @dev Account that secures ERC20 rewards.
    /// @dev It must approve `RewardsController` to spend the rewards it holds.
    address internal REWARDS_VAULT;

    modifier onlyAuthorizedClaimers(address claimer, address user) {
        if (_authorizedClaimers[user] != claimer) {
            revert UnauthorizedClaimer(claimer, user);
        }
        _;
    }

    function setup(
        ISolidStakingViewActions _solidStakingViewActions,
        address rewardsVault,
        address emissionManager
    ) external postConstruct {
        solidStakingViewActions = _solidStakingViewActions;
        REWARDS_VAULT = rewardsVault;
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
    function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config)
        external
        override
        onlyEmissionManager
    {
        for (uint i; i < config.length; i++) {
            // Get the current total staked amount for the asset
            config[i].totalStaked = solidStakingViewActions.totalStaked(config[i].asset);

            // Set reward oracle, enforces input oracle to have latestPrice function
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
    function handleAction(
        address asset,
        address user,
        uint userStake,
        uint totalStaked
    ) external override {
        if (msg.sender != address(solidStakingViewActions)) {
            revert NotSolidStaking(msg.sender);
        }

        _updateData(asset, user, userStake, totalStaked);
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

    /// @dev Get user balances and total supply of all the assets specified by the assets parameter
    /// @param assets List of assets to retrieve user balance and total supply
    /// @param user Address of the user
    /// @return userAssetBalances contains a list of structs with user balance and total supply of the given assets
    function _getUserAssetBalances(address[] calldata assets, address user)
        internal
        view
        override
        returns (RewardsDataTypes.UserAssetBalance[] memory userAssetBalances)
    {
        userAssetBalances = new RewardsDataTypes.UserAssetBalance[](assets.length);
        for (uint i; i < assets.length; i++) {
            userAssetBalances[i].asset = assets[i];
            userAssetBalances[i].userStake = solidStakingViewActions.balanceOf(assets[i], user);
            userAssetBalances[i].totalStaked = solidStakingViewActions.totalStaked(assets[i]);
        }
        return userAssetBalances;
    }

    /// @dev Claims one type of reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards.
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

        _updateDataMultiple(user, _getUserAssetBalances(assets, user));

        for (uint i; i < assets.length; i++) {
            address asset = assets[i];
            for (uint j; j < rewardsListLength; j++) {
                if (rewardsList[j] == address(0)) {
                    rewardsList[j] = _rewardsList[j];
                }
                uint rewardAmount = _assets[asset].rewards[rewardsList[j]].usersData[user].accrued;
                if (rewardAmount != 0) {
                    claimedAmounts[j] += rewardAmount;
                    _assets[asset].rewards[rewardsList[j]].usersData[user].accrued = 0;
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
}
