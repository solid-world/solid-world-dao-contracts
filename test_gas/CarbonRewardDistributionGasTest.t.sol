pragma solidity ^0.8.0;

import "./utils/GasTest.sol";
import "../contracts/SolidWorldManager.sol";
import "../contracts/interfaces/ISolidStaking.sol";
import "../contracts/rewards/EmissionManager.sol";
import "../contracts/SolidStaking.sol";
import "../contracts/rewards/RewardsController.sol";

contract CarbonRewardDistributionGasTest is GasTest {
    uint32 constant CURRENT_DATE = 1666016743;
    uint constant CATEGORY_ID = 1;
    uint constant PROJECT_ID = 3;
    uint constant BATCH_ID = 5;
    uint constant ONE_YEAR = 1 weeks * 52;

    SolidWorldManager manager;
    SolidStaking staking;
    EmissionManager emissionManager;
    RewardsController rewardsController;

    address rewardsVault;
    address feeReceiver;
    address rewardOracle;

    function setUp() public {
        vm.warp(CURRENT_DATE);

        manager = new SolidWorldManager();
        staking = new SolidStaking();
        emissionManager = new EmissionManager();
        rewardsController = new RewardsController();

        rewardsVault = vm.addr(1);
        feeReceiver = vm.addr(2);
        rewardOracle = vm.addr(7);

        ForwardContractBatchToken forwardContractBatch = new ForwardContractBatchToken("");
        forwardContractBatch.transferOwnership(address(manager));
        CollateralizedBasketTokenDeployer collateralizedBasketTokenDeployer = new CollateralizedBasketTokenDeployer();
        manager.initialize(
            collateralizedBasketTokenDeployer,
            forwardContractBatch,
            1000,
            1000,
            1000,
            feeReceiver,
            address(emissionManager)
        );

        rewardsController.setup(address(staking), rewardsVault, address(emissionManager));
        staking.setup(rewardsController, address(this));
        emissionManager.setup(address(manager), address(rewardsController), address(this));

        vm.mockCall(
            rewardOracle,
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(1)
        );
    }

    function testGas_updateCarbonRewardDistribution_100Batches_5YearsFromCertification_3Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(100, 5, 3);
    }

    function testGas_updateCarbonRewardDistribution_100Batches_10YearsFromCertification_3Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(100, 10, 3);
    }

    function testGas_updateCarbonRewardDistribution_100Batches_5YearsFromCertification_15Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(100, 5, 15);
    }

    function testGas_updateCarbonRewardDistribution_100Batches_10YearsFromCertification_15Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(100, 10, 15);
    }

    function testGas_updateCarbonRewardDistribution_500Batches_5YearsFromCertification_3Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(500, 5, 3);
    }

    function testGas_updateCarbonRewardDistribution_500Batches_10YearsFromCertification_3Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(500, 10, 3);
    }

    function testGas_updateCarbonRewardDistribution_500Batches_5YearsFromCertification_15Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(500, 5, 15);
    }

    function testGas_updateCarbonRewardDistribution_500Batches_10YearsFromCertification_15Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(500, 10, 15);
    }

    function testGas_updateCarbonRewardDistribution_1000Batches_5YearsFromCertification_3Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(1000, 5, 3);
    }

    function testGas_updateCarbonRewardDistribution_1000Batches_10YearsFromCertification_3Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(1000, 10, 3);
    }

    function testGas_updateCarbonRewardDistribution_1000Batches_5YearsFromCertification_15Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(1000, 5, 15);
    }

    function testGas_updateCarbonRewardDistribution_1000Batches_10YearsFromCertification_15Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(1000, 10, 15);
    }

    function testGas_updateCarbonRewardDistribution_5000Batches_5YearsFromCertification_3Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(5000, 5, 3);
    }

    function testGas_updateCarbonRewardDistribution_5000Batches_10YearsFromCertification_3Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(5000, 10, 3);
    }

    function testGas_updateCarbonRewardDistribution_5000Batches_5YearsFromCertification_15Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(5000, 5, 15);
    }

    function testGas_updateCarbonRewardDistribution_5000Batches_10YearsFromCertification_15Rewards()
        public
    {
        _testGas_updateCarbonRewardDistribution(5000, 10, 15);
    }

    function _testGas_updateCarbonRewardDistribution(
        uint batches,
        uint yearsFromCertification,
        uint rewards
    ) internal {
        for (uint i = 0; i < rewards; i++) {
            manager.addCategory(CATEGORY_ID + i, "", "", 1647);
            manager.addProject(CATEGORY_ID + i, PROJECT_ID + i);
        }

        for (uint i = 1; i < batches + 1; i++) {
            manager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID + (i % rewards),
                    certificationDate: uint32(CURRENT_DATE + ONE_YEAR * yearsFromCertification),
                    vintage: 2022,
                    batchTA: 0,
                    supplier: address(manager)
                }),
                10000
            );
        }

        address[] memory assets = new address[](rewards);
        uint[] memory categoryIds = new uint[](rewards);
        RewardsDataTypes.DistributionConfig[]
            memory config = new RewardsDataTypes.DistributionConfig[](rewards);

        for (uint i = 0; i < rewards; i++) {
            assets[i] = address(new CollateralizedBasketToken("", ""));
            categoryIds[i] = CATEGORY_ID + i;

            emissionManager.setEmissionAdmin(
                address(manager.getCategoryToken(CATEGORY_ID + i)),
                address(this)
            );

            staking.addToken(assets[i]);

            config[i].asset = assets[i];
            config[i].reward = address(manager.getCategoryToken(CATEGORY_ID + i));
            config[i].rewardOracle = IEACAggregatorProxy(rewardOracle);
            config[i].distributionEnd = CURRENT_DATE;
        }

        emissionManager.configureAssets(config);

        string memory label = string(
            abi.encodePacked(
                "updateCarbonRewardDistribution_",
                vm.toString(batches),
                "Batches_",
                vm.toString(yearsFromCertification),
                "yearsFromCertification_",
                vm.toString(rewards),
                "rewards"
            )
        );
        startMeasuringGas(label);
        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);
        stopMeasuringGas();
    }
}
