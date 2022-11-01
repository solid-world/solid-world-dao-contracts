pragma solidity ^0.8.0;

import "./rewards/IRewardsController.sol";
import "./RewardsDistributor.sol";

contract RewardsController is IRewardsController, RewardsDistributor {
    /// @inheritdoc IRewardsController
    function getClaimer(address user) external view override returns (address) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function getRewardOracle(address reward) external view override returns (address) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function getTransferStrategy(address reward) external view override returns (address) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config)
        external
        override
    {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function setTransferStrategy(address reward, ITransferStrategyBase transferStrategy) external {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function handleAction(
        address user,
        uint256 totalSupply,
        uint256 userBalance
    ) external override {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to,
        address reward
    ) external override returns (uint256) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to,
        address reward
    ) external override returns (uint256) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function claimRewardsToSelf(
        address[] calldata assets,
        uint256 amount,
        address reward
    ) external override returns (uint256) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function claimAllRewards(address[] calldata assets, address to)
        external
        override
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts)
    {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function claimAllRewardsOnBehalf(
        address[] calldata assets,
        address user,
        address to
    ) external override returns (address[] memory rewardsList, uint256[] memory claimedAmounts) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function claimAllRewardsToSelf(address[] calldata assets)
        external
        override
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts)
    {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsController
    function setClaimer(address user, address caller) external override {
        revert("Not implemented");
    }
}
