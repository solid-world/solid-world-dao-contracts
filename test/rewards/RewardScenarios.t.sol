// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./base-tests/BaseRewardScenarios.sol";

contract RewardScenarios is BaseRewardScenariosTest {
    function testUpdateCarbonRewardDistribution_failsIfCalledBeforeInitialDistributionEnd() public {
        address[] memory assets = _toArray(assetMangrove, assetReforestation);
        uint[] memory categoryIds = _toArray(MANGROVE_CATEGORY_ID, REFORESTATION_CATEGORY_ID);

        _expectRevert_UpdateDistributionNotApplicable(assetMangrove, mangroveRewardToken);
        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);
    }

    function testBothUsersStakingBeforeAndAfterDistributionStartsForAnIncentivizedAssetAccrueRewardsProportionallyToTheirTimeStaked()
        public
    {
        vm.prank(user0);
        solidStaking.stake(assetMangrove, 5000e18);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END);

        address[] memory assets = _toArray(assetMangrove, assetReforestation);
        uint[] memory categoryIds = _toArray(MANGROVE_CATEGORY_ID, REFORESTATION_CATEGORY_ID);
        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);

        (
            ,
            uint mangroveEmissionPerSecond, //100145660714285
            uint lastUpdateTimestamp,
            uint distributionEnd
        ) = rewardsController.getRewardDistribution(assetMangrove, mangroveRewardToken);

        assertEq(lastUpdateTimestamp, INITIAL_CARBON_DISTRIBUTION_END);
        assertEq(distributionEnd, INITIAL_CARBON_DISTRIBUTION_END + 1 weeks);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 1 days);

        vm.prank(user1);
        solidStaking.stake(assetMangrove, 5000e18);
        // updates index

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 2 days);
        CollateralizedBasketToken(usdcToken).mint(rewardsVault, 30 days * 1e18);
        // $1 per second, for a month
        emissionManager.setEmissionPerSecond(assetMangrove, _toArray(usdcToken), _toArrayUint88(1e18));

        // accrued all carbon rewards and distribution ended + accrued 6 days of usdc rewards
        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 8 days);

        address[] memory incentivizedAssets = _toArray(assetMangrove);
        (address[] memory rewardsList0, uint[] memory unclaimedAmounts0) = rewardsController
            .getAllUnclaimedRewardAmountsForUserAndAssets(incentivizedAssets, user0);
        assertEq(rewardsList0.length, 3);
        assertEq(unclaimedAmounts0.length, 3);
        assertEq(rewardsList0[0], mangroveRewardToken);
        assertEq(rewardsList0[1], reforestationRewardToken);
        assertEq(rewardsList0[2], usdcToken);
        assertApproxEqAbs(
            unclaimedAmounts0[0],
            mangroveEmissionPerSecond * 1 days + (mangroveEmissionPerSecond / 2) * 6 days,
            DELTA
        );
        assertEq(unclaimedAmounts0[2], (1e18 / 2) * 6 days);

        (address[] memory rewardsList1, uint[] memory unclaimedAmounts1) = rewardsController
            .getAllUnclaimedRewardAmountsForUserAndAssets(incentivizedAssets, user1);
        assertEq(rewardsList1.length, 3);
        assertEq(unclaimedAmounts1.length, 3);
        assertEq(rewardsList1[0], mangroveRewardToken);
        assertEq(rewardsList1[1], reforestationRewardToken);
        assertEq(rewardsList1[2], usdcToken);
        assertApproxEqAbs(unclaimedAmounts1[0], (mangroveEmissionPerSecond / 2) * 6 days, DELTA);
        assertEq(unclaimedAmounts1[2], (1e18 / 2) * 6 days);

        uint balanceBeforeClaimingRewards0 = CollateralizedBasketToken(mangroveRewardToken).balanceOf(user0);
        uint balanceBeforeClaimingRewards1 = CollateralizedBasketToken(mangroveRewardToken).balanceOf(user1);
        vm.prank(user0);
        rewardsController.claimAllRewardsToSelf(incentivizedAssets);
        assertEq(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(user0),
            balanceBeforeClaimingRewards0 + unclaimedAmounts0[0]
        );

        vm.prank(user1);
        rewardsController.claimAllRewardsToSelf(incentivizedAssets);
        assertEq(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(user1),
            balanceBeforeClaimingRewards1 + unclaimedAmounts1[0]
        );
    }

    function testUserRewardsAreCorrectlyAccountedWhenClaimingMultipleTimesAndModifyingStakeDuringDistributionPeriod()
        public
    {
        uint mangroveBalanceBeforeClaimingRewards = CollateralizedBasketToken(mangroveRewardToken).balanceOf(
            user0
        );
        vm.warp(INITIAL_CARBON_DISTRIBUTION_END);

        address[] memory assets = _toArray(assetMangrove);
        uint[] memory categoryIds = _toArray(MANGROVE_CATEGORY_ID);

        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);
        (, uint mangroveEmissionPerSecond, , ) = rewardsController.getRewardDistribution(
            assetMangrove,
            mangroveRewardToken
        );

        vm.prank(user0);
        solidStaking.stake(assetMangrove, 5000e18);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 1 days);
        vm.prank(user1);
        solidStaking.stake(assetMangrove, 5000e18);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 2 days);
        (, uint[] memory unclaimedAmounts0) = rewardsController.getAllUnclaimedRewardAmountsForUserAndAssets(
            assets,
            user0
        );
        assertApproxEqAbs(
            unclaimedAmounts0[0],
            mangroveEmissionPerSecond * 1 days + (mangroveEmissionPerSecond / 2) * 1 days,
            DELTA
        );
        vm.prank(user0);
        rewardsController.claimAllRewardsToSelf(assets);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 3 days);
        (, uint[] memory unclaimedAmounts1) = rewardsController.getAllUnclaimedRewardAmountsForUserAndAssets(
            assets,
            user0
        );
        assertApproxEqAbs(unclaimedAmounts1[0], (mangroveEmissionPerSecond / 2) * 1 days, DELTA);
        vm.prank(user0);
        solidStaking.withdrawStakeAndClaimRewards(assetMangrove, 2500e18);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 5 days);
        (, uint[] memory unclaimedAmounts2) = rewardsController.getAllUnclaimedRewardAmountsForUserAndAssets(
            assets,
            user0
        );
        assertApproxEqAbs(unclaimedAmounts2[0], (mangroveEmissionPerSecond / 3) * 2 days, DELTA);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 7 days);
        // distribution ended

        vm.prank(user0);
        rewardsController.claimAllRewardsToSelf(assets);
        vm.prank(user1);
        rewardsController.claimAllRewardsToSelf(assets);

        assertEq(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(user0),
            mangroveBalanceBeforeClaimingRewards +
                unclaimedAmounts0[0] +
                unclaimedAmounts1[0] +
                unclaimedAmounts2[0] *
                2
        );
        assertApproxEqAbs(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(user1),
            mangroveBalanceBeforeClaimingRewards +
                (mangroveEmissionPerSecond / 2) *
                2 days +
                ((mangroveEmissionPerSecond * 2) / 3) *
                4 days,
            DELTA
        );

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 8 days);

        (, uint[] memory unclaimedAmounts3) = rewardsController.getAllUnclaimedRewardAmountsForUserAndAssets(
            assets,
            user0
        );
        assertEq(unclaimedAmounts3[0], 0);
        (, uint[] memory unclaimedAmounts4) = rewardsController.getAllUnclaimedRewardAmountsForUserAndAssets(
            assets,
            user1
        );
        assertEq(unclaimedAmounts4[0], 0);
    }

    function testRewardsAccountingWorksAcrossMoreWeeksAndRegardlessOfTheUpdateFunctionBeingCalledWithDelay()
        public
    {
        uint mangroveBalanceBeforeClaimingRewards = CollateralizedBasketToken(mangroveRewardToken).balanceOf(
            user0
        );
        vm.warp(INITIAL_CARBON_DISTRIBUTION_END);

        address[] memory assets = _toArray(assetMangrove);
        uint[] memory categoryIds = _toArray(MANGROVE_CATEGORY_ID);
        address[] memory rewards = _toArray(mangroveRewardToken);
        uint[] memory rewardAmounts = _toArray(25e18);
        uint[] memory feeAmounts = _toArray(5e18);

        _mockComputeWeeklyCarbonRewards(rewards, rewardAmounts, feeAmounts);
        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);

        vm.prank(user0);
        solidStaking.stake(assetMangrove, 5000e18);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 10 days + 12 hours);
        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 14 days);
        // 2 distribution periods passed
        vm.prank(user0);
        rewardsController.claimAllRewardsToSelf(assets);

        assertApproxEqAbs(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(user0),
            mangroveBalanceBeforeClaimingRewards + rewardAmounts[0] * 2,
            DELTA
        );

        assertApproxEqAbs(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(address(rewardsVault)),
            0,
            DELTA
        );
    }
}
