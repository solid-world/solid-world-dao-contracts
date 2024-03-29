// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./utils/GasTest.sol";
import "../contracts/SolidWorldManager.sol";
import "../contracts/interfaces/ISolidStaking.sol";
import "../contracts/rewards/EmissionManager.sol";
import "../contracts/SolidStaking.sol";
import "../contracts/rewards/RewardsController.sol";

contract CarbonRewardDistributionGasTest is GasTest {
    uint constant CATEGORY_ID = 1;
    uint constant PROJECT_ID = 3;
    uint constant BATCH_ID = 5;

    SolidWorldManager manager;
    SolidStaking staking;
    EmissionManager emissionManager;
    RewardsController rewardsController;
    address verificationRegistry = address(new VerificationRegistry());
    address timelockController = vm.addr(13);

    address rewardsVault;
    address feeReceiver;
    address rewardOracle;

    function setUp() public {
        vm.warp(PRESET_CURRENT_DATE);

        manager = new SolidWorldManager();
        staking = new SolidStaking(verificationRegistry, timelockController);
        emissionManager = new EmissionManager();
        rewardsController = new RewardsController();

        rewardsVault = vm.addr(1);
        feeReceiver = vm.addr(2);
        rewardOracle = vm.addr(7);

        ForwardContractBatchToken forwardContractBatch = new ForwardContractBatchToken(
            "",
            verificationRegistry
        );
        forwardContractBatch.transferOwnership(address(manager));
        CollateralizedBasketTokenDeployer collateralizedBasketTokenDeployer = new CollateralizedBasketTokenDeployer(
                verificationRegistry
            );
        manager.initialize(
            collateralizedBasketTokenDeployer,
            forwardContractBatch,
            1000,
            1000,
            1000,
            1000,
            feeReceiver,
            address(emissionManager),
            address(this),
            address(this)
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

    function testGas_updateCarbonRewardDistribution_100Batches_3Rewards() public {
        _testGas_updateCarbonRewardDistribution(100, 3);
    }

    function testGas_updateCarbonRewardDistribution_100Batches_15Rewards() public {
        _testGas_updateCarbonRewardDistribution(100, 15);
    }

    function testGas_updateCarbonRewardDistribution_500Batches_3Rewards() public {
        _testGas_updateCarbonRewardDistribution(500, 3);
    }

    function testGas_updateCarbonRewardDistribution_500Batches_15Rewards() public {
        _testGas_updateCarbonRewardDistribution(500, 15);
    }

    function testGas_updateCarbonRewardDistribution_1000Batches_3Rewards() public {
        _testGas_updateCarbonRewardDistribution(1000, 3);
    }

    function testGas_updateCarbonRewardDistribution_1000Batches_15Rewards() public {
        _testGas_updateCarbonRewardDistribution(1000, 15);
    }

    function testGas_updateCarbonRewardDistribution_5000Batches_3Rewards() public {
        _testGas_updateCarbonRewardDistribution(5000, 3);
    }

    function testGas_updateCarbonRewardDistribution_5000Batches_15Rewards() public {
        _testGas_updateCarbonRewardDistribution(5000, 15);
    }

    function _testGas_updateCarbonRewardDistribution(uint batches, uint rewards) internal {
        for (uint i = 0; i < rewards; i++) {
            manager.addCategory(CATEGORY_ID + i, "", "", 82360);
            manager.addProject(CATEGORY_ID + i, PROJECT_ID + i);
        }

        for (uint i = 1; i < batches + 1; i++) {
            manager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID + (i % rewards),
                    collateralizedCredits: 10000,
                    certificationDate: uint32(PRESET_CURRENT_DATE + _yearsToSeconds(10)),
                    vintage: 2022,
                    batchTA: 0,
                    supplier: vm.addr(13),
                    isAccumulating: false
                }),
                10000
            );
        }

        address[] memory assets = new address[](rewards);
        uint[] memory categoryIds = new uint[](rewards);
        RewardsDataTypes.DistributionConfig[] memory config = new RewardsDataTypes.DistributionConfig[](
            rewards
        );

        for (uint i = 0; i < rewards; i++) {
            assets[i] = address(new CollateralizedBasketToken("", "", verificationRegistry));
            categoryIds[i] = CATEGORY_ID + i;

            emissionManager.setEmissionAdmin(
                address(manager.getCategoryToken(CATEGORY_ID + i)),
                address(this)
            );

            staking.addToken(assets[i]);

            config[i].asset = assets[i];
            config[i].reward = address(manager.getCategoryToken(CATEGORY_ID + i));
            config[i].rewardOracle = IEACAggregatorProxy(rewardOracle);
            config[i].distributionEnd = PRESET_CURRENT_DATE;
        }

        emissionManager.configureAssets(config);

        string memory label = string(
            abi.encodePacked(
                "updateCarbonRewardDistribution_",
                vm.toString(batches),
                "batches_",
                vm.toString(rewards),
                "rewards"
            )
        );
        startMeasuringGas(label);
        emissionManager.updateCarbonRewardDistribution(assets, categoryIds);
        stopMeasuringGas();
    }
}
