// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../BaseTest.sol";
import "../../contracts/interfaces/manager/IWeeklyCarbonRewardsManager.sol";
import "../../contracts/interfaces/rewards/IRewardsController.sol";
import "../../contracts/rewards/EmissionManager.sol";
import "../../contracts/SolidWorldManager.sol";
import "../../contracts/rewards/RewardsController.sol";

abstract contract BaseEmissionManagerTest is BaseTest {
    uint32 constant CURRENT_DATE = 1666016743;

    event EmissionAdminUpdated(
        address indexed reward,
        address indexed oldAdmin,
        address indexed newAdmin
    );
    event RewardsControllerUpdated(address indexed newRewardsController);
    event CarbonRewardsManagerUpdated(address indexed newCarbonRewardsManager);

    EmissionManager emissionManager;
    address carbonRewardsManager;
    address controller;
    address owner;
    address rewardsVault;
    address emissionAdmin;

    function setUp() public {
        vm.warp(CURRENT_DATE);

        owner = vm.addr(7);
        carbonRewardsManager = vm.addr(11);
        controller = vm.addr(10);
        rewardsVault = vm.addr(1);
        emissionAdmin = vm.addr(119);
        emissionManager = new EmissionManager();

        _mockRewardsController();
        _setupEmissionManager();
        _labelAccounts();
    }

    function _labelAccounts() private {
        vm.label(address(emissionManager), "EmissionManager");
        vm.label(carbonRewardsManager, "CarbonRewardsManager");
        vm.label(controller, "RewardsController");
        vm.label(owner, "Owner");
        vm.label(rewardsVault, "RewardsVault");
        vm.label(emissionAdmin, "EmissionAdmin");
    }

    function _setupEmissionManager() private {
        _expectEmitCarbonRewardsManagerUpdated(carbonRewardsManager);
        _expectEmitRewardsControllerUpdated(controller);
        emissionManager.setup(carbonRewardsManager, controller, owner);
    }

    function _expectEmitCarbonRewardsManagerUpdated(address newCarbonRewardsManager) internal {
        vm.expectEmit(true, false, false, false, address(emissionManager));
        emit CarbonRewardsManagerUpdated(newCarbonRewardsManager);
    }

    function _expectEmitRewardsControllerUpdated(address newController) internal {
        vm.expectEmit(true, false, false, false, address(emissionManager));
        emit RewardsControllerUpdated(newController);
    }

    function _expectEmitEmissionAdminUpdated(address reward) internal {
        vm.expectEmit(true, true, true, false, address(emissionManager));
        emit EmissionAdminUpdated(reward, address(0), emissionAdmin);
    }

    function _mockRewardsController() private {
        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsController.getRewardsVault.selector),
            abi.encode(rewardsVault)
        );
        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsController.setRewardOracle.selector),
            abi.encode()
        );
        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsController.configureAssets.selector),
            abi.encode()
        );
        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsDistributor.setDistributionEnd.selector),
            abi.encode()
        );
        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsDistributor.setEmissionPerSecond.selector),
            abi.encode()
        );
        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsDistributor.setEmissionManager.selector),
            abi.encode()
        );
        vm.mockCall(
            controller,
            abi.encodeWithSelector(IRewardsController.setClaimer.selector),
            abi.encode()
        );
    }

    function _makeTestDistributionConfigAndEmpowerEmissionAdmin()
        internal
        returns (RewardsDataTypes.DistributionConfig[] memory config)
    {
        config = new RewardsDataTypes.DistributionConfig[](2);
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

        vm.startPrank(owner);
        emissionManager.setEmissionAdmin(config[0].reward, emissionAdmin);
        emissionManager.setEmissionAdmin(config[1].reward, emissionAdmin);
        vm.stopPrank();
    }

    function _makeTestRewardsAndEmissionsPerSecondAndEmpowerEmissionAdmin()
        internal
        returns (address[] memory rewards, uint88[] memory emissionsPerSecond)
    {
        rewards = new address[](2);
        rewards[0] = vm.addr(113);
        rewards[1] = vm.addr(116);

        emissionsPerSecond = new uint88[](2);
        emissionsPerSecond[0] = 100;
        emissionsPerSecond[1] = 200;

        vm.startPrank(owner);
        emissionManager.setEmissionAdmin(rewards[0], emissionAdmin);
        emissionManager.setEmissionAdmin(rewards[1], emissionAdmin);
        vm.stopPrank();
    }

    function _expectSetEmissionPerSecondIsCalledOnRewardsController(
        address asset,
        address[] memory rewards,
        uint88[] memory emissionsPerSecond
    ) internal {
        vm.expectCall(
            controller,
            abi.encodeCall(
                IRewardsDistributor.setEmissionPerSecond,
                (asset, rewards, emissionsPerSecond)
            )
        );
    }

    function _expectSetDistributionEndIsCalledOnRewardsController(
        address asset,
        address reward,
        uint32 distributionEnd
    ) internal {
        vm.expectCall(
            controller,
            abi.encodeCall(IRewardsDistributor.setDistributionEnd, (asset, reward, distributionEnd))
        );
    }

    function _expectSetRewardOracleIsCalledOnRewardsController(
        address reward,
        IEACAggregatorProxy rewardOracle
    ) internal {
        vm.expectCall(
            controller,
            abi.encodeCall(IRewardsController.setRewardOracle, (reward, rewardOracle))
        );
    }

    function _expectConfigureAssetsIsCalledOnRewardsController(
        RewardsDataTypes.DistributionConfig[] memory config
    ) internal {
        vm.expectCall(controller, abi.encodeCall(IRewardsController.configureAssets, config));
    }

    function _expectSetClaimerIsCalledOnRewardsController(address user, address claimer) internal {
        vm.expectCall(controller, abi.encodeCall(IRewardsController.setClaimer, (user, claimer)));
    }

    function _expectSetEmissionManagerIsCalledOnRewardsController(address newEmissionManager)
        internal
    {
        vm.expectCall(
            controller,
            abi.encodeCall(IRewardsDistributor.setEmissionManager, newEmissionManager)
        );
    }

    function _expectProperMethodsAreCalledDuringRewardDistributionUpdate(
        address[] memory assets,
        uint[] memory categoryIds,
        address[] memory carbonRewards,
        uint[] memory rewardAmounts,
        uint[] memory feeAmounts
    ) internal {
        vm.mockCall(
            carbonRewardsManager,
            abi.encodeWithSelector(IWeeklyCarbonRewardsManager.computeWeeklyCarbonRewards.selector),
            abi.encode(carbonRewards, rewardAmounts, feeAmounts)
        );
        vm.expectCall(
            controller,
            abi.encodeCall(
                IRewardsDistributor.updateCarbonRewardDistribution,
                (assets, carbonRewards, rewardAmounts)
            )
        );
        vm.expectCall(
            carbonRewardsManager,
            abi.encodeCall(
                IWeeklyCarbonRewardsManager.mintWeeklyCarbonRewards,
                (categoryIds, carbonRewards, rewardAmounts, feeAmounts, rewardsVault)
            )
        );
    }
}
