// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../BaseTest.sol";
import "../../../contracts/rewards/RewardsController.sol";
import "../../../contracts/SolidStaking.sol";
import "../../../contracts/rewards/EmissionManager.sol";
import "../../../contracts/SolidWorldManager.sol";
import "../../../contracts/compliance/VerificationRegistry.sol";

abstract contract BaseRewardScenariosTest is BaseTest {
    uint constant MANGROVE_CATEGORY_ID = 1;
    uint constant REFORESTATION_CATEGORY_ID = 2;
    uint constant MANGROVE_PROJECT_ID = 3;
    uint constant REFORESTATION_PROJECT_ID = 4;
    uint constant BATCH_ID = 5;

    uint16 constant COLLATERALIZATION_FEE = 1000; // 10%
    uint16 constant DECOLLATERALIZATION_FEE = 1000; // 10%
    uint16 constant REWARDS_FEE = 500; // 5%

    uint32 constant INITIAL_CARBON_DISTRIBUTION_END = PRESET_CURRENT_DATE + 3 days;
    uint32 constant USDC_DISTRIBUTION_DELAY = 5 days;
    uint32 constant INITIAL_USDC_DISTRIBUTION_END = PRESET_CURRENT_DATE + USDC_DISTRIBUTION_DELAY + 30 days;
    uint24 constant INITIAL_CATEGORY_TA = 82360;

    uint constant DELTA = 1e6; // 0.000000000001 precision

    RewardsController rewardsController;
    SolidStaking solidStaking;
    EmissionManager emissionManager;
    SolidWorldManager solidWorldManager;
    ForwardContractBatchToken forwardContractBatch;
    address verificationRegistry = address(new VerificationRegistry());

    uint mangroveInitialBalance;
    uint reforestationInitialBalance;

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
        vm.warp(PRESET_CURRENT_DATE);

        rewardsController = new RewardsController();
        solidStaking = new SolidStaking(address(new VerificationRegistry()));
        emissionManager = new EmissionManager();
        solidWorldManager = new SolidWorldManager();
        forwardContractBatch = new ForwardContractBatchToken("");
        rewardsVault = vm.addr(1);
        feeReceiver = vm.addr(2);
        user0 = vm.addr(4);
        user1 = vm.addr(5);
        rewardOracle = vm.addr(6);
        usdcToken = address(new CollateralizedBasketToken("USDC", "USDC", verificationRegistry));
        assetMangrove = address(
            new CollateralizedBasketToken("Mangrove hypervisor", "MH", verificationRegistry)
        );
        assetReforestation = address(
            new CollateralizedBasketToken("Reforestation hypervisor", "RH", verificationRegistry)
        );

        _initializeContracts();

        _loadCarbonRepository();
        _configureEmissionAdmin();
        _rewardsVaultApprovesRewardsController();
        _usersApproveSolidStaking();
        _usersApproveSolidWorldManager();
        _usersCollateralizeForwards();
        _configureStakableAssets();
        _usersBecomeLiquidityProviders();
        _configureRewardDistribution();
        _computeInitialBalances();

        _labelAccounts();
    }

    function _initializeContracts() private {
        _initializeForwardContractBatch();

        rewardsController.setup(address(solidStaking), rewardsVault, address(emissionManager));
        solidStaking.setup(rewardsController, address(this));
        emissionManager.setup(address(solidWorldManager), address(rewardsController), address(this));
        solidWorldManager.initialize(
            new CollateralizedBasketTokenDeployer(),
            forwardContractBatch,
            COLLATERALIZATION_FEE,
            DECOLLATERALIZATION_FEE,
            REWARDS_FEE,
            feeReceiver,
            address(emissionManager),
            address(this)
        );
    }

    function _initializeForwardContractBatch() private {
        forwardContractBatch.transferOwnership(address(solidWorldManager));
    }

    function _mockRewardOracle() private {
        vm.mockCall(
            address(rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(1)
        );
    }

    function _labelAccounts() private {
        vm.label(address(rewardsController), "RewardsController");
        vm.label(address(solidStaking), "SolidStaking");
        vm.label(address(emissionManager), "EmissionManager");
        vm.label(address(solidWorldManager), "SolidWorldManager");
        vm.label(address(forwardContractBatch), "ForwardContractBatch");
        vm.label(rewardsVault, "RewardsVault");
        vm.label(feeReceiver, "FeeReceiver");
        vm.label(user0, "User0");
        vm.label(user1, "User1");
        vm.label(assetMangrove, "AssetMangrove");
        vm.label(assetReforestation, "AssetReforestation");
        vm.label(mangroveRewardToken, "MangroveRewardToken");
        vm.label(reforestationRewardToken, "ReforestationRewardToken");
        vm.label(usdcToken, "UsdcToken");
        vm.label(rewardOracle, "RewardOracle");
    }

    function _configureEmissionAdmin() private {
        emissionManager.setEmissionAdmin(mangroveRewardToken, address(this));
        emissionManager.setEmissionAdmin(reforestationRewardToken, address(this));
        emissionManager.setEmissionAdmin(usdcToken, address(this));
    }

    function _initializeMangroveCategoryAndRewardToken() private {
        solidWorldManager.addCategory(
            MANGROVE_CATEGORY_ID,
            "Mangrove Collateralized Basket Token",
            "MCBT",
            INITIAL_CATEGORY_TA
        );
        mangroveRewardToken = address(solidWorldManager.getCategoryToken(MANGROVE_CATEGORY_ID));
    }

    function _initializeReforestationCategoryAndRewardToken() private {
        solidWorldManager.addCategory(
            REFORESTATION_CATEGORY_ID,
            "Reforestation Collateralized Basket Token",
            "RCBT",
            INITIAL_CATEGORY_TA
        );
        reforestationRewardToken = address(solidWorldManager.getCategoryToken(REFORESTATION_CATEGORY_ID));
    }

    function _addProjectForEachCategory() private {
        solidWorldManager.addProject(MANGROVE_CATEGORY_ID, MANGROVE_PROJECT_ID);
        solidWorldManager.addProject(REFORESTATION_CATEGORY_ID, REFORESTATION_PROJECT_ID);
    }

    function _addBatches() private {
        for (uint i; i < 4; i++) {
            solidWorldManager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: i % 2 == 0 ? MANGROVE_PROJECT_ID : REFORESTATION_PROJECT_ID,
                    collateralizedCredits: 0,
                    certificationDate: PRESET_CURRENT_DATE + ONE_YEAR,
                    vintage: 2023,
                    batchTA: 0,
                    supplier: i % 2 == 0 ? user0 : user1,
                    isAccumulating: false
                }),
                10000 * (i + 1)
            );
            solidWorldManager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i + 4,
                    status: 0,
                    projectId: i % 2 == 0 ? MANGROVE_PROJECT_ID : REFORESTATION_PROJECT_ID,
                    collateralizedCredits: 0,
                    certificationDate: PRESET_CURRENT_DATE + ONE_YEAR,
                    vintage: 2023,
                    batchTA: 0,
                    supplier: i % 2 == 0 ? user1 : user0,
                    isAccumulating: false
                }),
                10000 * (i + 1)
            );
        }
    }

    function _loadCarbonRepository() private {
        _initializeMangroveCategoryAndRewardToken();
        _initializeReforestationCategoryAndRewardToken();
        _addProjectForEachCategory();
        _addBatches();
    }

    function _configureRewardDistribution() private {
        _mockRewardOracle();

        _initialConfigurationCarbonRewards();
        _initialConfigurationUSDCRewards();
    }

    function _computeInitialBalances() private {
        mangroveInitialBalance = IERC20(mangroveRewardToken).balanceOf(user0);
        reforestationInitialBalance = IERC20(reforestationRewardToken).balanceOf(user0);
    }

    function _initialConfigurationCarbonRewards() private {
        RewardsDataTypes.DistributionConfig[] memory carbonConfig = new RewardsDataTypes.DistributionConfig[](
            2
        );
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

    function _initialConfigurationUSDCRewards() private {
        vm.warp(PRESET_CURRENT_DATE + USDC_DISTRIBUTION_DELAY);

        RewardsDataTypes.DistributionConfig[] memory usdcConfig = new RewardsDataTypes.DistributionConfig[](
            2
        );
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

        vm.warp(PRESET_CURRENT_DATE);
    }

    function _rewardsVaultApprovesRewardsController() private {
        vm.startPrank(rewardsVault);
        CollateralizedBasketToken(mangroveRewardToken).approve(address(rewardsController), type(uint256).max);
        CollateralizedBasketToken(reforestationRewardToken).approve(
            address(rewardsController),
            type(uint256).max
        );
        CollateralizedBasketToken(usdcToken).approve(address(rewardsController), type(uint256).max);
        vm.stopPrank();
    }

    function _usersApproveSolidStaking() private {
        vm.startPrank(user0);
        CollateralizedBasketToken(assetMangrove).approve(address(solidStaking), type(uint256).max);
        CollateralizedBasketToken(assetReforestation).approve(address(solidStaking), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user1);
        CollateralizedBasketToken(assetMangrove).approve(address(solidStaking), type(uint256).max);
        CollateralizedBasketToken(assetReforestation).approve(address(solidStaking), type(uint256).max);
        vm.stopPrank();
    }

    function _usersApproveSolidWorldManager() private {
        vm.prank(user0);
        forwardContractBatch.setApprovalForAll(address(solidWorldManager), true);

        vm.prank(user1);
        forwardContractBatch.setApprovalForAll(address(solidWorldManager), true);
    }

    function _usersCollateralizeForwards() private {
        vm.startPrank(user0);
        solidWorldManager.collateralizeBatch(BATCH_ID, 5000, 4130.352e18); // mangrove
        solidWorldManager.collateralizeBatch(BATCH_ID + 5, 10000, 8260.704e18); // reforestation
        solidWorldManager.collateralizeBatch(BATCH_ID + 2, 15000, 12391.056e18); // mangrove
        solidWorldManager.collateralizeBatch(BATCH_ID + 7, 20000, 16521.408e18); // reforestation
        vm.stopPrank();

        vm.startPrank(user1);
        solidWorldManager.collateralizeBatch(BATCH_ID + 4, 5000, 4130.352e18); // mangrove
        solidWorldManager.collateralizeBatch(BATCH_ID + 1, 10000, 8260.704e18); // reforestation
        solidWorldManager.collateralizeBatch(BATCH_ID + 6, 15000, 12391.056e18); // mangrove
        solidWorldManager.collateralizeBatch(BATCH_ID + 3, 20000, 16521.408e18); // reforestation
        vm.stopPrank();
    }

    function _configureStakableAssets() private {
        solidStaking.addToken(assetMangrove);
        solidStaking.addToken(assetReforestation);
    }

    function _usersBecomeLiquidityProviders() private {
        CollateralizedBasketToken(assetMangrove).mint(user0, 16500e18);
        CollateralizedBasketToken(assetReforestation).mint(user0, 24500e18);

        CollateralizedBasketToken(assetMangrove).mint(user1, 16500e18);
        CollateralizedBasketToken(assetReforestation).mint(user1, 24500e18);
    }

    function _expectRevert_UpdateDistributionNotApplicable(address asset, address reward) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.UpdateDistributionNotApplicable.selector,
                asset,
                reward
            )
        );
    }

    function _mockComputeWeeklyCarbonRewards(
        address[] memory rewards,
        uint[] memory rewardAmounts,
        uint[] memory feeAmounts
    ) internal {
        vm.mockCall(
            address(solidWorldManager),
            abi.encodeWithSelector(IWeeklyCarbonRewardsManager.computeWeeklyCarbonRewards.selector),
            abi.encode(rewards, rewardAmounts, feeAmounts)
        );
    }
}
