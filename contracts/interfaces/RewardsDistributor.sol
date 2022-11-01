pragma solidity ^0.8.0;

import "./rewards/IRewardsDistributor.sol";

contract RewardsDistributor is IRewardsDistributor {
    /// @inheritdoc IRewardsDistributor
    function getRewardsData(address asset, address reward)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function getDistributionEnd(address asset, address reward)
        external
        view
        override
        returns (uint256)
    {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function getRewardsByAsset(address asset) external view override returns (address[] memory) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function getRewardsList() external view override returns (address[] memory) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function getUserAssetIndex(
        address user,
        address asset,
        address reward
    ) public view override returns (uint256) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function getUserAccruedRewards(address user, address reward)
        external
        view
        override
        returns (uint256)
    {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view override returns (uint256) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function getAllUserRewards(address[] calldata assets, address user)
        external
        view
        override
        returns (address[] memory rewardsList, uint256[] memory unclaimedAmounts)
    {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external override {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external override {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function getAssetDecimals(address asset) external view returns (uint8) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function getEmissionManager() external view returns (address) {
        revert("Not implemented");
    }

    /// @inheritdoc IRewardsDistributor
    function setEmissionManager(address emissionManager) external {
        revert("Not implemented");
    }
}
