// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/SolidWorldManager.sol";
import "../../contracts/compliance/VerificationRegistry.sol";

abstract contract BaseSolidWorldManagerTest is BaseTest {
    event CategoryRebalanced(
        uint indexed categoryId,
        uint indexed averageTA,
        uint indexed totalCollateralized
    );

    SolidWorldManager manager;
    ForwardContractBatchToken forwardContractBatch;
    address verificationRegistry = address(new VerificationRegistry());
    address root = address(this);
    address testAccount = vm.addr(1);
    address feeReceiver = vm.addr(2);
    address weeklyRewardsMinter = vm.addr(3);
    address timelockController = vm.addr(4);

    uint constant CATEGORY_ID = 1;
    uint constant PROJECT_ID = 3;
    uint constant BATCH_ID = 5;
    uint24 constant INITIAL_CATEGORY_TA = 8_0000;

    uint16 constant COLLATERALIZATION_FEE = 1000; // 10%
    uint16 constant DECOLLATERALIZATION_FEE = 1000; // 10%
    uint16 constant BOOSTED_DECOLLATERALIZATION_FEE = 100; // 1%
    uint16 constant REWARDS_FEE = 500; // 5%

    function setUp() public virtual {
        vm.warp(PRESET_CURRENT_DATE);

        manager = new SolidWorldManager();
        forwardContractBatch = new ForwardContractBatchToken("", verificationRegistry);
        forwardContractBatch.transferOwnership(address(manager));

        _labelAccounts();

        vm.prank(testAccount);
        forwardContractBatch.setApprovalForAll(address(manager), true);

        manager.initialize(
            _configuredCBTDeployer(address(manager)),
            forwardContractBatch,
            COLLATERALIZATION_FEE,
            DECOLLATERALIZATION_FEE,
            BOOSTED_DECOLLATERALIZATION_FEE,
            REWARDS_FEE,
            feeReceiver,
            weeklyRewardsMinter,
            address(this),
            timelockController
        );
    }

    function _labelAccounts() private {
        vm.label(address(manager), "SolidWorldManager");
        vm.label(address(forwardContractBatch), "ForwardContractBatch");
        vm.label(testAccount, "Test account");
        vm.label(feeReceiver, "Protocol fee receiver");
        vm.label(weeklyRewardsMinter, "Weekly rewards minter");
        vm.label(timelockController, "Timelock controller");
    }

    function _configuredCBTDeployer(address owner)
        private
        returns (CollateralizedBasketTokenDeployer deployer)
    {
        deployer = new CollateralizedBasketTokenDeployer(verificationRegistry);
        deployer.transferOwnership(owner);
    }

    function _addBatchWithDependencies(uint certificationDate, uint mintableAmount) internal {
        _addBatchWithDependencies(INITIAL_CATEGORY_TA, certificationDate, mintableAmount);
    }

    function _addBatchWithDependencies(
        uint initialCategoryTa,
        uint certificationDate,
        uint mintableAmount
    ) internal {
        _addBatchWithDependencies(
            CATEGORY_ID,
            PROJECT_ID,
            BATCH_ID,
            initialCategoryTa,
            certificationDate,
            mintableAmount
        );
    }

    function _addBatchWithDependencies(
        uint categoryId,
        uint projectId,
        uint batchId,
        uint initialCategoryTa,
        uint certificationDate,
        uint mintableAmount
    ) internal {
        _addCategoryAndProjectWithApprovedSpending(categoryId, projectId, initialCategoryTa);
        _addBatch(batchId, projectId, certificationDate, mintableAmount);
    }

    function _addCategoryAndProjectWithApprovedSpending() internal {
        _addCategoryAndProjectWithApprovedSpending(CATEGORY_ID, PROJECT_ID, INITIAL_CATEGORY_TA);
    }

    function _addCategoryAndProjectWithApprovedSpending(
        uint categoryId,
        uint projectId,
        uint initialCategoryTa
    ) internal {
        manager.addCategory(categoryId, "", "", uint24(initialCategoryTa));
        CollateralizedBasketToken cbt = manager.getCategoryToken(categoryId);
        vm.label(address(cbt), "Test CBT");

        manager.addProject(categoryId, projectId);

        vm.prank(testAccount);
        cbt.approve(address(manager), type(uint).max);
    }

    function _addBatch(uint certificationDate, uint mintableAmount) internal {
        _addBatch(BATCH_ID, certificationDate, mintableAmount);
    }

    function _addBatch(
        uint batchId,
        uint certificationDate,
        uint mintableAmount
    ) internal {
        _addBatch(batchId, PROJECT_ID, certificationDate, mintableAmount);
    }

    function _addBatch(
        uint batchId,
        uint projectId,
        uint certificationDate,
        uint mintableAmount
    ) internal {
        _addBatch(batchId, projectId, certificationDate, 0, mintableAmount);
    }

    function _addBatch(
        uint batchId,
        uint projectId,
        uint certificationDate,
        uint batchTA,
        uint mintableAmount
    ) internal {
        manager.addBatch(
            DomainDataTypes.Batch({
                id: batchId,
                status: 0,
                projectId: projectId,
                collateralizedCredits: 0,
                certificationDate: uint32(certificationDate),
                vintage: 2023,
                batchTA: uint24(batchTA),
                supplier: testAccount,
                isAccumulating: false
            }),
            mintableAmount
        );
    }

    function _getTestDecayPerSecond() internal pure returns (uint40 decayPerSecond) {
        // 5% decay per day quantified per second
        decayPerSecond = uint40(
            Math.mulDiv(5, ReactiveTimeAppreciationMath.DECAY_BASIS_POINTS, 100 * 1 days)
        );
    }

    function _expectRevert_Paused() internal {
        vm.expectRevert(abi.encodeWithSelector(Pausable.Paused.selector));
    }

    function _expectRevert_NotTimelockController(address caller) internal {
        vm.expectRevert(abi.encodeWithSelector(SolidWorldManager.NotTimelockController.selector, caller));
    }
}
