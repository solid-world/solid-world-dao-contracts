pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../contracts/SolidWorldManager.sol";

abstract contract BaseSolidWorldManager is Test {
    SolidWorldManager manager;
    address root = address(this);
    address testAccount = vm.addr(1);
    address feeReceiver = vm.addr(2);
    address weeklyRewardsMinter = vm.addr(3);

    uint constant CATEGORY_ID = 1;
    uint constant PROJECT_ID = 3;
    uint constant BATCH_ID = 5;

    uint constant CURRENT_DATE = 1666016743;

    uint16 constant COLLATERALIZATION_FEE = 1000; // 10%
    uint16 constant DECOLLATERALIZATION_FEE = 1000; // 10%

    function setUp() public virtual {
        vm.warp(CURRENT_DATE);

        manager = new SolidWorldManager();

        ForwardContractBatchToken forwardContractBatch = new ForwardContractBatchToken("");
        forwardContractBatch.transferOwnership(address(manager));

        CollateralizedBasketTokenDeployer collateralizedBasketTokenDeployer = new CollateralizedBasketTokenDeployer();

        vm.label(testAccount, "Test account");
        vm.label(feeReceiver, "Protocol fee receiver account");
        vm.label(weeklyRewardsMinter, "Weekly rewards minter");

        manager.initialize(
            collateralizedBasketTokenDeployer,
            forwardContractBatch,
            COLLATERALIZATION_FEE,
            DECOLLATERALIZATION_FEE,
            feeReceiver,
            weeklyRewardsMinter
        );
    }
}
