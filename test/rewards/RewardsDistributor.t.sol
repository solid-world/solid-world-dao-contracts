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

        RewardsController rewardsController = new RewardsController();
        rewardsController.setup(
            ISolidStakingViewActions(solidStakingViewActions),
            rewardsVault,
            emissionManager
        );

        RewardsDataTypes.DistributionConfig[]
            memory config = new RewardsDataTypes.DistributionConfig[](3);
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
            abi.encode(500e18)
        );
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, asset1),
            abi.encode(500e18)
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

    function testGetAllUserRewards() public {
        address[] memory rewards0 = new address[](2);
        rewards0[0] = reward00;
        rewards0[1] = reward01;
        uint88[] memory newEmissionsPerSecond0 = new uint88[](2);
        newEmissionsPerSecond0[0] = 100;
        newEmissionsPerSecond0[1] = 200;

        address[] memory rewards1 = new address[](1);
        rewards1[0] = reward1;
        uint88[] memory newEmissionsPerSecond1 = new uint88[](1);
        newEmissionsPerSecond1[0] = 300;
        vm.startPrank(emissionManager);
        rewardsDistributor.setEmissionPerSecond(asset0, rewards0, newEmissionsPerSecond0);
        rewardsDistributor.setEmissionPerSecond(asset1, rewards1, newEmissionsPerSecond1);
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE + 1 weeks);
        rewardsDistributor.setDistributionEnd(asset0, reward01, CURRENT_DATE + 2 weeks);
        rewardsDistributor.setDistributionEnd(asset1, reward1, CURRENT_DATE + 3 weeks);
        vm.stopPrank();

        address user = vm.addr(10);
        uint userStake = 100e18;
        uint totalStaked = 500e18;

        vm.warp(CURRENT_DATE + 5 seconds);
        vm.startPrank(solidStakingViewActions);
        IRewardsController(address(rewardsDistributor)).handleAction(
            asset0,
            user,
            userStake,
            totalStaked
        );
        IRewardsController(address(rewardsDistributor)).handleAction(
            asset1,
            user,
            userStake,
            totalStaked
        );
        vm.stopPrank();

        vm.warp(CURRENT_DATE + 10 seconds); // advance time by 5 more seconds to double rewards

        address[] memory assets = new address[](2);
        assets[0] = asset0;
        assets[1] = asset1;
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.balanceOf.selector),
            abi.encode(userStake)
        );
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector),
            abi.encode(totalStaked)
        );
        (address[] memory rewardsList, uint[] memory unclaimedAmounts) = rewardsDistributor
            .getAllUserRewards(assets, user);

        assertEq(rewardsList.length, 3);
        assertEq(rewardsList[0], reward00);
        assertEq(rewardsList[1], reward1);
        assertEq(rewardsList[2], reward01);

        assertEq(unclaimedAmounts.length, 3);
        assertEq(unclaimedAmounts[0], 100 * 2);
        assertEq(unclaimedAmounts[1], 300 * 2);
        assertEq(unclaimedAmounts[2], 200 * 2);
    }

    function testSetDistributionEnd_failsIfNotCalledByEmissionManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(IRewardsDistributor.NotEmissionManager.selector, address(this))
        );
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE + 1 weeks);
    }

    function testSetDistributionEnd_failsForNonExistentDistribution() public {
        address reward = vm.addr(77);

        vm.prank(emissionManager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.DistributionNonExistent.selector,
                asset0,
                reward
            )
        );
        rewardsDistributor.setDistributionEnd(asset0, reward, CURRENT_DATE + 1 weeks);
    }

    function testSetDistributionEnd() public {
        vm.startPrank(emissionManager);
        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(asset0, reward00, 0, 0, CURRENT_DATE, CURRENT_DATE + 1 weeks, 0);
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE + 1 weeks);

        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(
            asset1,
            reward1,
            0,
            0,
            CURRENT_DATE + 1 seconds,
            CURRENT_DATE + 2 weeks,
            0
        );
        rewardsDistributor.setDistributionEnd(asset1, reward1, CURRENT_DATE + 2 weeks);

        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(
            asset0,
            reward01,
            0,
            0,
            CURRENT_DATE + 2 seconds,
            CURRENT_DATE + 3 weeks,
            0
        );
        rewardsDistributor.setDistributionEnd(asset0, reward01, CURRENT_DATE + 3 weeks);

        vm.stopPrank();

        (, , , uint distributionEnd00) = rewardsDistributor.getRewardsData(asset0, reward00);
        assertEq(distributionEnd00, CURRENT_DATE + 1 weeks);

        (, , , uint distributionEnd1) = rewardsDistributor.getRewardsData(asset1, reward1);
        assertEq(distributionEnd1, CURRENT_DATE + 2 weeks);

        (, , , uint distributionEnd01) = rewardsDistributor.getRewardsData(asset0, reward01);
        assertEq(distributionEnd01, CURRENT_DATE + 3 weeks);
    }

    function testSetEmissionPerSecond_failsIfNotCalledByEmissionManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(IRewardsDistributor.NotEmissionManager.selector, address(this))
        );
        rewardsDistributor.setEmissionPerSecond(asset0, new address[](0), new uint88[](0));
    }

    function testSetEmissionPerSecond_failsForInvalidInput() public {
        vm.prank(emissionManager);
        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidInput.selector));
        rewardsDistributor.setEmissionPerSecond(asset0, new address[](2), new uint88[](0));
    }

    function testSetEmissionPerSecond_failsForNonExistentDistribution() public {
        vm.prank(emissionManager);
        address[] memory rewards = new address[](1);
        rewards[0] = vm.addr(77);
        uint88[] memory newEmissionsPerSecond = new uint88[](1);
        newEmissionsPerSecond[0] = 300;
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.DistributionNonExistent.selector,
                asset0,
                rewards[0]
            )
        );
        rewardsDistributor.setEmissionPerSecond(asset0, rewards, newEmissionsPerSecond);
    }

    function testSetEmissionPerSecond() public {
        address[] memory rewards0 = new address[](2);
        rewards0[0] = reward00;
        rewards0[1] = reward01;
        uint88[] memory newEmissionsPerSecond0 = new uint88[](2);
        newEmissionsPerSecond0[0] = 100;
        newEmissionsPerSecond0[1] = 200;

        address[] memory rewards1 = new address[](1);
        rewards1[0] = reward1;
        uint88[] memory newEmissionsPerSecond1 = new uint88[](1);
        newEmissionsPerSecond1[0] = 300;

        vm.startPrank(emissionManager);

        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(asset0, reward00, 0, 100, CURRENT_DATE, CURRENT_DATE, 0);
        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(
            asset0,
            reward01,
            0,
            200,
            CURRENT_DATE + 2 seconds,
            CURRENT_DATE + 2 seconds,
            0
        );
        rewardsDistributor.setEmissionPerSecond(asset0, rewards0, newEmissionsPerSecond0);

        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(
            asset1,
            reward1,
            0,
            300,
            CURRENT_DATE + 1 seconds,
            CURRENT_DATE + 1 seconds,
            0
        );
        rewardsDistributor.setEmissionPerSecond(asset1, rewards1, newEmissionsPerSecond1);
        vm.stopPrank();

        (uint index00, uint emissionPerSecond00, uint lastUpdateTimestamp00, ) = rewardsDistributor
            .getRewardsData(asset0, reward00);
        assertEq(index00, 0);
        assertEq(emissionPerSecond00, 100);
        assertEq(lastUpdateTimestamp00, CURRENT_DATE);

        (uint index01, uint emissionPerSecond01, uint lastUpdateTimestamp01, ) = rewardsDistributor
            .getRewardsData(asset0, reward01);
        assertEq(index01, 0);
        assertEq(emissionPerSecond01, 200);
        assertEq(lastUpdateTimestamp01, CURRENT_DATE);

        (uint index1, uint emissionPerSecond1, uint lastUpdateTimestamp1, ) = rewardsDistributor
            .getRewardsData(asset1, reward1);
        assertEq(index1, 0);
        assertEq(emissionPerSecond1, 300);
        assertEq(lastUpdateTimestamp1, CURRENT_DATE);
    }

    function testSetEmissionPerSecond_updatesIndexBasedOnTimePassedSinceLastUpdate() public {
        address[] memory rewards0 = new address[](2);
        rewards0[0] = reward00;
        rewards0[1] = reward01;
        uint88[] memory newEmissionsPerSecond0 = new uint88[](2);
        newEmissionsPerSecond0[0] = 100;
        newEmissionsPerSecond0[1] = 200;

        address[] memory rewards1 = new address[](1);
        rewards1[0] = reward1;
        uint88[] memory newEmissionsPerSecond1 = new uint88[](1);
        newEmissionsPerSecond1[0] = 300;

        uint32 distributionEnd00 = CURRENT_DATE + 1 weeks;
        uint32 distributionEnd01 = CURRENT_DATE + 2 weeks;
        uint32 distributionEnd1 = CURRENT_DATE + 3 weeks;

        vm.startPrank(emissionManager);
        rewardsDistributor.setDistributionEnd(asset0, reward00, distributionEnd00);
        rewardsDistributor.setDistributionEnd(asset0, reward01, distributionEnd01);
        rewardsDistributor.setDistributionEnd(asset1, reward1, distributionEnd1);
        rewardsDistributor.setEmissionPerSecond(asset0, rewards0, newEmissionsPerSecond0); // set "old" emissions
        rewardsDistributor.setEmissionPerSecond(asset1, rewards1, newEmissionsPerSecond1); // set "old" emissions

        uint32 updateTimestamp = CURRENT_DATE + 5 seconds;
        vm.warp(updateTimestamp);

        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(
            asset0,
            reward00,
            newEmissionsPerSecond0[0],
            newEmissionsPerSecond0[0],
            distributionEnd00,
            distributionEnd00,
            1
        );
        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(
            asset0,
            reward01,
            newEmissionsPerSecond0[1],
            newEmissionsPerSecond0[1],
            distributionEnd01,
            distributionEnd01,
            2
        );
        rewardsDistributor.setEmissionPerSecond(asset0, rewards0, newEmissionsPerSecond0);

        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(
            asset1,
            reward1,
            newEmissionsPerSecond1[0],
            newEmissionsPerSecond1[0],
            distributionEnd1,
            distributionEnd1,
            3
        );
        rewardsDistributor.setEmissionPerSecond(asset1, rewards1, newEmissionsPerSecond1);
        vm.stopPrank();

        (uint index00, uint emissionPerSecond00, uint lastUpdateTimestamp00, ) = rewardsDistributor
            .getRewardsData(asset0, reward00);
        assertEq(index00, 1);
        assertEq(emissionPerSecond00, newEmissionsPerSecond0[0]);
        assertEq(lastUpdateTimestamp00, updateTimestamp);

        (uint index01, uint emissionPerSecond01, uint lastUpdateTimestamp01, ) = rewardsDistributor
            .getRewardsData(asset0, reward01);
        assertEq(index01, 2);
        assertEq(emissionPerSecond01, newEmissionsPerSecond0[1]);
        assertEq(lastUpdateTimestamp01, updateTimestamp);

        (uint index1, uint emissionPerSecond1, uint lastUpdateTimestamp1, ) = rewardsDistributor
            .getRewardsData(asset1, reward1);
        assertEq(index1, 3);
        assertEq(emissionPerSecond1, newEmissionsPerSecond1[0]);
        assertEq(lastUpdateTimestamp1, updateTimestamp);
    }

    function testSetEmissionManager_failsIfNotCalledByEmissionManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(IRewardsDistributor.NotEmissionManager.selector, address(this))
        );
        rewardsDistributor.setEmissionManager(address(this));
    }

    function testSetEmissionManager() public {
        vm.prank(emissionManager);
        vm.expectEmit(true, true, false, false, address(rewardsDistributor));
        emit EmissionManagerUpdated(emissionManager, address(this));
        rewardsDistributor.setEmissionManager(address(this));

        address newEmissionManager = rewardsDistributor.getEmissionManager();
        assertEq(newEmissionManager, address(this));
    }

    function testCanUpdateCarbonRewardDistribution_failsForNonExistentDistribution() public {
        address reward = address(77);

        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.DistributionNonExistent.selector,
                asset0,
                reward
            )
        );
        rewardsDistributor.canUpdateCarbonRewardDistribution(asset0, reward);
    }

    function testCanUpdateCarbonRewardDistribution() public {
        vm.prank(emissionManager);
        rewardsDistributor.setDistributionEnd(asset0, reward00, 0);
        bool canUpdate0 = rewardsDistributor.canUpdateCarbonRewardDistribution(asset0, reward00);
        assertEq(canUpdate0, false);

        vm.prank(emissionManager);
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE);

        vm.warp(CURRENT_DATE - 1 seconds);
        bool canUpdate1 = rewardsDistributor.canUpdateCarbonRewardDistribution(asset0, reward00);
        assertEq(canUpdate1, false);

        vm.warp(CURRENT_DATE);
        bool canUpdate2 = rewardsDistributor.canUpdateCarbonRewardDistribution(asset0, reward00);
        assertEq(canUpdate2, true);

        vm.warp(CURRENT_DATE + 1 weeks - 1 seconds);
        bool canUpdate3 = rewardsDistributor.canUpdateCarbonRewardDistribution(asset0, reward00);
        assertEq(canUpdate3, true);

        vm.warp(CURRENT_DATE + 1 weeks);
        bool canUpdate4 = rewardsDistributor.canUpdateCarbonRewardDistribution(asset0, reward00);
        assertEq(canUpdate4, false);
    }

    function testUpdateCarbonRewardDistribution_failsIfNotCalledByEmissionManager() public {
        address[] memory assets = new address[](1);
        address[] memory rewards = new address[](1);
        uint[] memory rewardAmounts = new uint[](1);

        assets[0] = asset0;
        rewards[0] = reward00;
        rewardAmounts[0] = 100;

        vm.expectRevert(
            abi.encodeWithSelector(IRewardsDistributor.NotEmissionManager.selector, address(this))
        );
        rewardsDistributor.updateCarbonRewardDistribution(assets, rewards, rewardAmounts);
    }

    function testUpdateCarbonRewardDistribution_failsForInvalidInput() public {
        vm.startPrank(emissionManager);
        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidInput.selector));
        rewardsDistributor.updateCarbonRewardDistribution(
            new address[](0),
            new address[](1),
            new uint[](1)
        );

        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidInput.selector));
        rewardsDistributor.updateCarbonRewardDistribution(
            new address[](1),
            new address[](0),
            new uint[](1)
        );

        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidInput.selector));
        rewardsDistributor.updateCarbonRewardDistribution(
            new address[](1),
            new address[](1),
            new uint[](0)
        );
        vm.stopPrank();
    }

    function testUpdateCarbonRewardDistribution_failsForNonExistentDistribution() public {
        address[] memory assets = new address[](1);
        address[] memory rewards = new address[](1);
        uint[] memory rewardAmounts = new uint[](1);

        assets[0] = asset0;
        rewards[0] = address(77);
        rewardAmounts[0] = 100;

        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.UpdateDistributionNotApplicable.selector,
                asset0,
                address(77)
            )
        );
        vm.prank(emissionManager);
        rewardsDistributor.updateCarbonRewardDistribution(assets, rewards, rewardAmounts);
    }

    function testUpdateCarbonRewardDistribution() public {
        uint32 updateTimestamp = CURRENT_DATE + 1 weeks;

        address[] memory assets = new address[](2);
        address[] memory rewards = new address[](2);
        uint[] memory rewardAmounts = new uint[](2);

        assets[0] = asset0;
        rewards[0] = reward00;
        rewardAmounts[0] = 10e18;
        assets[1] = asset1;
        rewards[1] = reward1;
        rewardAmounts[1] = 12e18;

        vm.startPrank(emissionManager);
        rewardsDistributor.setDistributionEnd(asset0, reward00, updateTimestamp);
        rewardsDistributor.setDistributionEnd(asset1, reward1, updateTimestamp);

        uint32 secondsTillNextDistributionEnd = 100 seconds;
        uint32 callTimeStamp = updateTimestamp + 1 weeks - secondsTillNextDistributionEnd;
        vm.warp(callTimeStamp);
        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(
            asset0,
            reward00,
            0,
            10e18 / secondsTillNextDistributionEnd,
            updateTimestamp,
            updateTimestamp + 1 weeks,
            0
        );
        vm.expectEmit(true, true, false, true, address(rewardsDistributor));
        emit AssetConfigUpdated(
            asset1,
            reward1,
            0,
            12e18 / secondsTillNextDistributionEnd,
            updateTimestamp,
            updateTimestamp + 1 weeks,
            0
        );
        rewardsDistributor.updateCarbonRewardDistribution(assets, rewards, rewardAmounts);

        (
            uint index,
            uint emissionPerSecond,
            uint lastUpdateTimestamp,
            uint distributionEnd
        ) = rewardsDistributor.getRewardsData(asset0, reward00);
        assertEq(index, 0);
        assertEq(emissionPerSecond, 10e18 / secondsTillNextDistributionEnd);
        assertEq(lastUpdateTimestamp, callTimeStamp);
        assertEq(distributionEnd, updateTimestamp + 1 weeks);

        (index, emissionPerSecond, lastUpdateTimestamp, distributionEnd) = rewardsDistributor
            .getRewardsData(asset1, reward1);
        assertEq(index, 0);
        assertEq(emissionPerSecond, 12e18 / secondsTillNextDistributionEnd);
        assertEq(lastUpdateTimestamp, callTimeStamp);
        assertEq(distributionEnd, updateTimestamp + 1 weeks);
    }
}
