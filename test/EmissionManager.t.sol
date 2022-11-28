pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../contracts/interfaces/manager/IWeeklyCarbonRewardsManager.sol";
import "../contracts/interfaces/rewards/IRewardsController.sol";
import "../contracts/rewards/EmissionManager.sol";
import "../contracts/SolidWorldManager.sol";
import "../contracts/rewards/RewardsController.sol";

contract EmissionManagerTest is Test {
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
}
