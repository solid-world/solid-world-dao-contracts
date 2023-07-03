// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./base-tests/BaseRewardsDistributor.sol";

contract RewardsDistributorTest is BaseRewardsDistributorTest {
    function testInitialConfiguration() public {
        _assertInitialFirstDistributionIsCorrect();
        _assertInitialSecondDistributionIsCorrect();
        _assertInitialThirdDistributionIsCorrect();
    }

    function testGetRewardsByAsset() public {
        address[] memory rewards0 = rewardsDistributor.getRewardsByAsset(preset.asset0);
        assertEq(rewards0.length, 2);
        assertEq(rewards0[0], preset.reward00);
        assertEq(rewards0[1], preset.reward01);

        address[] memory rewards1 = rewardsDistributor.getRewardsByAsset(preset.asset1);
        assertEq(rewards1.length, 1);
        assertEq(rewards1[0], preset.reward1);
    }

    function testGetAllRewards() public {
        address[] memory rewards = rewardsDistributor.getAllRewards();
        assertEq(rewards.length, 3);
        assertEq(rewards[0], preset.reward00);
        assertEq(rewards[1], preset.reward1);
        assertEq(rewards[2], preset.reward01);
    }

    function testChangesOfStakeEmitAccruedEvent() public {
        _distributeRewardsForOneWeek(preset.asset0, preset.reward00, preset.emissionPerSecond00);
        vm.warp(PRESET_CURRENT_DATE + preset.accruingPeriod);

        _expectEmitAccrued(
            preset.asset0,
            preset.reward00,
            preset.user,
            preset.distributionIndex00,
            preset.distributionIndex00,
            preset.accruedRewards00
        );
        _simulateUserStaking(preset.asset0, preset.user, preset.userStake, preset.totalStaked);
    }

    function testChangeOfStakeUpdatesDistributionIndex() public {
        _loadDistributionPreset();

        assertEq(_getDistributionIndex(preset.asset0, preset.reward00), preset.distributionIndex00);
        assertEq(_getDistributionIndex(preset.asset0, preset.reward01), preset.distributionIndex01);
        assertEq(_getDistributionIndex(preset.asset1, preset.reward1), preset.distributionIndex1);
    }

    function testChangeOfStakeUpdatesDistributionTimestamp() public {
        _loadDistributionPreset();

        assertEq(_getDistributionUpdateTimestamp(preset.asset0, preset.reward00), preset.updateTimestamp);
        assertEq(_getDistributionUpdateTimestamp(preset.asset0, preset.reward01), preset.updateTimestamp);
    }

    function testChangeOfStakeUpdatesUserIndex() public {
        _loadDistributionPreset();

        assertEq(
            rewardsDistributor.getUserIndex(preset.user, preset.asset0, preset.reward00),
            preset.distributionIndex00
        );
        assertEq(
            rewardsDistributor.getUserIndex(preset.user, preset.asset0, preset.reward01),
            preset.distributionIndex01
        );
        assertEq(
            rewardsDistributor.getUserIndex(preset.user, preset.asset1, preset.reward1),
            preset.distributionIndex1
        );
    }

    function testChangeOfStakeAccruesRewardsForUser() public {
        _loadDistributionPreset();

        assertEq(
            rewardsDistributor.getAccruedRewardAmountForUser(preset.user, preset.reward00),
            preset.accruedRewards00
        );
        assertEq(
            rewardsDistributor.getAccruedRewardAmountForUser(preset.user, preset.reward01),
            preset.accruedRewards01
        );
        assertEq(
            rewardsDistributor.getAccruedRewardAmountForUser(preset.user, preset.reward1),
            preset.accruedRewards1
        );
    }

    function testGetUnclaimedRewardAmountForUserAndAssets_returnsAccruedAndUnrealised() public {
        _loadDistributionPreset();

        // rewards continue to grow another 5 seconds
        vm.warp(PRESET_CURRENT_DATE + preset.accruingPeriod + 5 seconds);
        uint totalRewards = rewardsDistributor.getUnclaimedRewardAmountForUserAndAssets(
            _toArray(preset.asset0),
            preset.user,
            preset.reward00
        );

        assertEq(
            totalRewards,
            _earnedRewards(10, preset.emissionPerSecond00, preset.userStake, preset.totalStaked)
        );
    }

    function testGetAllUnclaimedRewardAmountsForUserAndAssets_rewardsListIsInOrderOfConfiguration() public {
        _loadDistributionPreset();

        // rewards continue to grow another 5 seconds
        vm.warp(PRESET_CURRENT_DATE + preset.accruingPeriod + 5 seconds);
        (address[] memory rewardsList, ) = rewardsDistributor.getAllUnclaimedRewardAmountsForUserAndAssets(
            _toArray(preset.asset0, preset.asset1),
            preset.user
        );

        assertEq(rewardsList.length, 3);
        assertEq(rewardsList[0], preset.reward00);
        assertEq(rewardsList[1], preset.reward1);
        assertEq(rewardsList[2], preset.reward01);
    }

    function testGetAllUnclaimedRewardAmountsForUserAndAssets_userRewardsAreCorrect() public {
        _loadDistributionPreset();

        // rewards continue to grow another 5 seconds
        vm.warp(PRESET_CURRENT_DATE + preset.accruingPeriod + 5 seconds);
        (, uint[] memory unclaimedAmounts) = rewardsDistributor.getAllUnclaimedRewardAmountsForUserAndAssets(
            _toArray(preset.asset0, preset.asset1),
            preset.user
        );

        assertEq(unclaimedAmounts.length, 3);
        assertEq(
            unclaimedAmounts[0],
            _earnedRewards(10, preset.emissionPerSecond00, preset.userStake, preset.totalStaked)
        );
        assertEq(
            unclaimedAmounts[1],
            _earnedRewards(10, preset.emissionPerSecond1, preset.userStake, preset.totalStaked)
        );
        assertEq(
            unclaimedAmounts[2],
            _earnedRewards(10, preset.emissionPerSecond01, preset.userStake, preset.totalStaked)
        );
    }

    function testSetDistributionEnd_failsIfNotCalledByEmissionManager() public {
        _expectRevert_NotEmissionManager();
        rewardsDistributor.setDistributionEnd(preset.asset0, preset.reward00, PRESET_CURRENT_DATE + 1 weeks);
    }

    function testSetDistributionEnd_failsForNonExistentDistribution() public {
        address reward = vm.addr(77);

        vm.prank(emissionManager);
        _expectRevert_DistributionNonExistent(preset.asset0, reward);
        rewardsDistributor.setDistributionEnd(preset.asset0, reward, PRESET_CURRENT_DATE + 1 weeks);
    }

    function testSetDistributionEnd_emitsEvent() public {
        vm.prank(emissionManager);
        _expectEmitAssetConfigUpdated(
            preset.asset1,
            preset.reward1,
            0,
            0,
            PRESET_CURRENT_DATE + 1 seconds,
            PRESET_CURRENT_DATE + 2 weeks,
            0
        );
        rewardsDistributor.setDistributionEnd(preset.asset1, preset.reward1, PRESET_CURRENT_DATE + 2 weeks);
    }

    function testSetDistributionEnd_persistsDistributionEnd() public {
        vm.prank(emissionManager);
        rewardsDistributor.setDistributionEnd(preset.asset1, preset.reward1, PRESET_CURRENT_DATE + 2 weeks);

        uint distributionEnd1 = rewardsDistributor.getDistributionEnd(preset.asset1, preset.reward1);
        assertEq(distributionEnd1, PRESET_CURRENT_DATE + 2 weeks);
    }

    function testSetEmissionPerSecond_failsIfNotCalledByEmissionManager() public {
        _expectRevert_NotEmissionManager();
        rewardsDistributor.setEmissionPerSecond(preset.asset0, new address[](0), new uint88[](0));
    }

    function testSetEmissionPerSecond_failsForInvalidInput() public {
        vm.prank(emissionManager);
        _expectRevert_InvalidInput();
        rewardsDistributor.setEmissionPerSecond(preset.asset0, new address[](2), new uint88[](0));
    }

    function testSetEmissionPerSecond_failsForNonExistentDistribution() public {
        address[] memory rewards = _toArray(vm.addr(77));
        uint88[] memory newEmissionsPerSecond = _toArrayUint88(300);

        vm.prank(emissionManager);
        _expectRevert_DistributionNonExistent(preset.asset0, rewards[0]);
        rewardsDistributor.setEmissionPerSecond(preset.asset0, rewards, newEmissionsPerSecond);
    }

    function testSetEmissionPerSecond_persistsEmissionPerSecond() public {
        address[] memory rewards = _toArray(preset.reward00, preset.reward01);
        uint88[] memory newEmissionsPerSecond = _toArrayUint88(100, 200);

        vm.prank(emissionManager);
        rewardsDistributor.setEmissionPerSecond(preset.asset0, rewards, newEmissionsPerSecond);

        assertEq(_getEmissionPerSecond(preset.asset0, rewards[0]), 100);
        assertEq(_getEmissionPerSecond(preset.asset0, rewards[1]), 200);
    }

    function testSetEmissionPerSecond_emitsEvent() public {
        address[] memory rewards = _toArray(preset.reward00, preset.reward01);
        uint88[] memory newEmissionsPerSecond = _toArrayUint88(100, 200);

        vm.prank(emissionManager);
        _expectEmitAssetConfigUpdated(
            preset.asset0,
            rewards[0],
            0,
            100,
            PRESET_CURRENT_DATE,
            PRESET_CURRENT_DATE,
            0
        );
        _expectEmitAssetConfigUpdated(
            preset.asset0,
            rewards[1],
            0,
            200,
            PRESET_CURRENT_DATE + 2 seconds,
            PRESET_CURRENT_DATE + 2 seconds,
            0
        );
        rewardsDistributor.setEmissionPerSecond(preset.asset0, rewards, newEmissionsPerSecond);
    }

    function testSetEmissionPerSecond_updatesIndexBasedOnTimePassedSinceLastUpdate() public {
        _distributeRewardsForOneWeek(preset.asset0, preset.reward00, 700);
        _distributeRewardsForOneWeek(preset.asset0, preset.reward01, 800);
        _distributeRewardsForOneWeek(preset.asset1, preset.reward1, 900);

        vm.warp(PRESET_CURRENT_DATE + preset.accruingPeriod);
        vm.startPrank(emissionManager);
        rewardsDistributor.setEmissionPerSecond(
            preset.asset0,
            _toArray(preset.reward00, preset.reward01),
            _toArrayUint88(100, 200)
        );
        rewardsDistributor.setEmissionPerSecond(preset.asset1, _toArray(preset.reward1), _toArrayUint88(300));

        assertEq(
            _getDistributionIndex(preset.asset0, preset.reward00),
            _computeDistributionIndex(700, preset.accruingPeriod)
        );
        assertEq(
            _getDistributionIndex(preset.asset0, preset.reward01),
            _computeDistributionIndex(800, preset.accruingPeriod)
        );
        assertEq(
            _getDistributionIndex(preset.asset1, preset.reward1),
            _computeDistributionIndex(900, preset.accruingPeriod)
        );
    }

    function testSetEmissionManager_failsIfNotCalledByEmissionManager() public {
        _expectRevert_NotEmissionManager();
        rewardsDistributor.setEmissionManager(address(this));
    }

    function testSetEmissionManager() public {
        vm.prank(emissionManager);
        _expectEmit_EmissionManagerUpdated(address(this));
        rewardsDistributor.setEmissionManager(address(this));

        assertEq(rewardsDistributor.getEmissionManager(), address(this));
    }

    function testCanUpdateCarbonRewardDistribution_failsForNonExistentDistribution() public {
        address reward = address(77);

        _expectRevert_DistributionNonExistent(preset.asset0, reward);
        rewardsDistributor.canUpdateCarbonRewardDistribution(preset.asset0, reward);
    }

    function testCanUpdateCarbonRewardDistribution_ifDistributionNotInitialized() public {
        vm.prank(emissionManager);
        rewardsDistributor.setDistributionEnd(preset.asset0, preset.reward00, 0);

        _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(0, false);
    }

    function testCanUpdateCarbonRewardDistribution() public {
        vm.prank(emissionManager);
        rewardsDistributor.setDistributionEnd(preset.asset0, preset.reward00, PRESET_CURRENT_DATE);

        _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(-1 seconds, false);
        _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(0 seconds, true);
        _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(1 weeks - 1 seconds, true);
        _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(1 weeks, false);
    }

    function testUpdateCarbonRewardDistribution_failsIfNotCalledByEmissionManager() public {
        _expectRevert_NotEmissionManager();
        rewardsDistributor.updateCarbonRewardDistribution(
            _toArray(preset.asset0),
            _toArray(preset.reward00),
            _toArray(100)
        );
    }

    function testUpdateCarbonRewardDistribution_failsForInvalidInput() public {
        vm.startPrank(emissionManager);
        _expectRevert_InvalidInput();
        rewardsDistributor.updateCarbonRewardDistribution(new address[](0), new address[](1), new uint[](1));

        _expectRevert_InvalidInput();
        rewardsDistributor.updateCarbonRewardDistribution(new address[](1), new address[](0), new uint[](1));

        _expectRevert_InvalidInput();
        rewardsDistributor.updateCarbonRewardDistribution(new address[](1), new address[](1), new uint[](0));
        vm.stopPrank();
    }

    function testUpdateCarbonRewardDistribution_failsForNonExistentDistribution() public {
        vm.prank(emissionManager);
        _expectRevert_UpdateDistributionNotApplicable(preset.asset0, address(77));
        rewardsDistributor.updateCarbonRewardDistribution(
            _toArray(preset.asset0),
            _toArray(address(77)),
            _toArray(100)
        );
    }

    function testUpdateCarbonRewardDistribution_emitsEvents() public {
        uint32 distributionEnd = PRESET_CURRENT_DATE + 1 weeks;
        uint32 secondsTillDistributionEnd = 100;
        uint32 updateCarbonRewardDistributionTimeStamp = distributionEnd +
            1 weeks -
            secondsTillDistributionEnd;

        vm.startPrank(emissionManager);
        rewardsDistributor.setDistributionEnd(preset.asset0, preset.reward00, distributionEnd);
        rewardsDistributor.setDistributionEnd(preset.asset1, preset.reward1, distributionEnd);

        vm.warp(updateCarbonRewardDistributionTimeStamp);
        _expectEmitAssetConfigUpdated(
            preset.asset0,
            preset.reward00,
            0,
            10e18 / secondsTillDistributionEnd,
            distributionEnd,
            distributionEnd + 1 weeks,
            0
        );
        _expectEmitAssetConfigUpdated(
            preset.asset1,
            preset.reward1,
            0,
            12e18 / secondsTillDistributionEnd,
            distributionEnd,
            distributionEnd + 1 weeks,
            0
        );
        rewardsDistributor.updateCarbonRewardDistribution(
            _toArray(preset.asset0, preset.asset1),
            _toArray(preset.reward00, preset.reward1),
            _toArray(10e18, 12e18)
        );
    }

    function testUpdateCarbonRewardDistribution_persists() public {
        uint32 distributionEnd = PRESET_CURRENT_DATE + 1 weeks;
        uint32 secondsTillDistributionEnd = 100;
        uint32 updateCarbonRewardDistributionTimeStamp = distributionEnd +
            1 weeks -
            secondsTillDistributionEnd;

        vm.startPrank(emissionManager);
        rewardsDistributor.setDistributionEnd(preset.asset0, preset.reward00, distributionEnd);
        rewardsDistributor.setDistributionEnd(preset.asset1, preset.reward1, distributionEnd);

        vm.warp(updateCarbonRewardDistributionTimeStamp);
        rewardsDistributor.updateCarbonRewardDistribution(
            _toArray(preset.asset0, preset.asset1),
            _toArray(preset.reward00, preset.reward1),
            _toArray(10e18, 12e18)
        );

        (
            uint index,
            uint emissionPerSecond,
            uint lastUpdateTimestamp,
            uint _distributionEnd
        ) = rewardsDistributor.getRewardDistribution(preset.asset0, preset.reward00);
        assertEq(index, 0);
        assertEq(emissionPerSecond, 10e18 / secondsTillDistributionEnd);
        assertEq(lastUpdateTimestamp, updateCarbonRewardDistributionTimeStamp);
        assertEq(uint32(_distributionEnd), distributionEnd + 1 weeks);

        (index, emissionPerSecond, lastUpdateTimestamp, _distributionEnd) = rewardsDistributor
            .getRewardDistribution(preset.asset1, preset.reward1);
        assertEq(index, 0);
        assertEq(emissionPerSecond, 12e18 / secondsTillDistributionEnd);
        assertEq(lastUpdateTimestamp, updateCarbonRewardDistributionTimeStamp);
        assertEq(uint32(_distributionEnd), distributionEnd + 1 weeks);
    }

    function _assertInitialFirstDistributionIsCorrect() private {
        (
            uint index,
            uint emissionPerSecond,
            uint lastUpdateTimestamp,
            uint distributionEnd
        ) = rewardsDistributor.getRewardDistribution(preset.asset0, preset.reward00);

        assertEq(index, 0);
        assertEq(emissionPerSecond, 0);
        assertEq(lastUpdateTimestamp, PRESET_CURRENT_DATE);
        assertEq(distributionEnd, PRESET_CURRENT_DATE);
    }

    function _assertInitialSecondDistributionIsCorrect() private {
        (
            uint index,
            uint emissionPerSecond,
            uint lastUpdateTimestamp,
            uint distributionEnd
        ) = rewardsDistributor.getRewardDistribution(preset.asset1, preset.reward1);

        assertEq(index, 0);
        assertEq(emissionPerSecond, 0);
        assertEq(lastUpdateTimestamp, PRESET_CURRENT_DATE);
        assertEq(distributionEnd, PRESET_CURRENT_DATE + 1 seconds);
    }

    function _assertInitialThirdDistributionIsCorrect() private {
        (
            uint index,
            uint emissionPerSecond,
            uint lastUpdateTimestamp,
            uint distributionEnd
        ) = rewardsDistributor.getRewardDistribution(preset.asset0, preset.reward01);

        assertEq(index, 0);
        assertEq(emissionPerSecond, 0);
        assertEq(lastUpdateTimestamp, PRESET_CURRENT_DATE);
        assertEq(distributionEnd, PRESET_CURRENT_DATE + 2 seconds);
    }

    function _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(
        int secondsRelativeToDistributionEnd,
        bool expectedResult
    ) private {
        vm.warp(uint(int32(PRESET_CURRENT_DATE) + secondsRelativeToDistributionEnd));

        bool canUpdate = rewardsDistributor.canUpdateCarbonRewardDistribution(preset.asset0, preset.reward00);
        assertEq(canUpdate, expectedResult);
    }
}
