pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/interfaces/rewards/IRewardsDistributor.sol";
import "../../contracts/rewards/RewardsController.sol";
import "../../contracts/CollateralizedBasketToken.sol";

contract RewardsDistributorTest is Test {
    event Accrued(
        address indexed asset,
        address indexed reward,
        address indexed user,
        uint assetIndex,
        uint userIndex,
        uint rewardsAccrued
    );

    uint32 constant CURRENT_DATE = 1666016743;

    IRewardsDistributor rewardsDistributor;
    address solidStakingViewActions;
    address emissionManager;
    address rewardsVault;
    address rewardOracle;

    address asset0;
    uint asset0InitialTotalStaked;
    address asset1;
    uint asset1InitialTotalStaked;
    address reward00;
    address reward01;
    address reward1;

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
        asset0InitialTotalStaked = 500;
        asset1InitialTotalStaked = 1000;

        RewardsController rewardsController = new RewardsController();
        rewardsController.setup(
            ISolidStakingViewActions(solidStakingViewActions),
            rewardsVault,
            emissionManager
        );

        RewardsDataTypes.RewardsConfigInput[]
            memory config = new RewardsDataTypes.RewardsConfigInput[](3);
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

        vm.mockCall(
            rewardOracle,
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(1)
        );
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, asset0),
            abi.encode(asset0InitialTotalStaked)
        );
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, asset1),
            abi.encode(asset1InitialTotalStaked)
        );
        vm.prank(emissionManager);
        rewardsController.configureAssets(config);

        rewardsDistributor = IRewardsDistributor(rewardsController);

        vm.label(address(rewardsDistributor), "rewardsDistributor");
        vm.label(rewardsVault, "rewardsVault");
        vm.label(emissionManager, "emissionManager");
    }

    function testGetRewardsData() public {
        (
            uint index0,
            uint emissionPerSecond0,
            uint lastUpdateTimestamp0,
            uint distributionEnd0
        ) = rewardsDistributor.getRewardsData(asset0, reward00);

        assertEq(index0, 0);
        assertEq(emissionPerSecond0, 0);
        assertEq(lastUpdateTimestamp0, CURRENT_DATE);
        assertEq(distributionEnd0, CURRENT_DATE);

        (
            uint index1,
            uint emissionPerSecond1,
            uint lastUpdateTimestamp1,
            uint distributionEnd1
        ) = rewardsDistributor.getRewardsData(asset1, reward1);

        assertEq(index1, 0);
        assertEq(emissionPerSecond1, 0);
        assertEq(lastUpdateTimestamp1, CURRENT_DATE);
        assertEq(distributionEnd1, CURRENT_DATE + 1 seconds);

        (
            uint index2,
            uint emissionPerSecond2,
            uint lastUpdateTimestamp2,
            uint distributionEnd2
        ) = rewardsDistributor.getRewardsData(asset0, reward01);

        assertEq(index2, 0);
        assertEq(emissionPerSecond2, 0);
        assertEq(lastUpdateTimestamp2, CURRENT_DATE);
        assertEq(distributionEnd2, CURRENT_DATE + 2 seconds);

        (
            uint index,
            uint emissionPerSecond,
            uint lastUpdateTimestamp,
            uint distributionEnd
        ) = rewardsDistributor.getRewardsData(vm.addr(77), vm.addr(77));

        assertEq(index, 0);
        assertEq(emissionPerSecond, 0);
        assertEq(lastUpdateTimestamp, 0);
        assertEq(distributionEnd, 0);
    }

    function testGetDistributionEnd() public {
        assertEq(rewardsDistributor.getDistributionEnd(asset0, reward00), CURRENT_DATE);
        assertEq(rewardsDistributor.getDistributionEnd(asset1, reward1), CURRENT_DATE + 1 seconds);
        assertEq(rewardsDistributor.getDistributionEnd(asset0, reward01), CURRENT_DATE + 2 seconds);
        assertEq(rewardsDistributor.getDistributionEnd(vm.addr(77), vm.addr(77)), 0);
    }

    function testGetRewardsByAsset() public {
        address[] memory rewards0 = rewardsDistributor.getRewardsByAsset(asset0);
        assertEq(rewards0.length, 2);
        assertEq(rewards0[0], reward00);
        assertEq(rewards0[1], reward01);

        address[] memory rewards1 = rewardsDistributor.getRewardsByAsset(asset1);
        assertEq(rewards1.length, 1);
        assertEq(rewards1[0], reward1);

        address[] memory rewards2 = rewardsDistributor.getRewardsByAsset(vm.addr(77));
        assertEq(rewards2.length, 0);
    }

    function testGetRewardsList() public {
        address[] memory rewards = rewardsDistributor.getRewardsList();
        assertEq(rewards.length, 3);
        assertEq(rewards[0], reward00);
        assertEq(rewards[1], reward1);
        assertEq(rewards[2], reward01);
    }

    function testUpdateData() public {
        address[] memory rewards = new address[](2);
        rewards[0] = reward00;
        rewards[1] = reward01;
        uint88[] memory newEmissionsPerSecond = new uint88[](2);
        newEmissionsPerSecond[0] = 100;
        newEmissionsPerSecond[1] = 200;
        vm.startPrank(emissionManager);
        rewardsDistributor.setEmissionPerSecond(asset0, rewards, newEmissionsPerSecond);
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE + 1 weeks);
        rewardsDistributor.setDistributionEnd(asset0, reward01, CURRENT_DATE + 2 weeks);
        vm.stopPrank();

        address asset = asset0;
        address user = vm.addr(10);
        uint userStake = 100e18;
        uint totalStaked = 500e18;

        vm.warp(CURRENT_DATE + 5 seconds);
        vm.expectEmit(true, true, true, true, address(rewardsDistributor));
        emit Accrued(asset, reward00, user, 1, 1, 100);
        vm.expectEmit(true, true, true, true, address(rewardsDistributor));
        emit Accrued(asset, reward01, user, 2, 2, 200);
        vm.prank(solidStakingViewActions);
        IRewardsController(address(rewardsDistributor)).handleAction( // call handleAction which calls _updateData
            asset,
            user,
            userStake,
            totalStaked
        );

        (
            uint index0,
            uint emissionPerSecond0,
            uint lastUpdateTimestamp0,
            uint distributionEnd0
        ) = rewardsDistributor.getRewardsData(asset0, reward00);
        assertEq(index0, 1);
        assertEq(emissionPerSecond0, 100);
        assertEq(lastUpdateTimestamp0, CURRENT_DATE + 5 seconds);
        assertEq(distributionEnd0, CURRENT_DATE + 1 weeks);

        (
            uint index1,
            uint emissionPerSecond1,
            uint lastUpdateTimestamp1,
            uint distributionEnd1
        ) = rewardsDistributor.getRewardsData(asset0, reward01);
        assertEq(index1, 2);
        assertEq(emissionPerSecond1, 200);
        assertEq(lastUpdateTimestamp1, CURRENT_DATE + 5 seconds);
        assertEq(distributionEnd1, CURRENT_DATE + 2 weeks);

        address[] memory assets = new address[](1);
        assets[0] = asset;
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.balanceOf.selector),
            abi.encode(userStake)
        );
        (address[] memory rewardsList, uint[] memory unclaimedAmounts) = rewardsDistributor
            .getAllUserRewards(assets, vm.addr(10));

        assertEq(rewardsList.length, 3);
        assertEq(rewardsList[0], reward00);
        assertEq(rewardsList[1], reward1);
        assertEq(rewardsList[2], reward01);

        assertEq(unclaimedAmounts.length, 3);
        assertEq(unclaimedAmounts[0], 100);
        assertEq(unclaimedAmounts[1], 0);
        assertEq(unclaimedAmounts[2], 200);
    }

    function testGetUserAssetIndex() public {
        address[] memory rewards = new address[](2);
        rewards[0] = reward00;
        rewards[1] = reward01;
        uint88[] memory newEmissionsPerSecond = new uint88[](2);
        newEmissionsPerSecond[0] = 100;
        newEmissionsPerSecond[1] = 200;
        vm.startPrank(emissionManager);
        rewardsDistributor.setEmissionPerSecond(asset0, rewards, newEmissionsPerSecond);
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE + 1 weeks);
        rewardsDistributor.setDistributionEnd(asset0, reward01, CURRENT_DATE + 2 weeks);
        vm.stopPrank();

        address asset = asset0;
        address user = vm.addr(10);
        uint userStake = 100e18;
        uint totalStaked = 500e18;

        vm.warp(CURRENT_DATE + 5 seconds);
        vm.prank(solidStakingViewActions);
        IRewardsController(address(rewardsDistributor)).handleAction( // updates user index
            asset,
            user,
            userStake,
            totalStaked
        );

        assertEq(rewardsDistributor.getUserAssetIndex(user, asset, reward00), 1);
        assertEq(rewardsDistributor.getUserAssetIndex(user, asset, reward01), 2);
        assertEq(rewardsDistributor.getUserAssetIndex(user, asset, reward1), 0);
    }

    function testGetUserAccruedRewards() public {
        address[] memory rewards = new address[](2);
        rewards[0] = reward00;
        rewards[1] = reward01;
        uint88[] memory newEmissionsPerSecond = new uint88[](2);
        newEmissionsPerSecond[0] = 100;
        newEmissionsPerSecond[1] = 200;
        vm.startPrank(emissionManager);
        rewardsDistributor.setEmissionPerSecond(asset0, rewards, newEmissionsPerSecond);
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE + 1 weeks);
        rewardsDistributor.setDistributionEnd(asset0, reward01, CURRENT_DATE + 2 weeks);
        vm.stopPrank();

        address asset = asset0;
        address user = vm.addr(10);
        uint userStake = 100e18;
        uint totalStaked = 500e18;

        vm.warp(CURRENT_DATE + 5 seconds);
        vm.prank(solidStakingViewActions);
        IRewardsController(address(rewardsDistributor)).handleAction( // updates user index
            asset,
            user,
            userStake,
            totalStaked
        );

        assertEq(rewardsDistributor.getUserAccruedRewards(user, reward00), 100);
        assertEq(rewardsDistributor.getUserAccruedRewards(user, reward01), 200);
        assertEq(rewardsDistributor.getUserAccruedRewards(user, reward1), 0);
    }

    function testGetUserRewards() public {
        address[] memory rewards = new address[](2);
        rewards[0] = reward00;
        rewards[1] = reward01;
        uint88[] memory newEmissionsPerSecond = new uint88[](2);
        newEmissionsPerSecond[0] = 100;
        newEmissionsPerSecond[1] = 200;
        vm.startPrank(emissionManager);
        rewardsDistributor.setEmissionPerSecond(asset0, rewards, newEmissionsPerSecond);
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE + 1 weeks);
        rewardsDistributor.setDistributionEnd(asset0, reward01, CURRENT_DATE + 2 weeks);
        vm.stopPrank();

        address asset = asset0;
        address user = vm.addr(10);
        uint userStake = 100e18;
        uint totalStaked = 500e18;

        vm.warp(CURRENT_DATE + 5 seconds);
        vm.prank(solidStakingViewActions);
        IRewardsController(address(rewardsDistributor)).handleAction( // updates user index
            asset,
            user,
            userStake,
            totalStaked
        );

        address[] memory assets = new address[](1);
        assets[0] = asset;
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.balanceOf.selector),
            abi.encode(userStake)
        );
        uint reward = rewardsDistributor.getUserRewards(assets, user, reward00);

        assertEq(reward, 100);
    }
}
