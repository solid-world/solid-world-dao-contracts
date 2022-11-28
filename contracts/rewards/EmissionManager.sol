// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/rewards/IEmissionManager.sol";
import "../interfaces/manager/IWeeklyCarbonRewardsManager.sol";
import "../PostConstruct.sol";

/// @title EmissionManager
/// @author Aave
/// @notice It manages the list of admins of reward emissions and provides functions to control reward emissions.
contract EmissionManager is Ownable, IEmissionManager, PostConstruct {
    // reward => emissionAdmin
    mapping(address => address) internal _emissionAdmins;

    IWeeklyCarbonRewardsManager internal _carbonRewardsManager;
    IRewardsController internal _rewardsController;
    address internal carbonRewardAdmin;

    /// @dev Only emission admin of the given reward can call functions marked by this modifier.
    modifier onlyEmissionAdmin(address reward) {
        if (_emissionAdmins[reward] != msg.sender) {
            revert NotEmissionAdmin(msg.sender, reward);
        }
        _;
    }

    function setup(
        IWeeklyCarbonRewardsManager carbonRewardsManager,
        IRewardsController controller,
        address owner
    ) external postConstruct {
        _carbonRewardsManager = carbonRewardsManager;
        _rewardsController = controller;
        transferOwnership(owner);
    }

    /// @inheritdoc IEmissionManager
    function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config)
        external
        override
    {
        for (uint i; i < config.length; i++) {
            if (_emissionAdmins[config[i].reward] != msg.sender) {
                revert NotEmissionAdmin(msg.sender, config[i].reward);
            }
        }
        _rewardsController.configureAssets(config);
    }

    /// @inheritdoc IEmissionManager
    function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle)
        external
        override
        onlyEmissionAdmin(reward)
    {
        _rewardsController.setRewardOracle(reward, rewardOracle);
    }

    /// @inheritdoc IEmissionManager
    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external override onlyEmissionAdmin(reward) {
        _rewardsController.setDistributionEnd(asset, reward, newDistributionEnd);
    }

    /// @inheritdoc IEmissionManager
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external override {
        for (uint i; i < rewards.length; i++) {
            if (_emissionAdmins[rewards[i]] != msg.sender) {
                revert NotEmissionAdmin(msg.sender, rewards[i]);
            }
        }
        _rewardsController.setEmissionPerSecond(asset, rewards, newEmissionsPerSecond);
    }

    /// @inheritdoc IEmissionManager
    function updateCarbonRewardDistribution(address[] calldata assets, uint[] calldata categoryIds)
        external
        override
    {
        (address[] memory carbonRewards, uint[] memory rewardAmounts) = _carbonRewardsManager
            .computeWeeklyCarbonRewards(assets, categoryIds);

        _rewardsController.updateRewardDistribution(assets, carbonRewards, rewardAmounts);

        _carbonRewardsManager.mintWeeklyCarbonRewards(
            carbonRewards,
            rewardAmounts,
            _rewardsController.getRewardsVault()
        );
    }

    /// @inheritdoc IEmissionManager
    function setClaimer(address user, address claimer) external override onlyOwner {
        _rewardsController.setClaimer(user, claimer);
    }

    /// @inheritdoc IEmissionManager
    function setEmissionManager(address emissionManager) external override onlyOwner {
        _rewardsController.setEmissionManager(emissionManager);
    }

    /// @inheritdoc IEmissionManager
    function setEmissionAdmin(address reward, address admin) external override onlyOwner {
        address oldAdmin = _emissionAdmins[reward];
        _emissionAdmins[reward] = admin;
        emit EmissionAdminUpdated(reward, oldAdmin, admin);
    }

    /// @inheritdoc IEmissionManager
    function setRewardsController(address controller) external override onlyOwner {
        _rewardsController = IRewardsController(controller);
    }

    /// @inheritdoc IEmissionManager
    function getRewardsController() external view override returns (IRewardsController) {
        return _rewardsController;
    }

    /// @inheritdoc IEmissionManager
    function getEmissionAdmin(address reward) external view override returns (address) {
        return _emissionAdmins[reward];
    }

    /// @inheritdoc IEmissionManager
    function getCarbonRewardsManager() external view override returns (address) {
        return address(_carbonRewardsManager);
    }
}
