// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../BaseTest.sol";
import "../../contracts/rewards/RewardsController.sol";
import "../../contracts/SolidStaking.sol";
import "../../contracts/rewards/EmissionManager.sol";
import "../../contracts/SolidWorldManager.sol";

contract BaseRewardScenariosTest is BaseTest {
    uint constant CATEGORY_ID = 1;
    uint constant PROJECT_ID = 3;
    uint constant BATCH_ID = 5;

    uint16 constant COLLATERALIZATION_FEE = 1000; // 10%
    uint16 constant DECOLLATERALIZATION_FEE = 1000; // 10%
    uint16 constant REWARDS_FEE = 500; // 5%

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

        rewardsController.setup(address(solidStaking), rewardsVault, address(emissionManager));
        solidStaking.setup(rewardsController, address(this));
        emissionManager.setup(
            address(solidWorldManager),
            address(rewardsController),
            address(this)
        );

        ForwardContractBatchToken forwardContractBatch = new ForwardContractBatchToken("");
        forwardContractBatch.transferOwnership(address(solidWorldManager));
        CollateralizedBasketTokenDeployer collateralizedBasketTokenDeployer = new CollateralizedBasketTokenDeployer();
        solidWorldManager.initialize(
            collateralizedBasketTokenDeployer,
            forwardContractBatch,
            COLLATERALIZATION_FEE,
            DECOLLATERALIZATION_FEE,
            REWARDS_FEE,
            feeReceiver,
            address(emissionManager),
            address(this)
        );

        solidWorldManager.addCategory(
            CATEGORY_ID,
            "Mangrove Collateralized Basket Token",
            "MCBT",
            82360
        );
        mangroveRewardToken = address(solidWorldManager.getCategoryToken(CATEGORY_ID));
        solidWorldManager.addCategory(
            CATEGORY_ID + 1,
            "Reforestation Collateralized Basket Token",
            "RCBT",
            82360
        );
        reforestationRewardToken = address(solidWorldManager.getCategoryToken(CATEGORY_ID + 1));

        emissionManager.setEmissionAdmin(mangroveRewardToken, address(this));
        emissionManager.setEmissionAdmin(reforestationRewardToken, address(this));
        emissionManager.setEmissionAdmin(usdcToken, address(this));

        solidWorldManager.addProject(CATEGORY_ID, PROJECT_ID);
        solidWorldManager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        for (uint i = 0; i < 4; i++) {
            solidWorldManager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID + (i % 2),
                    collateralizedCredits: 0,
                    certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
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
                    projectId: PROJECT_ID + (i % 2),
                    collateralizedCredits: 0,
                    certificationDate: uint32(CURRENT_DATE + ONE_YEAR),
                    vintage: 2023,
                    batchTA: 0,
                    supplier: i % 2 == 0 ? user1 : user0,
                    isAccumulating: false
                }),
                10000 * (i + 1)
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

    function _expectRevert_UpdateDistributionNotApplicable(address asset, address reward) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsDistributor.UpdateDistributionNotApplicable.selector,
                asset,
                reward
            )
        );
    }
}
