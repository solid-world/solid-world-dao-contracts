pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/interfaces/rewards/IRewardsController.sol";
import "../../contracts/rewards/RewardsController.sol";

contract RewardsControllerTest is Test {
    event AssetConfigUpdated(
        address indexed asset,
        address indexed reward,
        uint256 oldEmission,
        uint256 newEmission,
        uint256 oldDistributionEnd,
        uint256 newDistributionEnd,
        uint256 assetIndex
    );
    event RewardOracleUpdated(address indexed reward, address indexed rewardOracle);
    event ClaimerSet(address indexed user, address indexed claimer);

    uint32 constant CURRENT_DATE = 1666016743;

    IRewardsController rewardsController;
    address solidStakingViewActions;
    address rewardsVault;
    address emissionManager;

    function setUp() public {
        vm.warp(CURRENT_DATE);

        solidStakingViewActions = vm.addr(1);
        rewardsVault = vm.addr(2);
        emissionManager = vm.addr(3);

        rewardsController = new RewardsController();
        RewardsController(address(rewardsController)).setup(
            ISolidStakingViewActions(solidStakingViewActions),
            rewardsVault,
            emissionManager
        );

        vm.label(address(rewardsController), "rewardsController");
        vm.label(rewardsVault, "rewardsVault");
        vm.label(emissionManager, "emissionManager");
    }

    function testConfigureAssets_failsIfNotEmissionManager() public {
        address notEmissionManager = vm.addr(4);
        vm.prank(notEmissionManager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.NotEmissionManager.selector,
                notEmissionManager
            )
        );
        rewardsController.configureAssets(new RewardsDataTypes.RewardsConfigInput[](0));
    }

    function testConfigureAssets_failsForInvalidDecimals() public {
        RewardsDataTypes.RewardsConfigInput[]
            memory config = new RewardsDataTypes.RewardsConfigInput[](2);
        config[0].reward = vm.addr(4);
        config[0].asset = vm.addr(5);
        config[0].emissionPerSecond = 100;
        config[0].distributionEnd = CURRENT_DATE;
        config[0].rewardOracle = IEACAggregatorProxy(vm.addr(6));

        config[1].reward = vm.addr(7);
        config[1].asset = vm.addr(8);
        config[1].emissionPerSecond = 200;
        config[1].distributionEnd = CURRENT_DATE;
        config[1].rewardOracle = IEACAggregatorProxy(vm.addr(9));

        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, config[0].asset),
            abi.encode(1000)
        );
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, config[1].asset),
            abi.encode(2000)
        );
        vm.mockCall(
            address(config[0].rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(15)
        );
        vm.mockCall(
            address(config[1].rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(15)
        );
        vm.mockCall(
            config[0].asset,
            abi.encodeWithSelector(IERC20Metadata.decimals.selector),
            abi.encode(18)
        );
        vm.mockCall(
            config[1].asset,
            abi.encodeWithSelector(IERC20Metadata.decimals.selector),
            abi.encode(0)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.InvalidAssetDecimals.selector,
                config[1].asset
            )
        );
        vm.prank(emissionManager);
        rewardsController.configureAssets(config);
    }

    function testConfigureAssets() public {
        RewardsDataTypes.RewardsConfigInput[]
            memory config = new RewardsDataTypes.RewardsConfigInput[](2);
        config[0].reward = vm.addr(4);
        config[0].asset = vm.addr(5);
        config[0].emissionPerSecond = 100;
        config[0].distributionEnd = CURRENT_DATE;
        config[0].rewardOracle = IEACAggregatorProxy(vm.addr(6));

        config[1].reward = vm.addr(7);
        config[1].asset = vm.addr(8);
        config[1].emissionPerSecond = 200;
        config[1].distributionEnd = CURRENT_DATE;
        config[1].rewardOracle = IEACAggregatorProxy(vm.addr(9));

        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, config[0].asset),
            abi.encode(1000)
        );
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, config[1].asset),
            abi.encode(2000)
        );
        vm.mockCall(
            address(config[0].rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(15)
        );
        vm.mockCall(
            address(config[1].rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(15)
        );
        vm.mockCall(
            config[0].asset,
            abi.encodeWithSelector(IERC20Metadata.decimals.selector),
            abi.encode(18)
        );
        vm.mockCall(
            config[1].asset,
            abi.encodeWithSelector(IERC20Metadata.decimals.selector),
            abi.encode(18)
        );
        vm.expectEmit(true, true, false, false, address(rewardsController));
        emit AssetConfigUpdated(config[0].asset, config[0].reward, 0, 0, 0, 0, 0);
        vm.prank(emissionManager);
        rewardsController.configureAssets(config);

        assertEq(
            rewardsController.getRewardOracle(config[0].reward),
            address(config[0].rewardOracle)
        );
        assertEq(
            rewardsController.getRewardOracle(config[1].reward),
            address(config[1].rewardOracle)
        );
    }

    function testSetRewardOracle_failsForInvalidRewardOracle() public {
        address reward = vm.addr(4);
        IEACAggregatorProxy rewardOracle = IEACAggregatorProxy(vm.addr(5));

        vm.mockCall(
            address(rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(0)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsController.InvalidRewardOracle.selector,
                reward,
                vm.addr(5)
            )
        );
        vm.prank(emissionManager);
        rewardsController.setRewardOracle(reward, rewardOracle);
    }

    function testSetRewardOracle_failsIfNotEmissionManager() public {
        address notEmissionManager = vm.addr(4);
        vm.prank(notEmissionManager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.NotEmissionManager.selector,
                notEmissionManager
            )
        );
        rewardsController.setRewardOracle(vm.addr(3), IEACAggregatorProxy(vm.addr(4)));
    }

    function testSetRewardOracle() public {
        address reward = vm.addr(4);
        IEACAggregatorProxy rewardOracle = IEACAggregatorProxy(vm.addr(5));

        vm.mockCall(
            address(rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(15)
        );
        vm.expectEmit(true, true, false, false, address(rewardsController));
        emit RewardOracleUpdated(reward, address(rewardOracle));
        vm.prank(emissionManager);
        rewardsController.setRewardOracle(reward, rewardOracle);

        assertEq(rewardsController.getRewardOracle(reward), address(rewardOracle));
    }

    function testSetClaimer_failsIfNotEmissionManager() public {
        address notEmissionManager = vm.addr(4);
        vm.prank(notEmissionManager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.NotEmissionManager.selector,
                notEmissionManager
            )
        );
        rewardsController.setClaimer(vm.addr(3), vm.addr(4));
    }

    function testSetClaimer() public {
        address claimer = vm.addr(4);
        address user = vm.addr(5);

        vm.expectEmit(true, true, false, false, address(rewardsController));
        emit ClaimerSet(user, claimer);
        vm.prank(emissionManager);
        rewardsController.setClaimer(user, claimer);

        assertEq(rewardsController.getClaimer(user), claimer);
    }

    function testHandleAction_failsIfNotCalledBySolidStaking() public {
        address notSolidStaking = vm.addr(4);
        vm.expectRevert(
            abi.encodeWithSelector(IRewardsController.NotSolidStaking.selector, notSolidStaking)
        );
        vm.prank(notSolidStaking);
        rewardsController.handleAction(vm.addr(5), vm.addr(6), 0, 0);
    }

    function testClaimAllRewards_failsForInvalidToAddress() public {
        address[] memory assets = new address[](0);
        address invalidTo = address(0);
        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidInput.selector));
        rewardsController.claimAllRewards(assets, invalidTo);
    }

    function testClaimAllRewardsOnBehalf_failsForInvalidInputs() public {
        address[] memory assets = new address[](0);
        address invalidTo = address(0);
        address invalidOnBehalfOf = address(0);
        address okOnBehalfOf = vm.addr(4);
        address okTo = vm.addr(5);

        vm.startPrank(emissionManager);
        rewardsController.setClaimer(okOnBehalfOf, address(this));
        rewardsController.setClaimer(invalidOnBehalfOf, address(this));
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidInput.selector));
        rewardsController.claimAllRewardsOnBehalf(assets, invalidOnBehalfOf, invalidTo);

        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidInput.selector));
        rewardsController.claimAllRewardsOnBehalf(assets, okOnBehalfOf, invalidTo);

        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidInput.selector));
        rewardsController.claimAllRewardsOnBehalf(assets, invalidOnBehalfOf, okTo);
    }

    function testClaimAllRewardsOnBehalf_failsForUnauthorizedClaimer() public {
        address[] memory assets = new address[](0);
        address onBehalfOf = vm.addr(4);
        address to = vm.addr(5);
        address unauthorizedClaimer = vm.addr(6);

        vm.prank(emissionManager);
        rewardsController.setClaimer(onBehalfOf, address(this));

        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsController.UnauthorizedClaimer.selector,
                unauthorizedClaimer,
                onBehalfOf
            )
        );
        vm.prank(unauthorizedClaimer);
        rewardsController.claimAllRewardsOnBehalf(assets, onBehalfOf, to);

        rewardsController.claimAllRewardsOnBehalf(assets, onBehalfOf, to); //should not revert
        vm.prank(solidStakingViewActions);
        rewardsController.claimAllRewardsOnBehalf(assets, onBehalfOf, to); //should not revert
    }
}
