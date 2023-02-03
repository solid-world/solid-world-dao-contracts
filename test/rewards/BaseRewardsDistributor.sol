// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../BaseTest.sol";
import "../../contracts/interfaces/rewards/IRewardsDistributor.sol";
import "../../contracts/rewards/RewardsController.sol";
import "../../contracts/CollateralizedBasketToken.sol";

abstract contract BaseRewardsDistributor is BaseTest {
    event Accrued(
        address indexed asset,
        address indexed reward,
        address indexed user,
        uint assetIndex,
        uint userIndex,
        uint rewardsAccrued
    );
    event AssetConfigUpdated(
        address indexed asset,
        address indexed reward,
        uint oldEmission,
        uint newEmission,
        uint oldDistributionEnd,
        uint newDistributionEnd,
        uint assetIndex
    );
    event EmissionManagerUpdated(
        address indexed oldEmissionManager,
        address indexed newEmissionManager
    );

    uint32 constant CURRENT_DATE = 1666016743;

    IRewardsDistributor rewardsDistributor;
    address solidStakingViewActions;
    address emissionManager;
    address rewardsVault;
    address rewardOracle;

    address asset0;
    address asset1;
    address reward00;
    address reward01;
    address reward1;

    address arbitraryUser;
    uint arbitraryUserStake = 100e18;
    uint arbitraryTotalStaked = 500e18;

    function setUp() public {
        vm.warp(CURRENT_DATE);

        solidStakingViewActions = vm.addr(1);
        rewardsVault = vm.addr(2);
        emissionManager = vm.addr(3);
        rewardOracle = vm.addr(4);
        asset0 = address(new CollateralizedBasketToken("", ""));
        asset1 = address(new CollateralizedBasketToken("", ""));
        reward00 = address(new CollateralizedBasketToken("", ""));
        reward01 = address(new CollateralizedBasketToken("", ""));
        reward1 = address(new CollateralizedBasketToken("", ""));
        arbitraryUser = vm.addr(10);
        rewardsDistributor = _initializedRewardsDistributor();

        _labelAccounts();
    }

    function _labelAccounts() private {
        vm.label(address(rewardsDistributor), "RewardsDistributor");
        vm.label(solidStakingViewActions, "SolidStakingViewActions");
        vm.label(rewardsVault, "RewardsVault");
        vm.label(rewardOracle, "RewardOracle");
        vm.label(emissionManager, "EmissionManager");
        vm.label(arbitraryUser, "ArbitraryUser");
    }

    function _initializedRewardsDistributor()
        private
        returns (IRewardsDistributor _rewardsDistributor)
    {
        RewardsController rewardsController = new RewardsController();
        rewardsController.setup(solidStakingViewActions, rewardsVault, emissionManager);

        vm.prank(emissionManager);
        _mockOracleLatestAnswer();
        _mockAssetsTotalStaked();
        rewardsController.configureAssets(_makeDistributionConfig());

        _rewardsDistributor = IRewardsDistributor(rewardsController);
    }

    function _makeDistributionConfig()
        private
        view
        returns (RewardsDataTypes.DistributionConfig[] memory config)
    {
        config = new RewardsDataTypes.DistributionConfig[](3);

        config[0].asset = asset0;
        config[0].reward = reward00;
        config[0].rewardOracle = IEACAggregatorProxy(rewardOracle);
        config[0].distributionEnd = CURRENT_DATE;

        config[1].asset = asset1;
        config[1].reward = reward1;
        config[1].rewardOracle = IEACAggregatorProxy(rewardOracle);
        config[1].distributionEnd = CURRENT_DATE + 1 seconds;

        config[2].asset = asset0;
        config[2].reward = reward01;
        config[2].rewardOracle = IEACAggregatorProxy(rewardOracle);
        config[2].distributionEnd = CURRENT_DATE + 2 seconds;
    }

    function _mockAssetsTotalStaked() private {
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, asset0),
            abi.encode(500e18)
        );
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, asset1),
            abi.encode(500e18)
        );
    }

    function _mockOracleLatestAnswer() private {
        vm.mockCall(
            rewardOracle,
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(1)
        );
    }

    function _mockUserStakeAmount(uint stakeAmount) internal {
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.balanceOf.selector),
            abi.encode(stakeAmount)
        );
    }

    function _mockTotalStaked(uint totalStaked) internal {
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector),
            abi.encode(totalStaked)
        );
    }

    function _expectEmitAccrued(
        address asset,
        address reward,
        address user,
        uint assetIndex,
        uint userIndex,
        uint rewardsAccrued
    ) internal {
        vm.expectEmit(true, true, true, true, address(rewardsDistributor));
        emit Accrued(asset, reward, user, assetIndex, userIndex, rewardsAccrued);
    }

    function _expectEmit_EmissionManagerUpdated(address newEmissionManager) internal {
        vm.expectEmit(true, true, false, false, address(rewardsDistributor));
        emit EmissionManagerUpdated(emissionManager, newEmissionManager);
    }

    function _expectEmitAssetConfigUpdated(
        address asset,
        address reward,
        uint oldEmission,
        uint newEmission,
        uint oldDistributionEnd,
        uint newDistributionEnd,
        uint assetIndex
    ) internal {
        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(
            asset,
            reward,
            oldEmission,
            newEmission,
            oldDistributionEnd,
            newDistributionEnd,
            assetIndex
        );
    }

    function _expectRevert_InvalidInput() internal {
        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidInput.selector));
    }

    function _expectRevert_NotEmissionManager() internal {
        vm.expectRevert(
            abi.encodeWithSelector(IRewardsDistributor.NotEmissionManager.selector, address(this))
        );
    }

    function _expectRevert_DistributionNonExistent(address asset, address reward) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.DistributionNonExistent.selector,
                asset,
                reward
            )
        );
    }

    function _expectRevert_UpdateDistributionNotApplicable(address asset, address reward) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.UpdateDistributionNotApplicable.selector,
                asset,
                reward
            )
        );
    }

    function _distributeRewardsForOneWeek(
        address asset,
        address reward,
        uint emissionPerSecond
    ) internal {
        (
            address[] memory rewards,
            uint88[] memory emissionsPerSecond
        ) = _makeRewardsAndEmissionsPerSecond(reward, emissionPerSecond);

        vm.startPrank(emissionManager);
        rewardsDistributor.setEmissionPerSecond(asset, rewards, emissionsPerSecond);
        rewardsDistributor.setDistributionEnd(asset, reward, CURRENT_DATE + 1 weeks);
        vm.stopPrank();
    }

    function _makeRewardsAndEmissionsPerSecond(address reward, uint emissionPerSecond)
        internal
        pure
        returns (address[] memory rewards, uint88[] memory emissionsPerSecond)
    {
        rewards = _toArray(reward);
        emissionsPerSecond = _toArrayUint88(uint88(emissionPerSecond));
    }

    /// @notice Simulates a user staking, and assumes the user's stake and total staked
    /// before this action were `userStake` and `totalStaked` respectively.
    function _simulateUserStaking(
        address asset,
        address user,
        uint userStake,
        uint totalStaked
    ) internal {
        // call handleUserStakeChanged which calls _updateAllRewardDistributionsAndUserRewardsForAsset
        vm.prank(solidStakingViewActions);
        IRewardsController(address(rewardsDistributor)).handleUserStakeChanged(
            asset,
            user,
            userStake,
            totalStaked
        );
    }

    function _earnedRewards(
        uint secondsPassed,
        uint emissionPerSecond,
        uint userStake,
        uint totalStaked
    ) internal pure returns (uint earnedRewards) {
        return (secondsPassed * emissionPerSecond * userStake) / totalStaked;
    }

    function _getEmissionPerSecond(address asset, address reward)
        internal
        view
        returns (uint emissionPerSecond)
    {
        (, emissionPerSecond, , ) = rewardsDistributor.getRewardDistribution(asset, reward);
    }

    function _getDistributionIndex(address asset, address reward)
        internal
        view
        returns (uint index)
    {
        (index, , , ) = rewardsDistributor.getRewardDistribution(asset, reward);
    }

    function _getDistributionUpdateTimestamp(address asset, address reward)
        internal
        view
        returns (uint lastUpdateTimestamp)
    {
        (, , lastUpdateTimestamp, ) = rewardsDistributor.getRewardDistribution(asset, reward);
    }
}
