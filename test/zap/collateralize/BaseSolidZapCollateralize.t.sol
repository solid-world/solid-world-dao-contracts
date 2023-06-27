// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./TestERC1155.sol";
import "../staking/MockRouter.sol";
import "../staking/WMATIC.sol";
import "../../BaseTest_0_8_18.sol";
import "../../liquidity-deployer/TestToken.sol";
import "../../../contracts/interfaces/zap/ISolidZapCollateralize.sol";
import "../../../contracts/zap/collateralize/SolidZapCollateralize.sol";

abstract contract BaseSolidZapCollateralizeTest is BaseTest {
    uint internal constant INITIAL_TOKEN_AMOUNT = 1000000;

    address internal ROUTER;
    address internal SWM;
    TestERC1155 internal fcbt;
    TestToken internal inputToken;
    TestToken internal crispToken;
    WMATIC internal weth;

    address internal testAccount0;
    address internal testAccount1;
    bytes internal emptySwap;

    ISolidZapCollateralize internal zap;

    function setUp() public {
        emptySwap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, 0);

        testAccount0 = vm.addr(3);
        testAccount1 = vm.addr(4);
        inputToken = new TestToken("Input Token", "IT", 18);
        crispToken = new TestToken("CRISP SCORED MANGROVES", "CRISP-M", 18);
        weth = new WMATIC();
        ROUTER = address(new MockRouter(address(crispToken), address(crispToken)));
        fcbt = new TestERC1155("");

        zap = new SolidZapCollateralize(ROUTER, address(weth), address(SWM), address(fcbt));

        _labelAccounts();
        _prepareZap();
    }

    function _encodeSwap(RouterBehaviour behaviour, uint acquiredAmount)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSignature("swap(uint256,uint256)", uint(behaviour), acquiredAmount);
    }

    function _labelAccounts() private {
        vm.label(ROUTER, "Router");
        vm.label(address(weth), "WETH");
        vm.label(testAccount0, "TestAccount0");
        vm.label(testAccount1, "TestAccount1");
        vm.label(address(inputToken), "InputToken");
        vm.label(address(crispToken), "CrispToken");
        vm.label(address(zap), "Zap");
        vm.label(address(fcbt), "FCBT");
        vm.label(address(SWM), "SWM");
    }

    function _prepareZap() private {
        inputToken.mint(testAccount0, INITIAL_TOKEN_AMOUNT);

        vm.prank(testAccount0);
        inputToken.approve(address(zap), INITIAL_TOKEN_AMOUNT);
    }
}
