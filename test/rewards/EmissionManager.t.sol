pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../../contracts/interfaces/manager/IWeeklyCarbonRewardsManager.sol";
import "../../contracts/interfaces/rewards/IRewardsController.sol";
import "../../contracts/rewards/EmissionManager.sol";
import "../../contracts/SolidWorldManager.sol";
import "../../contracts/rewards/RewardsController.sol";

contract EmissionManagerTest is Test {
    event EmissionAdminUpdated(
        address indexed reward,
        address indexed oldAdmin,
        address indexed newAdmin
    );

    EmissionManager emissionManager;
    address carbonRewardsManager;
    address controller;
    address owner;
    address rewardsVault;

    function setUp() public {
        owner = vm.addr(7);
        carbonRewardsManager = vm.addr(11);
        controller = vm.addr(10);
        rewardsVault = vm.addr(1);

        emissionManager = new EmissionManager();
        emissionManager.setup(
            IWeeklyCarbonRewardsManager(carbonRewardsManager),
            IRewardsController(controller),
            owner
        );

        vm.label(address(emissionManager), "emissionManager");
        vm.label(carbonRewardsManager, "carbonRewardsManager");
        vm.label(controller, "controller");
        vm.label(owner, "owner");
        vm.label(rewardsVault, "rewardsVault");
    }

    function testRecurrentSetup() public {
        assertEq(emissionManager.owner(), owner);
        assertEq(emissionManager.getCarbonRewardsManager(), carbonRewardsManager);
        assertEq(address(emissionManager.getRewardsController()), controller);

        vm.expectRevert(abi.encodeWithSelector(PostConstruct.AlreadyInitialized.selector));
        emissionManager.setup(
            IWeeklyCarbonRewardsManager(carbonRewardsManager),
            IRewardsController(controller),
            owner
        );
    }

    function testConfigureAssets() public {
        RewardsDataTypes.RewardsConfigInput[]
            memory config = new RewardsDataTypes.RewardsConfigInput[](2);
        config[0].reward = vm.addr(113);
        config[0].asset = vm.addr(114);
        config[0].rewardOracle = IEACAggregatorProxy(vm.addr(115));
        config[0].emissionPerSecond = 100;
        config[0].distributionEnd = 1000;
        config[0].totalStaked = 10000;

        config[1].reward = vm.addr(116);
        config[1].asset = vm.addr(117);
        config[1].rewardOracle = IEACAggregatorProxy(vm.addr(118));
        config[1].emissionPerSecond = 200;
        config[1].distributionEnd = 2000;
        config[1].totalStaked = 20000;

        address emissionAdmin = vm.addr(119);
        vm.startPrank(owner);
        emissionManager.setEmissionAdmin(config[0].reward, emissionAdmin);
        emissionManager.setEmissionAdmin(config[1].reward, emissionAdmin);
        vm.stopPrank();

        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsController.configureAssets.selector),
            abi.encode()
        );
        vm.expectCall(controller, abi.encodeCall(IRewardsController.configureAssets, config));
        vm.prank(emissionAdmin);
        emissionManager.configureAssets(config);
    }

    function testConfigureAssets_failsIfNotCalledByEmissionAdmin() public {
        RewardsDataTypes.RewardsConfigInput[]
            memory config = new RewardsDataTypes.RewardsConfigInput[](2);
        config[0].reward = vm.addr(113);
        config[0].asset = vm.addr(114);
        config[0].rewardOracle = IEACAggregatorProxy(vm.addr(115));
        config[0].emissionPerSecond = 100;
        config[0].distributionEnd = 1000;
        config[0].totalStaked = 10000;

        config[1].reward = vm.addr(116);
        config[1].asset = vm.addr(117);
        config[1].rewardOracle = IEACAggregatorProxy(vm.addr(118));
        config[1].emissionPerSecond = 200;
        config[1].distributionEnd = 2000;
        config[1].totalStaked = 20000;

        address emissionAdmin = vm.addr(119);
        vm.prank(owner);
        emissionManager.setEmissionAdmin(config[0].reward, emissionAdmin);

        vm.expectRevert(
            abi.encodeWithSelector(
                IEmissionManager.NotEmissionAdmin.selector,
                emissionAdmin,
                config[1].reward
            )
        );
        vm.prank(emissionAdmin);
        emissionManager.configureAssets(config);
    }

    function testSetRewardOracle_failsIfNotCalledByEmissionAdmin() public {
        address notAnAdmin = vm.addr(119);
        address reward = vm.addr(113);
        IEACAggregatorProxy rewardOracle = IEACAggregatorProxy(vm.addr(115));

        vm.expectRevert(
            abi.encodeWithSelector(IEmissionManager.NotEmissionAdmin.selector, notAnAdmin, reward)
        );
        vm.prank(notAnAdmin);
        emissionManager.setRewardOracle(reward, rewardOracle);
    }

    function testSetRewardOracle() public {
        address emissionAdmin = vm.addr(119);
        address reward = vm.addr(113);
        IEACAggregatorProxy rewardOracle = IEACAggregatorProxy(vm.addr(115));

        vm.prank(owner);
        emissionManager.setEmissionAdmin(reward, emissionAdmin);

        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsController.setRewardOracle.selector),
            abi.encode()
        );
        vm.expectCall(
            controller,
            abi.encodeCall(IRewardsController.setRewardOracle, (reward, rewardOracle))
        );
        vm.prank(emissionAdmin);
        emissionManager.setRewardOracle(reward, rewardOracle);
    }

    function testSetDistributionEnd_failsIfNotCalledByEmissionAdmin() public {
        address notAnAdmin = vm.addr(119);
        address reward = vm.addr(113);
        address asset = vm.addr(114);
        uint32 distributionEnd = 1000;

        vm.expectRevert(
            abi.encodeWithSelector(IEmissionManager.NotEmissionAdmin.selector, notAnAdmin, reward)
        );
        vm.prank(notAnAdmin);
        emissionManager.setDistributionEnd(asset, reward, distributionEnd);
    }

    function testSetDistributionEnd() public {
        address emissionAdmin = vm.addr(119);
        address reward = vm.addr(113);
        address asset = vm.addr(114);
        uint32 distributionEnd = 1000;

        vm.prank(owner);
        emissionManager.setEmissionAdmin(reward, emissionAdmin);

        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsDistributor.setDistributionEnd.selector),
            abi.encode()
        );
        vm.expectCall(
            controller,
            abi.encodeCall(IRewardsDistributor.setDistributionEnd, (asset, reward, distributionEnd))
        );
        vm.prank(emissionAdmin);
        emissionManager.setDistributionEnd(asset, reward, distributionEnd);
    }

    function testSetEmissionPerSecond_failsIfNotCalledByEmissionAdmin() public {
        address notAnAdmin = vm.addr(119);
        address asset = vm.addr(114);
        address[] memory rewards = new address[](2);
        uint88[] memory emissionsPerSecond = new uint88[](2);

        rewards[0] = vm.addr(113);
        rewards[1] = vm.addr(116);
        emissionsPerSecond[0] = 100;
        emissionsPerSecond[1] = 200;

        vm.prank(owner);
        emissionManager.setEmissionAdmin(rewards[0], notAnAdmin);

        vm.expectRevert(
            abi.encodeWithSelector(
                IEmissionManager.NotEmissionAdmin.selector,
                notAnAdmin,
                rewards[1]
            )
        );
        vm.prank(notAnAdmin);
        emissionManager.setEmissionPerSecond(asset, rewards, emissionsPerSecond);
    }

    function testSetEmissionPerSecond() public {
        address emissionAdmin = vm.addr(119);
        address asset = vm.addr(114);
        address[] memory rewards = new address[](2);
        uint88[] memory emissionsPerSecond = new uint88[](2);

        rewards[0] = vm.addr(113);
        rewards[1] = vm.addr(116);
        emissionsPerSecond[0] = 100;
        emissionsPerSecond[1] = 200;

        vm.startPrank(owner);
        emissionManager.setEmissionAdmin(rewards[0], emissionAdmin);
        emissionManager.setEmissionAdmin(rewards[1], emissionAdmin);
        vm.stopPrank();

        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsDistributor.setEmissionPerSecond.selector),
            abi.encode()
        );
        vm.expectCall(
            controller,
            abi.encodeCall(
                IRewardsDistributor.setEmissionPerSecond,
                (asset, rewards, emissionsPerSecond)
            )
        );
        vm.prank(emissionAdmin);
        emissionManager.setEmissionPerSecond(asset, rewards, emissionsPerSecond);
    }

    function testUpdateCarbonRewardDistribution() public {
        address[] memory assets = new address[](1);
        assets[0] = vm.addr(2);
        uint[] memory categoryIds = new uint[](1);
        categoryIds[0] = 1;

        address[] memory carbonRewards = new address[](1);
        carbonRewards[0] = vm.addr(3);
        uint[] memory rewardAmounts = new uint[](1);
        rewardAmounts[0] = 100;

        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsController.getRewardsVault.selector),
            abi.encode(rewardsVault)
        );
        vm.mockCall(
            carbonRewardsManager,
            abi.encodeWithSelector(IWeeklyCarbonRewardsManager.computeWeeklyCarbonRewards.selector),
            abi.encode(carbonRewards, rewardAmounts)
        );
        vm.expectCall(
            controller,
            abi.encodeCall(
                IRewardsDistributor.updateRewardDistribution,
                (assets, carbonRewards, rewardAmounts)
            )
        );
        vm.expectCall(
            carbonRewardsManager,
            abi.encodeCall(
                IWeeklyCarbonRewardsManager.mintWeeklyCarbonRewards,
                (carbonRewards, rewardAmounts, rewardsVault)
            )
        );
        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);
    }

    function testSetClaimer_failsIfNotCalledByOwner() public {
        address notOwner = vm.addr(119);
        address claimer = vm.addr(115);
        address user = vm.addr(116);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(notOwner);
        emissionManager.setClaimer(user, claimer);
    }

    function testSetClaimer() public {
        address claimer = vm.addr(115);
        address user = vm.addr(116);

        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsController.setClaimer.selector),
            abi.encode()
        );
        vm.expectCall(controller, abi.encodeCall(IRewardsController.setClaimer, (user, claimer)));
        vm.prank(owner);
        emissionManager.setClaimer(user, claimer);
    }

    function testSetEmissionManager_failsIfNotCalledByOwner() public {
        address notOwner = vm.addr(119);
        address newEmissionManager = vm.addr(115);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(notOwner);
        emissionManager.setEmissionManager(newEmissionManager);
    }

    function testSetEmissionManager() public {
        address newEmissionManager = vm.addr(115);

        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsDistributor.setEmissionManager.selector),
            abi.encode()
        );
        vm.expectCall(
            controller,
            abi.encodeCall(IRewardsDistributor.setEmissionManager, newEmissionManager)
        );
        vm.prank(owner);
        emissionManager.setEmissionManager(newEmissionManager);
    }

    function testSetEmissionAdmin_failsIfNotCalledByOwner() public {
        address notOwner = vm.addr(119);
        address emissionAdmin = vm.addr(115);
        address reward = vm.addr(116);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(notOwner);
        emissionManager.setEmissionAdmin(reward, emissionAdmin);
    }

    function testSetEmissionAdmin() public {
        address emissionAdmin = vm.addr(115);
        address reward = vm.addr(116);

        vm.expectEmit(true, true, true, false, address(emissionManager));
        emit EmissionAdminUpdated(reward, address(0), emissionAdmin);
        vm.prank(owner);
        emissionManager.setEmissionAdmin(reward, emissionAdmin);

        assertEq(emissionManager.getEmissionAdmin(reward), emissionAdmin);
    }

    function testSetRewardsController_failsIfNotCalledByOwner() public {
        address notOwner = vm.addr(119);
        address newController = vm.addr(115);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(notOwner);
        emissionManager.setRewardsController(newController);
    }

    function testSetRewardsController() public {
        address newController = vm.addr(115);

        vm.prank(owner);
        emissionManager.setRewardsController(newController);

        assertEq(address(emissionManager.getRewardsController()), newController);
    }
}
