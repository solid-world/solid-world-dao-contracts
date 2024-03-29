// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../libraries/RewardsDataTypes.sol";
import "./IRewardsController.sol";

/// @title IEmissionManager
/// @author Aave
/// @notice Defines the basic interface for the Emission Manager
interface IEmissionManager {
    error NotEmissionAdmin(address sender, address reward);

    event EmissionAdminUpdated(address indexed reward, address indexed oldAdmin, address indexed newAdmin);
    event RewardsControllerUpdated(address indexed newRewardsController);
    event CarbonRewardsManagerUpdated(address indexed newCarbonRewardsManager);

    error InvalidInput();

    /// @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
    /// @dev Only callable by the emission admin of the given rewards
    /// @param config The assets configuration input, the list of structs contains the following fields:
    ///   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
    ///   uint256 totalSupply: The total supply of the asset to incentivize
    ///   uint40 distributionEnd: The end of the distribution of the incentives for an asset
    ///   address asset: The asset address to incentivize
    ///   address reward: The reward token address
    ///   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
    ///                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
    function configureAssets(RewardsDataTypes.DistributionConfig[] memory config) external;

    /// @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
    /// @dev Only callable by the emission admin of the given reward
    /// @notice At the moment of reward configuration, the Incentives Controller performs
    /// a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
    /// This check is enforced for integrators to be able to show incentives at
    /// the current Aave UI without the need to setup an external price registry
    /// @param reward The address of the reward to set the price aggregator
    /// @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
    function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

    /// @dev Sets the end date for the distribution
    /// @dev Only callable by the emission admin of the given reward
    /// @param asset The asset to incentivize
    /// @param reward The reward token that incentives the asset
    /// @param newDistributionEnd The end date of the incentivization, in unix time format
    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external;

    /// @dev Sets the emission per second of a set of reward distributions
    /// @param asset The asset is being incentivized
    /// @param rewards List of reward addresses are being distributed
    /// @param newEmissionsPerSecond List of new reward emissions per second
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external;

    /// @dev Computes and mints weekly carbon rewards, and instructs RewardsController how to distribute them
    /// @param assets The incentivized assets (hypervisors)
    /// @param _categoryIds The categories to which the incentivized assets belong
    function updateCarbonRewardDistribution(address[] calldata assets, uint[] calldata _categoryIds) external;

    /// @dev Whitelists an address to claim the rewards on behalf of another address
    /// @dev Only callable by the owner of the EmissionManager
    /// @param user The address of the user
    /// @param claimer The address of the claimer
    function setClaimer(address user, address claimer) external;

    /// @dev Only callable by the owner of the EmissionManager
    /// @param rewardsVault The address of the account that secures ERC20 rewards.
    function setRewardsVault(address rewardsVault) external;

    /// @dev Only callable by the owner of the EmissionManager
    /// @param solidStaking Used to fetch the total amount staked and the stake of an user for a given asset
    function setSolidStaking(address solidStaking) external;

    /// @dev Updates the address of the emission manager
    /// @dev Only callable by the owner of the EmissionManager
    /// @param emissionManager The address of the new EmissionManager
    function setEmissionManager(address emissionManager) external;

    /// @dev Updates the admin of the reward emission
    /// @dev Only callable by the owner of the EmissionManager
    /// @param reward The address of the reward token
    /// @param admin The address of the new admin of the emission
    function setEmissionAdmin(address reward, address admin) external;

    /// @dev Updates the address of the rewards controller
    /// @dev Only callable by the owner of the EmissionManager
    /// @param controller the address of the RewardsController contract
    function setRewardsController(address controller) external;

    /// @dev Only callable by the owner of the EmissionManager
    /// @param carbonRewardsManager the address of the IWeeklyCarbonRewardsManager contract
    function setCarbonRewardsManager(address carbonRewardsManager) external;

    /// @dev Returns the rewards controller address
    /// @return The address of the RewardsController contract
    function getRewardsController() external view returns (IRewardsController);

    /// @dev Returns the admin of the given reward emission
    /// @param reward The address of the reward token
    /// @return The address of the emission admin
    function getEmissionAdmin(address reward) external view returns (address);

    /// @return The address of the IWeeklyCarbonRewardsManager implementation contract
    function getCarbonRewardsManager() external view returns (address);
}
