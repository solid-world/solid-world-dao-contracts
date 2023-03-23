// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./base-tests/BaseEmissionManager.t.sol";

contract EmissionManagerTest is BaseEmissionManagerTest {
    function testRecurrentSetup() public {
        assertEq(emissionManager.owner(), owner);
        assertEq(emissionManager.getCarbonRewardsManager(), carbonRewardsManager);
        assertEq(address(emissionManager.getRewardsController()), controller);

        _expectRevert_AlreadyInitialized();
        emissionManager.setup(carbonRewardsManager, controller, owner);
    }

    function testConfigureAssets() public {
        RewardsDataTypes.DistributionConfig[]
            memory config = _makeTestDistributionConfigAndEmpowerEmissionAdmin();

        _expectConfigureAssetsIsCalledOnRewardsController(config);
        vm.prank(emissionAdmin);
        emissionManager.configureAssets(config);
    }

    function testConfigureAssets_failsIfNotCalledByEmissionAdmin() public {
        RewardsDataTypes.DistributionConfig[]
            memory config = _makeTestDistributionConfigAndEmpowerEmissionAdmin();

        vm.prank(owner);
        emissionManager.setEmissionAdmin(config[1].reward, vm.addr(777));

        _expectRevert_NotEmissionAdmin(emissionAdmin, config[1].reward);
        vm.prank(emissionAdmin);
        emissionManager.configureAssets(config);
    }

    function testSetRewardOracle_failsIfEmissionAdminNotEmpowered() public {
        address reward = vm.addr(113);
        IEACAggregatorProxy rewardOracle = IEACAggregatorProxy(vm.addr(115));

        _expectRevert_NotEmissionAdmin(emissionAdmin, reward);
        vm.prank(emissionAdmin);
        emissionManager.setRewardOracle(reward, rewardOracle);
    }

    function testSetRewardOracle() public {
        address reward = vm.addr(113);
        IEACAggregatorProxy rewardOracle = IEACAggregatorProxy(vm.addr(115));

        vm.prank(owner);
        emissionManager.setEmissionAdmin(reward, emissionAdmin);

        _expectSetRewardOracleIsCalledOnRewardsController(reward, rewardOracle);
        vm.prank(emissionAdmin);
        emissionManager.setRewardOracle(reward, rewardOracle);
    }

    function testSetDistributionEnd_failsIfEmissionAdminNotEmpowered() public {
        address reward = vm.addr(113);
        address asset = vm.addr(114);
        uint32 distributionEnd = 1000;

        _expectRevert_NotEmissionAdmin(emissionAdmin, reward);
        vm.prank(emissionAdmin);
        emissionManager.setDistributionEnd(asset, reward, distributionEnd);
    }

    function testSetDistributionEnd() public {
        address asset = vm.addr(114);
        address reward = vm.addr(113);
        uint32 distributionEnd = 1000;

        vm.prank(owner);
        emissionManager.setEmissionAdmin(reward, emissionAdmin);

        _expectSetDistributionEndIsCalledOnRewardsController(asset, reward, distributionEnd);
        vm.prank(emissionAdmin);
        emissionManager.setDistributionEnd(asset, reward, distributionEnd);
    }

    function testSetEmissionPerSecond_failsIfEmissionAdminNotEmpowered() public {
        address asset = vm.addr(114);
        (
            address[] memory rewards,
            uint88[] memory emissionsPerSecond
        ) = _makeTestRewardsAndEmissionsPerSecondAndEmpowerEmissionAdmin();

        vm.prank(owner);
        emissionManager.setEmissionAdmin(rewards[1], vm.addr(777));

        _expectRevert_NotEmissionAdmin(emissionAdmin, rewards[1]);
        vm.prank(emissionAdmin);
        emissionManager.setEmissionPerSecond(asset, rewards, emissionsPerSecond);
    }

    function testSetEmissionPerSecond() public {
        address asset = vm.addr(114);
        (
            address[] memory rewards,
            uint88[] memory emissionsPerSecond
        ) = _makeTestRewardsAndEmissionsPerSecondAndEmpowerEmissionAdmin();

        _expectSetEmissionPerSecondIsCalledOnRewardsController(asset, rewards, emissionsPerSecond);
        vm.prank(emissionAdmin);
        emissionManager.setEmissionPerSecond(asset, rewards, emissionsPerSecond);
    }

    function testUpdateCarbonRewardDistribution_failsInputsOfDifferentLengths() public {
        _expectRevert_InvalidInput();
        emissionManager.updateCarbonRewardDistribution(new address[](2), new uint[](1));
    }

    function testUpdateCarbonRewardDistribution() public {
        address[] memory assets = new address[](1);
        assets[0] = vm.addr(2);
        uint[] memory categoryIds = new uint[](1);
        categoryIds[0] = 1;

        address[] memory carbonRewards = new address[](1);
        carbonRewards[0] = vm.addr(3);
        uint[] memory rewardAmounts = new uint[](1);
        rewardAmounts[0] = 90;
        uint[] memory feeAmounts = new uint[](1);
        feeAmounts[0] = 10;

        _expectProperMethodsAreCalledDuringRewardDistributionUpdate(
            assets,
            categoryIds,
            carbonRewards,
            rewardAmounts,
            feeAmounts
        );
        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);
    }

    function testSetClaimer_failsIfNotCalledByOwner() public {
        address claimer = vm.addr(115);
        address user = vm.addr(116);

        _expectRevert_NotOwner();
        vm.prank(emissionAdmin);
        emissionManager.setClaimer(user, claimer);
    }

    function testSetClaimer() public {
        address user = vm.addr(116);
        address claimer = vm.addr(115);

        _expectSetClaimerIsCalledOnRewardsController(user, claimer);
        vm.prank(owner);
        emissionManager.setClaimer(user, claimer);
    }

    function testSetEmissionManager_failsIfNotCalledByOwner() public {
        address newEmissionManager = vm.addr(115);

        _expectRevert_NotOwner();
        vm.prank(emissionAdmin);
        emissionManager.setEmissionManager(newEmissionManager);
    }

    function testSetEmissionManager() public {
        address newEmissionManager = vm.addr(115);

        _expectSetEmissionManagerIsCalledOnRewardsController(newEmissionManager);
        vm.prank(owner);
        emissionManager.setEmissionManager(newEmissionManager);
    }

    function testSetEmissionAdmin_failsIfNotCalledByOwner() public {
        address reward = vm.addr(116);

        _expectRevert_NotOwner();
        vm.prank(emissionAdmin);
        emissionManager.setEmissionAdmin(reward, emissionAdmin);
    }

    function testSetEmissionAdmin() public {
        address reward = vm.addr(116);

        _expectEmitEmissionAdminUpdated(reward);
        vm.prank(owner);
        emissionManager.setEmissionAdmin(reward, emissionAdmin);

        assertEq(emissionManager.getEmissionAdmin(reward), emissionAdmin);
    }

    function testSetRewardsController_failsIfNotCalledByOwner() public {
        address newController = vm.addr(115);

        _expectRevert_NotOwner();
        vm.prank(emissionAdmin);
        emissionManager.setRewardsController(newController);
    }

    function testSetRewardsController() public {
        address newController = vm.addr(115);

        vm.prank(owner);
        _expectEmitRewardsControllerUpdated(newController);
        emissionManager.setRewardsController(newController);

        assertEq(address(emissionManager.getRewardsController()), newController);
    }

    function testCarbonRewardsManager_failsIfNotCalledByOwner() public {
        address newCarbonRewardsManager = vm.addr(115);

        _expectRevert_NotOwner();
        vm.prank(emissionAdmin);
        emissionManager.setCarbonRewardsManager(newCarbonRewardsManager);
    }

    function testSetCarbonRewardsManager() public {
        address newCarbonRewardsManager = vm.addr(115);

        vm.prank(owner);
        _expectEmitCarbonRewardsManagerUpdated(newCarbonRewardsManager);
        emissionManager.setCarbonRewardsManager(newCarbonRewardsManager);

        assertEq(address(emissionManager.getCarbonRewardsManager()), newCarbonRewardsManager);
    }
}
