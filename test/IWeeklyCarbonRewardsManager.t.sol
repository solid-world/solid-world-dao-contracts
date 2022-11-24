pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/SolidWorldManager.sol";

contract IWeeklyCarbonRewardsManagerTest is Test {
    SolidWorldManager manager;
    address root = address(this);
    address testAccount = vm.addr(1);
    address feeReceiver = vm.addr(2);
    address rewardsDistributor = vm.addr(3);

    uint constant CATEGORY_ID = 1;
    uint constant PROJECT_ID = 3;
    uint constant BATCH_ID = 5;

    uint constant CURRENT_DATE = 1666016743;

    uint16 constant COLLATERALIZATION_FEE = 1000; // 10%
    uint16 constant DECOLLATERALIZATION_FEE = 1000; // 10%
    uint24 constant TIME_APPRECIATION = 100_000; // 10%

    event RewardMinted(address rewardToken, uint rewardAmount);

    function setUp() public {
        vm.warp(CURRENT_DATE);

        manager = new SolidWorldManager();

        ForwardContractBatchToken forwardContractBatch = new ForwardContractBatchToken("");
        forwardContractBatch.transferOwnership(address(manager));

        manager.initialize(
            forwardContractBatch,
            COLLATERALIZATION_FEE,
            DECOLLATERALIZATION_FEE,
            feeReceiver,
            IRewardsDistributor(rewardsDistributor)
        );

        vm.label(testAccount, "Test account");
        vm.label(feeReceiver, "Protocol fee receiver account");
    }

    function testUpdateRewardDistribution() public {
        manager.addCategory(CATEGORY_ID, "Test token", "TT");
        manager.addCategory(CATEGORY_ID + 1, "Test token", "TT");
        manager.addProject(CATEGORY_ID, PROJECT_ID);
        manager.addProject(CATEGORY_ID + 1, PROJECT_ID + 1);
        for (uint i = 1; i < 500; i++) {
            manager.addBatch(
                SolidWorldManager.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID + (i % 2),
                    totalAmount: 10000,
                    expectedDueDate: uint32(CURRENT_DATE + i * 1 weeks),
                    vintage: 2022,
                    discountRate: 1647,
                    owner: testAccount
                })
            );
        }

        vm.mockCall(
            rewardsDistributor,
            abi.encodeWithSignature("getDistributionEnd(address,address)"),
            abi.encode(CURRENT_DATE - 1 weeks)
        );

        address[] memory assets = new address[](2);
        uint[] memory categoryIds = new uint[](2);
        assets[0] = vm.addr(4);
        assets[1] = vm.addr(5);
        categoryIds[0] = CATEGORY_ID;
        categoryIds[1] = CATEGORY_ID + 1;
        (address[] memory carbonRewards, uint[] memory rewardAmounts) = manager
            .computeAndMintWeeklyCarbonRewards(assets, categoryIds, vm.addr(6));

        //        assertEq(carbonRewards.length, 2);
        //        assertEq(rewardAmounts.length, 2);
        //
        //        assertEq(carbonRewards[0], assets[0]);
        //        assertEq(carbonRewards[1], assets[1]);
        //
        //        assertEq(rewardAmounts[0], 0);
        //        assertEq(rewardAmounts[1], 0);
    }
}
