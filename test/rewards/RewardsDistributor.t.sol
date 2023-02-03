pragma solidity ^0.8.0;

import "./BaseRewardsDistributor.sol";

contract RewardsDistributorTest is BaseRewardsDistributor {
    function testInitialRewardDistribution() public {
        _assertInitialFirstDistributionIsFine();
        _assertInitialSecondDistributionIsFine();
        _assertInitialThirdDistributionIsFine();
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
    }

    function testGetAllRewards() public {
        address[] memory rewards = rewardsDistributor.getAllRewards();
        assertEq(rewards.length, 3);
        assertEq(rewards[0], reward00);
        assertEq(rewards[1], reward1);
        assertEq(rewards[2], reward01);
    }

    function testChangesOfStakeEmitAccruedEvent() public {
        _distributeRewardsForOneWeek(asset0, reward00, 100);
        vm.warp(CURRENT_DATE + 5 seconds);

        _expectEmitAccrued(
            asset0,
            reward00,
            arbitraryUser,
            1,
            1,
            _earnedRewards(5, 100, arbitraryUserStake, arbitraryTotalStaked)
        );
        _simulateUserStaking(asset0, arbitraryUser, arbitraryUserStake, arbitraryTotalStaked);
    }

    function testChangeOfStakeUpdatesDistributionIndex() public {
        _distributeRewardsForOneWeek(asset0, reward00, 100);
        _distributeRewardsForOneWeek(asset0, reward01, 200);

        vm.warp(CURRENT_DATE + 5 seconds);
        _simulateUserStaking(asset0, arbitraryUser, arbitraryUserStake, arbitraryTotalStaked);

        assertEq(_getDistributionIndex(asset0, reward00), 1);
        assertEq(_getDistributionIndex(asset0, reward01), 2);
    }

    function testChangeOfStakeUpdatesDistributionTimestamp() public {
        _distributeRewardsForOneWeek(asset0, reward00, 100);
        _distributeRewardsForOneWeek(asset0, reward01, 200);

        vm.warp(CURRENT_DATE + 5 seconds);
        _simulateUserStaking(asset0, arbitraryUser, arbitraryUserStake, arbitraryTotalStaked);

        assertEq(_getDistributionUpdateTimestamp(asset0, reward00), CURRENT_DATE + 5 seconds);
        assertEq(_getDistributionUpdateTimestamp(asset0, reward01), CURRENT_DATE + 5 seconds);
    }

    function testChangeOfStakeUpdatesUserIndex() public {
        _distributeRewardsForOneWeek(asset0, reward00, 100);
        _distributeRewardsForOneWeek(asset0, reward01, 200);

        vm.warp(CURRENT_DATE + 5 seconds);
        _simulateUserStaking(asset0, arbitraryUser, arbitraryUserStake, arbitraryTotalStaked);

        assertEq(rewardsDistributor.getUserIndex(arbitraryUser, asset0, reward00), 1);
        assertEq(rewardsDistributor.getUserIndex(arbitraryUser, asset0, reward01), 2);
        assertEq(rewardsDistributor.getUserIndex(arbitraryUser, asset0, reward1), 0);
    }

    function testChangeOfStakeAccruesRewardsForUser() public {
        _distributeRewardsForOneWeek(asset0, reward00, 100);
        _distributeRewardsForOneWeek(asset0, reward01, 200);

        vm.warp(CURRENT_DATE + 5 seconds);
        _simulateUserStaking(asset0, arbitraryUser, arbitraryUserStake, arbitraryTotalStaked);

        assertEq(
            rewardsDistributor.getAccruedRewardAmountForUser(arbitraryUser, reward00),
            _earnedRewards(5, 100, arbitraryUserStake, arbitraryTotalStaked)
        );
        assertEq(
            rewardsDistributor.getAccruedRewardAmountForUser(arbitraryUser, reward01),
            _earnedRewards(5, 200, arbitraryUserStake, arbitraryTotalStaked)
        );
        assertEq(rewardsDistributor.getAccruedRewardAmountForUser(arbitraryUser, reward1), 0);
    }

    function testGetUnclaimedRewardAmountForUserAndAssets_returnsAccruedAndUnrealised() public {
        _distributeRewardsForOneWeek(asset0, reward00, 100);
        _distributeRewardsForOneWeek(asset0, reward01, 200);

        vm.warp(CURRENT_DATE + 5 seconds);
        _simulateUserStaking(asset0, arbitraryUser, arbitraryUserStake, arbitraryTotalStaked);

        // rewards continue to grow another 5 seconds after the user stakes
        vm.warp(CURRENT_DATE + 10 seconds);
        _mockUserStakeAmount(arbitraryUserStake);
        _mockTotalStaked(arbitraryTotalStaked);
        uint totalRewards = rewardsDistributor.getUnclaimedRewardAmountForUserAndAssets(
            _toArray(asset0),
            arbitraryUser,
            reward00
        );

        assertEq(totalRewards, _earnedRewards(10, 100, arbitraryUserStake, arbitraryTotalStaked));
    }

    function testGetAllUnclaimedRewardAmountsForUserAndAssets() public {
        _distributeRewardsForOneWeek(asset0, reward00, 100);
        _distributeRewardsForOneWeek(asset0, reward01, 200);
        _distributeRewardsForOneWeek(asset1, reward1, 300);

        vm.warp(CURRENT_DATE + 5 seconds);
        _simulateUserStaking(asset0, arbitraryUser, arbitraryUserStake, arbitraryTotalStaked);
        _simulateUserStaking(asset1, arbitraryUser, arbitraryUserStake, arbitraryTotalStaked);

        // rewards continue to grow another 5 seconds after the user stakes
        vm.warp(CURRENT_DATE + 10 seconds);

        _mockUserStakeAmount(arbitraryUserStake);
        _mockTotalStaked(arbitraryTotalStaked);
        (address[] memory rewardsList, uint[] memory unclaimedAmounts) = rewardsDistributor
            .getAllUnclaimedRewardAmountsForUserAndAssets(_toArray(asset0, asset1), arbitraryUser);

        assertEq(rewardsList.length, 3);
        assertEq(rewardsList[0], reward00);
        assertEq(rewardsList[1], reward1);
        assertEq(rewardsList[2], reward01);

        assertEq(unclaimedAmounts.length, 3);
        assertEq(
            unclaimedAmounts[0],
            _earnedRewards(10, 100, arbitraryUserStake, arbitraryTotalStaked)
        );
        assertEq(
            unclaimedAmounts[1],
            _earnedRewards(10, 300, arbitraryUserStake, arbitraryTotalStaked)
        );
        assertEq(
            unclaimedAmounts[2],
            _earnedRewards(10, 200, arbitraryUserStake, arbitraryTotalStaked)
        );
    }

    function testSetDistributionEnd_failsIfNotCalledByEmissionManager() public {
        _expectRevert_NotEmissionManager();
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE + 1 weeks);
    }

    function testSetDistributionEnd_failsForNonExistentDistribution() public {
        address reward = vm.addr(77);

        vm.prank(emissionManager);
        _expectRevert_DistributionNonExistent(asset0, reward);
        rewardsDistributor.setDistributionEnd(asset0, reward, CURRENT_DATE + 1 weeks);
    }

    function testSetDistributionEnd_emitsEvent() public {
        vm.startPrank(emissionManager);
        _expectEmitAssetConfigUpdated(
            asset0,
            reward00,
            0,
            0,
            CURRENT_DATE,
            CURRENT_DATE + 1 weeks,
            0
        );
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE + 1 weeks);

        _expectEmitAssetConfigUpdated(
            asset1,
            reward1,
            0,
            0,
            CURRENT_DATE + 1 seconds,
            CURRENT_DATE + 2 weeks,
            0
        );
        rewardsDistributor.setDistributionEnd(asset1, reward1, CURRENT_DATE + 2 weeks);

        _expectEmitAssetConfigUpdated(
            asset0,
            reward01,
            0,
            0,
            CURRENT_DATE + 2 seconds,
            CURRENT_DATE + 3 weeks,
            0
        );
        rewardsDistributor.setDistributionEnd(asset0, reward01, CURRENT_DATE + 3 weeks);
    }

    function testSetDistributionEnd_persistsDistributionEnd() public {
        vm.startPrank(emissionManager);
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE + 1 weeks);
        rewardsDistributor.setDistributionEnd(asset1, reward1, CURRENT_DATE + 2 weeks);
        rewardsDistributor.setDistributionEnd(asset0, reward01, CURRENT_DATE + 3 weeks);
        vm.stopPrank();

        uint distributionEnd00 = rewardsDistributor.getDistributionEnd(asset0, reward00);
        assertEq(distributionEnd00, CURRENT_DATE + 1 weeks);

        uint distributionEnd1 = rewardsDistributor.getDistributionEnd(asset1, reward1);
        assertEq(distributionEnd1, CURRENT_DATE + 2 weeks);

        uint distributionEnd01 = rewardsDistributor.getDistributionEnd(asset0, reward01);
        assertEq(distributionEnd01, CURRENT_DATE + 3 weeks);
    }

    function testSetEmissionPerSecond_failsIfNotCalledByEmissionManager() public {
        _expectRevert_NotEmissionManager();
        rewardsDistributor.setEmissionPerSecond(asset0, new address[](0), new uint88[](0));
    }

    function testSetEmissionPerSecond_failsForInvalidInput() public {
        vm.prank(emissionManager);
        _expectRevert_InvalidInput();
        rewardsDistributor.setEmissionPerSecond(asset0, new address[](2), new uint88[](0));
    }

    function testSetEmissionPerSecond_failsForNonExistentDistribution() public {
        address[] memory rewards = _toArray(vm.addr(77));
        uint88[] memory newEmissionsPerSecond = _toArrayUint88(uint88(300));

        vm.prank(emissionManager);
        _expectRevert_DistributionNonExistent(asset0, rewards[0]);
        rewardsDistributor.setEmissionPerSecond(asset0, rewards, newEmissionsPerSecond);
    }

    function testSetEmissionPerSecond_persistsEmissionPerSecond() public {
        address[] memory rewards = _toArray(reward00, reward01);
        uint88[] memory newEmissionsPerSecond = _toArrayUint88(uint88(100), uint88(200));

        vm.prank(emissionManager);
        rewardsDistributor.setEmissionPerSecond(asset0, rewards, newEmissionsPerSecond);

        assertEq(_getEmissionPerSecond(asset0, rewards[0]), 100);
        assertEq(_getEmissionPerSecond(asset0, rewards[1]), 200);
    }

    function testSetEmissionPerSecond_emitsEvent() public {
        address[] memory rewards = _toArray(reward00, reward01);
        uint88[] memory newEmissionsPerSecond = _toArrayUint88(uint88(100), uint88(200));

        vm.prank(emissionManager);
        _expectEmitAssetConfigUpdated(asset0, rewards[0], 0, 100, CURRENT_DATE, CURRENT_DATE, 0);
        _expectEmitAssetConfigUpdated(
            asset0,
            rewards[1],
            0,
            200,
            CURRENT_DATE + 2 seconds,
            CURRENT_DATE + 2 seconds,
            0
        );
        rewardsDistributor.setEmissionPerSecond(asset0, rewards, newEmissionsPerSecond);
    }

    function testSetEmissionPerSecond_updatesIndexBasedOnTimePassedSinceLastUpdate() public {
        _distributeRewardsForOneWeek(asset0, reward00, 700);
        _distributeRewardsForOneWeek(asset0, reward01, 800);
        _distributeRewardsForOneWeek(asset1, reward1, 900);

        vm.warp(CURRENT_DATE + 5 seconds);
        vm.startPrank(emissionManager);
        rewardsDistributor.setEmissionPerSecond(
            asset0,
            _toArray(reward00, reward01),
            _toArrayUint88(uint88(100), uint88(200))
        );
        rewardsDistributor.setEmissionPerSecond(
            asset1,
            _toArray(reward1),
            _toArrayUint88(uint88(300))
        );

        assertEq(_getDistributionIndex(asset0, reward00), 7);
        assertEq(_getDistributionIndex(asset0, reward01), 8);
        assertEq(_getDistributionIndex(asset1, reward1), 9);
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

        _expectRevert_DistributionNonExistent(asset0, reward);
        rewardsDistributor.canUpdateCarbonRewardDistribution(asset0, reward);
    }

    function testCanUpdateCarbonRewardDistribution_ifDistributionNotInitialized() public {
        vm.prank(emissionManager);
        rewardsDistributor.setDistributionEnd(asset0, reward00, 0);

        _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(0, false);
    }

    function testCanUpdateCarbonRewardDistribution() public {
        vm.prank(emissionManager);
        rewardsDistributor.setDistributionEnd(asset0, reward00, CURRENT_DATE);

        _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(-1 seconds, false);
        _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(0 seconds, true);
        _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(1 weeks - 1 seconds, true);
        _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(1 weeks, false);
    }

    function testUpdateCarbonRewardDistribution_failsIfNotCalledByEmissionManager() public {
        _expectRevert_NotEmissionManager();
        rewardsDistributor.updateCarbonRewardDistribution(
            _toArray(asset0),
            _toArray(reward00),
            _toArray(100)
        );
    }

    function testUpdateCarbonRewardDistribution_failsForInvalidInput() public {
        vm.startPrank(emissionManager);
        _expectRevert_InvalidInput();
        rewardsDistributor.updateCarbonRewardDistribution(
            new address[](0),
            new address[](1),
            new uint[](1)
        );

        _expectRevert_InvalidInput();
        rewardsDistributor.updateCarbonRewardDistribution(
            new address[](1),
            new address[](0),
            new uint[](1)
        );

        _expectRevert_InvalidInput();
        rewardsDistributor.updateCarbonRewardDistribution(
            new address[](1),
            new address[](1),
            new uint[](0)
        );
        vm.stopPrank();
    }

    function testUpdateCarbonRewardDistribution_failsForNonExistentDistribution() public {
        vm.prank(emissionManager);
        _expectRevert_UpdateDistributionNotApplicable(asset0, address(77));
        rewardsDistributor.updateCarbonRewardDistribution(
            _toArray(asset0),
            _toArray(address(77)),
            _toArray(100)
        );
    }

    function testUpdateCarbonRewardDistribution_emitsEvents() public {
        uint32 distributionEnd = CURRENT_DATE + 1 weeks;
        uint32 secondsTillDistributionEnd = 100;
        uint32 updateCarbonRewardDistributionTimeStamp = distributionEnd +
            1 weeks -
            secondsTillDistributionEnd;

        vm.startPrank(emissionManager);
        rewardsDistributor.setDistributionEnd(asset0, reward00, distributionEnd);
        rewardsDistributor.setDistributionEnd(asset1, reward1, distributionEnd);

        vm.warp(updateCarbonRewardDistributionTimeStamp);
        _expectEmitAssetConfigUpdated(
            asset0,
            reward00,
            0,
            10e18 / secondsTillDistributionEnd,
            distributionEnd,
            distributionEnd + 1 weeks,
            0
        );
        _expectEmitAssetConfigUpdated(
            asset1,
            reward1,
            0,
            12e18 / secondsTillDistributionEnd,
            distributionEnd,
            distributionEnd + 1 weeks,
            0
        );
        rewardsDistributor.updateCarbonRewardDistribution(
            _toArray(asset0, asset1),
            _toArray(reward00, reward1),
            _toArray(10e18, 12e18)
        );
    }

    function testUpdateCarbonRewardDistribution_persists() public {
        uint32 distributionEnd = CURRENT_DATE + 1 weeks;
        uint32 secondsTillDistributionEnd = 100;
        uint32 updateCarbonRewardDistributionTimeStamp = distributionEnd +
            1 weeks -
            secondsTillDistributionEnd;

        vm.startPrank(emissionManager);
        rewardsDistributor.setDistributionEnd(asset0, reward00, distributionEnd);
        rewardsDistributor.setDistributionEnd(asset1, reward1, distributionEnd);

        vm.warp(updateCarbonRewardDistributionTimeStamp);
        rewardsDistributor.updateCarbonRewardDistribution(
            _toArray(asset0, asset1),
            _toArray(reward00, reward1),
            _toArray(10e18, 12e18)
        );

        (
            uint index,
            uint emissionPerSecond,
            uint lastUpdateTimestamp,
            uint _distributionEnd
        ) = rewardsDistributor.getRewardDistribution(asset0, reward00);
        assertEq(index, 0);
        assertEq(emissionPerSecond, 10e18 / secondsTillDistributionEnd);
        assertEq(lastUpdateTimestamp, updateCarbonRewardDistributionTimeStamp);
        assertEq(uint32(_distributionEnd), distributionEnd + 1 weeks);

        (index, emissionPerSecond, lastUpdateTimestamp, _distributionEnd) = rewardsDistributor
            .getRewardDistribution(asset1, reward1);
        assertEq(index, 0);
        assertEq(emissionPerSecond, 12e18 / secondsTillDistributionEnd);
        assertEq(lastUpdateTimestamp, updateCarbonRewardDistributionTimeStamp);
        assertEq(uint32(_distributionEnd), distributionEnd + 1 weeks);
    }

    function _assertInitialFirstDistributionIsFine() private {
        (
            uint index,
            uint emissionPerSecond,
            uint lastUpdateTimestamp,
            uint distributionEnd
        ) = rewardsDistributor.getRewardDistribution(asset0, reward00);

        assertEq(index, 0);
        assertEq(emissionPerSecond, 0);
        assertEq(lastUpdateTimestamp, CURRENT_DATE);
        assertEq(distributionEnd, CURRENT_DATE);
    }

    function _assertInitialSecondDistributionIsFine() private {
        (
            uint index,
            uint emissionPerSecond,
            uint lastUpdateTimestamp,
            uint distributionEnd
        ) = rewardsDistributor.getRewardDistribution(asset1, reward1);

        assertEq(index, 0);
        assertEq(emissionPerSecond, 0);
        assertEq(lastUpdateTimestamp, CURRENT_DATE);
        assertEq(distributionEnd, CURRENT_DATE + 1 seconds);
    }

    function _assertInitialThirdDistributionIsFine() private {
        (
            uint index,
            uint emissionPerSecond,
            uint lastUpdateTimestamp,
            uint distributionEnd
        ) = rewardsDistributor.getRewardDistribution(asset0, reward01);

        assertEq(index, 0);
        assertEq(emissionPerSecond, 0);
        assertEq(lastUpdateTimestamp, CURRENT_DATE);
        assertEq(distributionEnd, CURRENT_DATE + 2 seconds);
    }

    function _canUpdateCarbonRewardDistribution_relativeToDistributionEnd(
        int secondsRelativeToDistributionEnd,
        bool expectedResult
    ) private {
        vm.warp(uint(int32(CURRENT_DATE) + secondsRelativeToDistributionEnd));

        bool canUpdate = rewardsDistributor.canUpdateCarbonRewardDistribution(asset0, reward00);
        assertEq(canUpdate, expectedResult);
    }
}
