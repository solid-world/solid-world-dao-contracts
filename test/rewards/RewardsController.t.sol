// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./base-tests/BaseRewardsController.sol";

contract RewardsControllerTest is BaseRewardsControllerTest {
    function testConfigureAssets_failsIfNotEmissionManager() public {
        vm.prank(arbitraryAccount);
        _expectRevert_NotEmissionManager(arbitraryAccount);
        rewardsController.configureAssets(new RewardsDataTypes.DistributionConfig[](0));
    }

    function testConfigureAssets_failsForInvalidAssetDecimals() public {
        _mockInvalidAssetDecimals();
        _expectRevert_InvalidAssetDecimals(testConfig[1].asset);
        vm.prank(emissionManager);
        _configureAssets();
    }

    function testConfigureAssets() public {
        _mockValidAssetDecimals();
        _expectEmitAssetConfigUpdated(testConfig[0].asset, testConfig[0].reward);
        _expectEmitAssetConfigUpdated(testConfig[1].asset, testConfig[1].reward);
        vm.prank(emissionManager);
        _configureAssets();

        assertEq(
            rewardsController.getRewardOracle(testConfig[0].reward),
            address(testConfig[0].rewardOracle)
        );
        assertEq(
            rewardsController.getRewardOracle(testConfig[1].reward),
            address(testConfig[1].rewardOracle)
        );
    }

    function testSetRewardOracle_failsForInvalidRewardOracle() public {
        address reward = vm.addr(4);
        IEACAggregatorProxy rewardOracle = _makeInvalidOracle();

        _expectRevert_InvalidRewardOracle(reward, rewardOracle);
        vm.prank(emissionManager);
        rewardsController.setRewardOracle(reward, rewardOracle);
    }

    function testSetRewardOracle_failsIfNotEmissionManager() public {
        address reward;
        address rewardOracle;

        vm.prank(arbitraryAccount);
        _expectRevert_NotEmissionManager(arbitraryAccount);
        rewardsController.setRewardOracle(reward, IEACAggregatorProxy(rewardOracle));
    }

    function testSetRewardOracle() public {
        address reward = vm.addr(4);
        IEACAggregatorProxy rewardOracle = _makeValidOracle();

        vm.prank(emissionManager);
        _expectEmitRewardOracleUpdated(reward, rewardOracle);
        rewardsController.setRewardOracle(reward, rewardOracle);

        assertEq(rewardsController.getRewardOracle(reward), address(rewardOracle));
    }

    function testSetClaimer_failsIfNotEmissionManager() public {
        address user;
        address claimer;

        vm.prank(arbitraryAccount);
        _expectRevert_NotEmissionManager(arbitraryAccount);
        rewardsController.setClaimer(user, claimer);
    }

    function testSetClaimer() public {
        address claimer = vm.addr(4);
        address user = vm.addr(5);

        vm.prank(emissionManager);
        _expectEmit_ClaimerSet(user, claimer);
        rewardsController.setClaimer(user, claimer);

        assertEq(rewardsController.getClaimer(user), claimer);
    }

    function testSetRewardsVault_failsIfNotEmissionManager() public {
        vm.prank(arbitraryAccount);
        _expectRevert_NotEmissionManager(arbitraryAccount);
        rewardsController.setRewardsVault(rewardsVault);
    }

    function testSetRewardsVault() public {
        address _rewardsVault = vm.addr(4);

        vm.prank(emissionManager);
        _expectEmit_RewardsVaultUpdated(_rewardsVault);
        rewardsController.setRewardsVault(_rewardsVault);

        assertEq(rewardsController.getRewardsVault(), _rewardsVault);
    }

    function testSetSolidStaking_failsIfNotEmissionManager() public {
        vm.prank(arbitraryAccount);
        _expectRevert_NotEmissionManager(arbitraryAccount);
        rewardsController.setSolidStaking(solidStakingViewActions);
    }

    function testSetSolidStaking() public {
        address _solidStaking = vm.addr(4);

        vm.prank(emissionManager);
        _expectEmit_SolidStakingUpdated(_solidStaking);
        rewardsController.setSolidStaking(_solidStaking);

        assertEq(
            address(RewardsController(address(rewardsController)).solidStakingViewActions()),
            _solidStaking
        );
    }

    function testHandleUserStakeChanged_failsIfNotCalledBySolidStaking() public {
        vm.prank(arbitraryAccount);
        _expectRevert_NotSolidStaking(arbitraryAccount);
        rewardsController.handleUserStakeChanged(vm.addr(5), vm.addr(6), 0, 0);
    }

    function testClaimAllRewards_failsForInvalidToAddress() public {
        address[] memory assets = new address[](0);
        address invalidTo = address(0);

        _expectRevert_InvalidInput();
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

        _expectRevert_InvalidInput();
        rewardsController.claimAllRewardsOnBehalf(assets, invalidOnBehalfOf, invalidTo);

        _expectRevert_InvalidInput();
        rewardsController.claimAllRewardsOnBehalf(assets, okOnBehalfOf, invalidTo);

        _expectRevert_InvalidInput();
        rewardsController.claimAllRewardsOnBehalf(assets, invalidOnBehalfOf, okTo);
    }

    function testClaimAllRewardsOnBehalf_failsForUnauthorizedClaimer() public {
        address[] memory assets = new address[](0);
        address onBehalfOf = vm.addr(4);
        address to = vm.addr(5);

        vm.prank(arbitraryAccount);
        _expectRevert_UnauthorizedClaimer(arbitraryAccount, onBehalfOf);
        rewardsController.claimAllRewardsOnBehalf(assets, onBehalfOf, to);
    }

    function testClaimAllRewardsOnBehalf() public {
        address[] memory assets = new address[](0);
        address onBehalfOf = vm.addr(4);
        address to = vm.addr(5);

        vm.prank(emissionManager);
        rewardsController.setClaimer(onBehalfOf, address(this));

        rewardsController.claimAllRewardsOnBehalf(assets, onBehalfOf, to);
    }

    function testClaimAllRewardsOnBehalf_solidStakingIsWhitelisted() public {
        address[] memory assets = new address[](0);
        address onBehalfOf = vm.addr(4);
        address to = vm.addr(5);

        vm.prank(solidStakingViewActions);
        rewardsController.claimAllRewardsOnBehalf(assets, onBehalfOf, to);
    }

    /// @notice copying from storage to memory is not supported ootb
    function _configureAssets() private {
        RewardsDataTypes.DistributionConfig[] memory config = new RewardsDataTypes.DistributionConfig[](2);
        config[0] = testConfig[0];
        config[1] = testConfig[1];
        rewardsController.configureAssets(config);
    }
}
