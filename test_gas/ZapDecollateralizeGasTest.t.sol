// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./utils/GasTest.sol";
import "../contracts/SolidWorldManager.sol";
import "../test/TestToken.sol";
import "../test/zap/WMATIC.sol";
import "../test/zap/MockRouter.sol";
import "./SolidZapDecollateralize_0_8_16.sol";

contract ZapDecollateralizeGasTest is GasTest {
    uint internal constant CATEGORY_ID = 1;
    uint internal constant PROJECT_ID = 3;
    uint internal constant BATCH_ID = 5;

    address internal ROUTER;
    SolidWorldManager internal manager;
    address internal verificationRegistry = address(new VerificationRegistry());
    address internal feeReceiver;
    TestToken internal inputToken;
    WMATIC internal weth;
    SolidZapDecollateralize_0_8_16 internal zap;
    address internal testAccount0;
    address internal crispToken;
    bytes internal gasIntensiveSwap;
    ForwardContractBatchToken internal forwardContractBatch;

    function setUp() public {
        vm.warp(PRESET_CURRENT_DATE);

        manager = new SolidWorldManager();
        feeReceiver = vm.addr(2);
        testAccount0 = vm.addr(3);

        forwardContractBatch = new ForwardContractBatchToken("", verificationRegistry);
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
            address(this),
            address(this),
            address(this)
        );

        manager.addCategory(CATEGORY_ID, "", "", 82360);
        manager.addProject(CATEGORY_ID, PROJECT_ID);

        crispToken = address(manager.getCategoryToken(CATEGORY_ID));

        gasIntensiveSwap = _encodeSwap(RouterBehaviour.GAS_INTENSIVE, 0);
        inputToken = new TestToken("Input Token", "IT", 18);
        weth = new WMATIC();
        ROUTER = address(new MockRouter(address(crispToken), address(crispToken)));
        zap = new SolidZapDecollateralize_0_8_16(
            ROUTER,
            address(weth),
            address(manager),
            address(forwardContractBatch)
        );
    }

    function testGas_zapDecollateralize_10Batches() public {
        _testGas_zapDecollateralize(10);
    }

    function testGas_zapDecollateralize_25Batches() public {
        _testGas_zapDecollateralize(25);
    }

    function _testGas_zapDecollateralize(uint batches) internal {
        uint[] memory batchIds = new uint[](batches);
        uint[] memory amountsIn = new uint[](batches);
        uint[] memory amountsOutMin = new uint[](batches);
        for (uint i = 1; i < batches + 1; i++) {
            batchIds[i - 1] = BATCH_ID + i;
            amountsIn[i - 1] = 50 ether;
            amountsOutMin[i - 1] = 0;
            manager.addBatch(
                DomainDataTypes.Batch({
                    id: BATCH_ID + i,
                    status: 0,
                    projectId: PROJECT_ID,
                    collateralizedCredits: 10000,
                    certificationDate: uint32(PRESET_CURRENT_DATE + _yearsToSeconds(10)),
                    vintage: 2022,
                    batchTA: 0,
                    supplier: vm.addr(13),
                    isAccumulating: false
                }),
                10000
            );

            vm.prank(address(manager));
            forwardContractBatch.mint(address(manager), BATCH_ID + i, 10000, "");
        }

        _prepareZap();
        SolidZapDecollateralize_0_8_16.DecollateralizeParams memory params = SolidZapDecollateralize_0_8_16
            .DecollateralizeParams({
                batchIds: batchIds,
                amountsIn: amountsIn,
                amountsOutMin: amountsOutMin
            });

        string memory label = string(
            abi.encodePacked("zapDecollateralize_", vm.toString(batches), "batches")
        );
        vm.startPrank(testAccount0);
        startMeasuringGas(label);
        zap.zapDecollateralize(
            address(inputToken),
            1000,
            address(crispToken),
            gasIntensiveSwap,
            feeReceiver,
            params
        );
        stopMeasuringGas();
    }

    function _prepareZap() private {
        vm.prank(address(manager));
        CollateralizedBasketToken(crispToken).mint(address(zap), 10000 ether);

        inputToken.mint(testAccount0, type(uint).max);

        vm.prank(testAccount0);
        inputToken.approve(address(zap), type(uint).max);
    }

    function _encodeSwap(RouterBehaviour behaviour, uint acquiredAmount)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSignature("swap(uint256,uint256)", uint(behaviour), acquiredAmount);
    }
}
