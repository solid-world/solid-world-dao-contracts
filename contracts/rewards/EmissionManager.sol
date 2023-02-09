// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/rewards/IEmissionManager.sol";
import "../interfaces/manager/IWeeklyCarbonRewardsManager.sol";
import "../PostConstruct.sol";

/// @title EmissionManager
/// @author Aave
/// @notice It manages the list of admins of reward emissions and provides functions to control reward emissions.
contract EmissionManager is Ownable, IEmissionManager, PostConstruct, ReentrancyGuard {
    // reward => emissionAdmin
    mapping(address => address) internal _emissionAdmins;

    IWeeklyCarbonRewardsManager internal _carbonRewardsManager;
    IRewardsController internal _rewardsController;

    modifier onlyEmissionAdmin(address reward) {
        if (_emissionAdmins[reward] != msg.sender) {
            revert NotEmissionAdmin(msg.sender, reward);
        }
        _;
    }

    function setup(
        address carbonRewardsManager,
        address controller,
        address owner
    ) external postConstruct {
        _setCarbonRewardsManager(carbonRewardsManager);
        _setRewardsController(controller);
        transferOwnership(owner);
    }

    /// @inheritdoc IEmissionManager
    function configureAssets(RewardsDataTypes.DistributionConfig[] memory config) external override {
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
        nonReentrant
    {
        if (assets.length != categoryIds.length) {
            revert InvalidInput();
        }

        (
            address[] memory carbonRewards,
            uint[] memory rewardAmounts,
            uint[] memory rewardFees
        ) = _carbonRewardsManager.computeWeeklyCarbonRewards(categoryIds);

        _rewardsController.updateCarbonRewardDistribution(assets, carbonRewards, rewardAmounts);

        _carbonRewardsManager.mintWeeklyCarbonRewards(
            categoryIds,
            carbonRewards,
            rewardAmounts,
            rewardFees,
            _rewardsController.getRewardsVault()
        );
    }

    /// @inheritdoc IEmissionManager
    function setClaimer(address user, address claimer) external override onlyOwner {
        _rewardsController.setClaimer(user, claimer);
    }

    /// @inheritdoc IEmissionManager
    function setRewardsVault(address rewardsVault) external override onlyOwner {
        _rewardsController.setRewardsVault(rewardsVault);
    }

    /// @inheritdoc IEmissionManager
    function setEmissionManager(address emissionManager) external override onlyOwner {
        _rewardsController.setEmissionManager(emissionManager);
    }

    /// @inheritdoc IEmissionManager
    function setSolidStaking(address solidStaking) external override onlyOwner {
        _rewardsController.setSolidStaking(solidStaking);
    }

    /// @inheritdoc IEmissionManager
    function setEmissionAdmin(address reward, address admin) external override onlyOwner {
        address oldAdmin = _emissionAdmins[reward];
        _emissionAdmins[reward] = admin;
        emit EmissionAdminUpdated(reward, oldAdmin, admin);
    }

    /// @inheritdoc IEmissionManager
    function setRewardsController(address controller) external override onlyOwner {
        _setRewardsController(controller);
    }

    /// @inheritdoc IEmissionManager
    function setCarbonRewardsManager(address carbonRewardsManager) external override onlyOwner {
        _setCarbonRewardsManager(carbonRewardsManager);
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

    function _setCarbonRewardsManager(address carbonRewardsManager) internal {
        _carbonRewardsManager = IWeeklyCarbonRewardsManager(carbonRewardsManager);

        emit CarbonRewardsManagerUpdated(carbonRewardsManager);
    }

    function _setRewardsController(address controller) internal {
        _rewardsController = IRewardsController(controller);

        emit RewardsControllerUpdated(controller);
    }
}
