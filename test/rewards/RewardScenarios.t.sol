pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../contracts/rewards/RewardsController.sol";
import "../../contracts/SolidStaking.sol";
import "../../contracts/rewards/EmissionManager.sol";
import "../../contracts/SolidWorldManager.sol";

contract RewardScenarios is Test {
    uint constant CATEGORY_ID = 1;
    uint constant PROJECT_ID = 3;
    uint constant BATCH_ID = 5;

    uint16 constant COLLATERALIZATION_FEE = 1000; // 10%
    uint16 constant DECOLLATERALIZATION_FEE = 1000; // 10%

    uint32 constant CURRENT_DATE = 1666016743;
    uint32 constant INITIAL_CARBON_DISTRIBUTION_END = CURRENT_DATE + 3 days;
    uint32 constant INITIAL_USDC_DISTRIBUTION_END = CURRENT_DATE + 5 days + 30 days;
    uint32 constant ONE_YEAR = 52 weeks;

    uint constant DELTA = 1e6; // 0.000000000001 precision

    RewardsController rewardsController;
    SolidStaking solidStaking;
    EmissionManager emissionManager;
    SolidWorldManager solidWorldManager;

    address rewardsVault;
    address feeReceiver;
    address user0;
    address user1;
    address assetMangrove;
    address assetReforestation;
    address mangroveRewardToken;
    address reforestationRewardToken;
    address usdcToken;
    address rewardOracle;

    function setUp() public {
        vm.warp(CURRENT_DATE);

        rewardsController = new RewardsController();
        solidStaking = new SolidStaking();
        emissionManager = new EmissionManager();
        solidWorldManager = new SolidWorldManager();
        rewardsVault = vm.addr(1);
        feeReceiver = vm.addr(2);
        user0 = vm.addr(4);
        user1 = vm.addr(5);
        rewardOracle = vm.addr(6);

        vm.mockCall(
            address(rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(1)
        );

        usdcToken = address(new CollateralizedBasketToken("USDC", "USDC"));
        assetMangrove = address(new CollateralizedBasketToken("Mangrove hypervisor", "MH"));
        assetReforestation = address(
            new CollateralizedBasketToken("Reforestation hypervisor", "RH")
        );

        rewardsController.setup(solidStaking, rewardsVault, address(emissionManager));
        solidStaking.setup(rewardsController, address(this));
        emissionManager.setup(solidWorldManager, rewardsController, address(this));

        ForwardContractBatchToken forwardContractBatch = new ForwardContractBatchToken("");
        forwardContractBatch.transferOwnership(address(solidWorldManager));
        solidWorldManager.initialize(
            forwardContractBatch,
            COLLATERALIZATION_FEE,
            DECOLLATERALIZATION_FEE,
            feeReceiver,
            address(emissionManager)
        );

        solidWorldManager.addCategory(CATEGORY_ID, "Mangrove Collateralized Basket Token", "MCBT");
        mangroveRewardToken = address(solidWorldManager.categoryToken(CATEGORY_ID));
        solidWorldManager.addCategory(
            CATEGORY_ID + 1,
            "Reforestation Collateralized Basket Token",
            "RCBT"
        );
        reforestationRewardToken = address(solidWorldManager.categoryToken(CATEGORY_ID + 1));

        emissionManager.setEmissionAdmin(mangroveRewardToken, address(this));
        emissionManager.setEmissionAdmin(reforestationRewardToken, address(this));
        emissionManager.setEmissionAdmin(usdcToken, address(this));

        solidWorldManager.addProject(CATEGORY_ID, PROJECT_ID);
        solidWorldManager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        for (uint i = 0; i < 4; i++) {
            solidWorldManager.addBatch(
                SolidWorldManager.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID + (i % 2),
                    totalAmount: 10000 * (i + 1),
                    expectedDueDate: uint32(CURRENT_DATE + ONE_YEAR),
                    vintage: 2023,
                    discountRate: 1647,
                    owner: i % 2 == 0 ? user0 : user1
                })
            );
            solidWorldManager.addBatch(
                SolidWorldManager.Batch({
                    id: BATCH_ID + i + 4,
                    status: 0,
                    projectId: PROJECT_ID + (i % 2),
                    totalAmount: 10000 * (i + 1),
                    expectedDueDate: uint32(CURRENT_DATE + ONE_YEAR),
                    vintage: 2023,
                    discountRate: 1647,
                    owner: i % 2 == 0 ? user1 : user0
                })
            );
        }

        _rewardsVaultApprovesRewardsController();
        _usersApproveSolidStaking();
        _usersCollateralizeForwards(forwardContractBatch);
        _usersBecomeLiquidityProviders();
        _initialConfigurationCarbonRewards();
        _initialConfigurationUSDCRewards();

        vm.label(rewardsVault, "rewardsVault");
        vm.label(feeReceiver, "feeReceiver");
        vm.label(user0, "user0");
        vm.label(user1, "user1");
        vm.label(assetMangrove, "assetMangrove");
        vm.label(assetReforestation, "assetReforestation");
        vm.label(mangroveRewardToken, "mangroveRewardToken");
        vm.label(reforestationRewardToken, "reforestationRewardToken");
        vm.label(usdcToken, "usdcToken");
        vm.label(rewardOracle, "rewardOracle");
    }

    function testUpdateCarbonRewardDistribution_failsIfCalledBeforeInitialDistributionEnd() public {
        address[] memory assets = new address[](2);
        uint[] memory categoryIds = new uint[](2);

        assets[0] = assetMangrove;
        assets[1] = assetReforestation;

        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.UpdateDistributionNotApplicable.selector,
                assetMangrove,
                mangroveRewardToken
            )
        );

        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);
    }

    function testBothUsersStakingBeforeAndAfterDistributionStartsForAnIncentivizedAssetAccrueRewardsProportionallyToTheirTimeStaked()
        public
    {
        vm.prank(user0);
        solidStaking.stake(assetMangrove, 5000e18);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END);

        address[] memory assets = new address[](2);
        uint[] memory categoryIds = new uint[](2);

        assets[0] = assetMangrove;
        assets[1] = assetReforestation;

        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;

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
        solidStaking.stake(assetMangrove, 5000e18); // updates index

        vm.warp(CURRENT_DATE + 5 days);
        CollateralizedBasketToken(usdcToken).mint(rewardsVault, 30 days * 1e18); // $1 per second, for a month
        address[] memory rewards = new address[](1);
        rewards[0] = usdcToken;
        uint88[] memory newEmissionsPerSecond = new uint88[](1);
        newEmissionsPerSecond[0] = 1e18; // $1 per second
        emissionManager.setEmissionPerSecond(assetMangrove, rewards, newEmissionsPerSecond);

        vm.warp(CURRENT_DATE + 11 days); // accrued all carbon rewards and distribution ended + accrued 6 days of usdc rewards

        address[] memory incentivizedAssets = new address[](1);
        incentivizedAssets[0] = assetMangrove;
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

        vm.prank(user0);
        rewardsController.claimAllRewardsToSelf(incentivizedAssets);
        assertEq(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(user0),
            4130.352e18 + 12391.056e18 + unclaimedAmounts0[0]
        );

        vm.prank(user1);
        rewardsController.claimAllRewardsToSelf(incentivizedAssets);
        assertEq(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(user1),
            4130.352e18 + 12391.056e18 + unclaimedAmounts1[0]
        );
    }

    function testUserRewardsAreCorrectlyAccountedWhenClaimingMultipleTimesAndModifyingStakeDuringDistributionPeriod()
        public
    {
        vm.warp(INITIAL_CARBON_DISTRIBUTION_END);

        address[] memory assets = new address[](1);
        uint[] memory categoryIds = new uint[](1);
        assets[0] = assetMangrove;
        categoryIds[0] = CATEGORY_ID;

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
        (, uint[] memory unclaimedAmounts0) = rewardsController
            .getAllUnclaimedRewardAmountsForUserAndAssets(assets, user0);
        assertApproxEqAbs(
            unclaimedAmounts0[0],
            mangroveEmissionPerSecond * 1 days + (mangroveEmissionPerSecond / 2) * 1 days,
            DELTA
        );
        vm.prank(user0);
        rewardsController.claimAllRewardsToSelf(assets);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 3 days);
        (, uint[] memory unclaimedAmounts1) = rewardsController
            .getAllUnclaimedRewardAmountsForUserAndAssets(assets, user0);
        assertApproxEqAbs(unclaimedAmounts1[0], (mangroveEmissionPerSecond / 2) * 1 days, DELTA);
        vm.prank(user0);
        solidStaking.withdrawStakeAndClaimRewards(assetMangrove, 2500e18);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 5 days);
        (, uint[] memory unclaimedAmounts2) = rewardsController
            .getAllUnclaimedRewardAmountsForUserAndAssets(assets, user0);
        assertApproxEqAbs(unclaimedAmounts2[0], (mangroveEmissionPerSecond / 3) * 2 days, DELTA);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 7 days); // distribution ended

        vm.prank(user0);
        rewardsController.claimAllRewardsToSelf(assets);
        vm.prank(user1);
        rewardsController.claimAllRewardsToSelf(assets);

        assertEq(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(user0),
            4130.352e18 +
                12391.056e18 +
                unclaimedAmounts0[0] +
                unclaimedAmounts1[0] +
                unclaimedAmounts2[0] *
                2
        );
        assertApproxEqAbs(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(user1),
            4130.352e18 +
                12391.056e18 +
                (mangroveEmissionPerSecond / 2) *
                2 days +
                ((mangroveEmissionPerSecond * 2) / 3) *
                4 days,
            DELTA
        );

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 8 days);

        (, uint[] memory unclaimedAmounts3) = rewardsController
            .getAllUnclaimedRewardAmountsForUserAndAssets(assets, user0);
        assertEq(unclaimedAmounts3[0], 0);
        (, uint[] memory unclaimedAmounts4) = rewardsController
            .getAllUnclaimedRewardAmountsForUserAndAssets(assets, user1);
        assertEq(unclaimedAmounts4[0], 0);
    }

    function testRewardsAccountingWorksAcrossMoreWeeksAndRegardlessOfTheUpdateFunctionBeingCalledWithDelay()
        public
    {
        vm.warp(INITIAL_CARBON_DISTRIBUTION_END);

        address[] memory assets = new address[](1);
        address[] memory rewards = new address[](1);
        uint[] memory categoryIds = new uint[](1);
        uint[] memory rewardAmounts = new uint[](1);
        assets[0] = assetMangrove;
        rewards[0] = mangroveRewardToken;
        categoryIds[0] = CATEGORY_ID;
        rewardAmounts[0] = 25e18;

        vm.mockCall(
            address(solidWorldManager),
            abi.encodeWithSelector(IWeeklyCarbonRewardsManager.computeWeeklyCarbonRewards.selector),
            abi.encode(rewards, rewardAmounts)
        );
        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);

        vm.prank(user0);
        solidStaking.stake(assetMangrove, 5000e18);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 10 days + 12 hours);
        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);

        vm.warp(INITIAL_CARBON_DISTRIBUTION_END + 14 days); // 2 distribution periods passed
        vm.prank(user0);
        rewardsController.claimAllRewardsToSelf(assets);

        assertApproxEqAbs(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(user0),
            4130.352e18 + 12391.056e18 + 25e18 * 2,
            DELTA
        );

        assertApproxEqAbs(
            CollateralizedBasketToken(mangroveRewardToken).balanceOf(address(rewardsVault)),
            0,
            DELTA
        );
    }

    function _initialConfigurationCarbonRewards() internal {
        RewardsDataTypes.DistributionConfig[]
            memory carbonConfig = new RewardsDataTypes.DistributionConfig[](2);
        carbonConfig[0].asset = assetMangrove;
        carbonConfig[0].reward = mangroveRewardToken;
        carbonConfig[0].emissionPerSecond = 0;
        carbonConfig[0].distributionEnd = INITIAL_CARBON_DISTRIBUTION_END;
        carbonConfig[0].rewardOracle = IEACAggregatorProxy(rewardOracle);

        carbonConfig[1].asset = assetReforestation;
        carbonConfig[1].reward = reforestationRewardToken;
        carbonConfig[1].emissionPerSecond = 0;
        carbonConfig[1].distributionEnd = INITIAL_CARBON_DISTRIBUTION_END;
        carbonConfig[1].rewardOracle = IEACAggregatorProxy(rewardOracle);

        emissionManager.configureAssets(carbonConfig);
    }

    function _initialConfigurationUSDCRewards() internal {
        vm.warp(CURRENT_DATE + 5 days);

        RewardsDataTypes.DistributionConfig[]
            memory usdcConfig = new RewardsDataTypes.DistributionConfig[](2);
        usdcConfig[0].asset = assetMangrove;
        usdcConfig[0].reward = usdcToken;
        usdcConfig[0].emissionPerSecond = 0;
        usdcConfig[0].distributionEnd = INITIAL_USDC_DISTRIBUTION_END;
        usdcConfig[0].rewardOracle = IEACAggregatorProxy(rewardOracle);

        usdcConfig[1].asset = assetReforestation;
        usdcConfig[1].reward = usdcToken;
        usdcConfig[1].emissionPerSecond = 0;
        usdcConfig[1].distributionEnd = INITIAL_USDC_DISTRIBUTION_END;
        usdcConfig[1].rewardOracle = IEACAggregatorProxy(rewardOracle);

        emissionManager.configureAssets(usdcConfig);

        vm.warp(CURRENT_DATE);
    }

    function _rewardsVaultApprovesRewardsController() internal {
        vm.startPrank(rewardsVault);
        CollateralizedBasketToken(mangroveRewardToken).approve(
            address(rewardsController),
            type(uint256).max
        );
        CollateralizedBasketToken(reforestationRewardToken).approve(
            address(rewardsController),
            type(uint256).max
        );
        CollateralizedBasketToken(usdcToken).approve(address(rewardsController), type(uint256).max);
        vm.stopPrank();
    }

    function _usersApproveSolidStaking() internal {
        vm.startPrank(user0);
        CollateralizedBasketToken(assetMangrove).approve(address(solidStaking), type(uint256).max);
        CollateralizedBasketToken(assetReforestation).approve(
            address(solidStaking),
            type(uint256).max
        );
        vm.stopPrank();

        vm.startPrank(user1);
        CollateralizedBasketToken(assetMangrove).approve(address(solidStaking), type(uint256).max);
        CollateralizedBasketToken(assetReforestation).approve(
            address(solidStaking),
            type(uint256).max
        );
        vm.stopPrank();
    }

    function _usersCollateralizeForwards(ForwardContractBatchToken forwardContractBatch) internal {
        vm.startPrank(user0);
        forwardContractBatch.setApprovalForAll(address(solidWorldManager), true);
        solidWorldManager.collateralizeBatch(BATCH_ID, 5000, 4130.352e18); // mangrove
        solidWorldManager.collateralizeBatch(BATCH_ID + 5, 10000, 8260.704e18); // reforestation
        solidWorldManager.collateralizeBatch(BATCH_ID + 2, 15000, 12391.056e18); // mangrove
        solidWorldManager.collateralizeBatch(BATCH_ID + 7, 20000, 16521.408e18); // reforestation
        vm.stopPrank();

        vm.startPrank(user1);
        forwardContractBatch.setApprovalForAll(address(solidWorldManager), true);
        solidWorldManager.collateralizeBatch(BATCH_ID + 4, 5000, 4130.352e18); // mangrove
        solidWorldManager.collateralizeBatch(BATCH_ID + 1, 10000, 8260.704e18); // reforestation
        solidWorldManager.collateralizeBatch(BATCH_ID + 6, 15000, 12391.056e18); // mangrove
        solidWorldManager.collateralizeBatch(BATCH_ID + 3, 20000, 16521.408e18); // reforestation
        vm.stopPrank();
    }

    function _usersBecomeLiquidityProviders() internal {
        solidStaking.addToken(assetMangrove);
        solidStaking.addToken(assetReforestation);
        CollateralizedBasketToken(assetMangrove).mint(user0, 16500e18);
        CollateralizedBasketToken(assetReforestation).mint(user0, 24500e18);
        CollateralizedBasketToken(assetMangrove).mint(user1, 16500e18);
        CollateralizedBasketToken(assetReforestation).mint(user1, 24500e18);
    }
}
