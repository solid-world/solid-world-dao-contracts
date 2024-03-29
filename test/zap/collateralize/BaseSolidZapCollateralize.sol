// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "../TestERC1155.sol";
import "../MockRouter.sol";
import "../WMATIC.sol";
import "../../BaseTest_0_8_18.sol";
import "../../TestToken.sol";
import "../../../contracts/interfaces/zap/ISolidZapCollateralize.sol";
import "../../../contracts/zap/collateralize/SolidZapCollateralize.sol";
import "../MockSWM.sol";

abstract contract BaseSolidZapCollateralizeTest is BaseTest {
    uint internal constant INITIAL_TOKEN_AMOUNT = 1000000;
    uint internal constant BATCH_ID = 1;

    address internal ROUTER;
    address internal SWM;
    TestERC1155 internal fcbt;
    TestToken internal outputToken;
    TestToken internal crispToken;
    WMATIC internal weth;

    address internal testAccount0;
    address internal testAccount1;
    bytes internal basicSwap;

    ISolidZapCollateralize internal zap;

    event ZapCollateralize(
        address indexed receiver,
        address indexed outputToken,
        uint indexed outputAmount,
        uint dust,
        address dustRecipient,
        uint categoryId
    );

    function setUp() public {
        basicSwap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, 1);

        testAccount0 = vm.addr(3);
        testAccount1 = vm.addr(4);
        outputToken = new TestToken("Output Token", "OT", 18);
        crispToken = new TestToken("CRISP SCORED MANGROVES", "CRISP-M", 18);
        weth = new WMATIC();
        ROUTER = address(new MockRouter(address(outputToken), address(outputToken)));
        fcbt = new TestERC1155("");
        SWM = address(new MockSWM(fcbt, crispToken));
        zap = new SolidZapCollateralize(ROUTER, address(weth), SWM, address(fcbt));

        _labelAccounts();
        _prepareZap();
    }

    function _expectCall_ERC20_transferFrom(address from, uint amount) internal {
        vm.expectCall(
            address(outputToken),
            abi.encodeCall(IERC20.transferFrom, (from, address(zap), amount))
        );
    }

    function _expectCall_ERC1155_safeTransferFrom(address from, uint amount) internal {
        vm.expectCall(
            address(fcbt),
            abi.encodeCall(IERC1155.safeTransferFrom, (from, address(zap), BATCH_ID, amount, ""))
        );
    }

    function _expectCall_ERC20_approve_maxUint(address token, address spender) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.approve, (spender, type(uint256).max)));
    }

    function _doNotExpectCall_ERC20_approve_maxUint(address token, address spender) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.approve, (spender, type(uint256).max)), 0);
    }

    function _expectCall_collateralizeBatch(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) internal {
        vm.expectCall(
            SWM,
            abi.encodeWithSelector(MockSWM.collateralizeBatch.selector, batchId, amountIn, amountOutMin)
        );
    }

    function _expectCall_swap(RouterBehaviour behaviour, uint acquiredAmount) internal {
        vm.expectCall(ROUTER, _encodeSwap(behaviour, acquiredAmount));
    }

    function _expectCall_withdraw(uint amount) internal {
        vm.expectCall(address(weth), abi.encodeWithSelector(WMATIC.withdraw.selector, amount));
    }

    function _expectEmit_ZapCollateralize(
        address receiver,
        address _outputToken,
        uint outputAmount,
        uint dust,
        address dustRecipient,
        uint categoryId
    ) internal {
        vm.expectEmit(true, true, true, true, address(zap));
        emit ZapCollateralize(receiver, _outputToken, outputAmount, dust, dustRecipient, categoryId);
    }

    function _expectRevert_GenericSwapError() internal {
        vm.expectRevert(abi.encodeWithSelector(BaseZap.GenericSwapError.selector));
    }

    function _expectRevert_InvalidInput() internal {
        vm.expectRevert(abi.encodeWithSelector(BaseZap.InvalidInput.selector));
    }

    function _encodeSwap(RouterBehaviour behaviour, uint acquiredAmount)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSignature("swap(uint256,uint256)", uint(behaviour), acquiredAmount);
    }

    function _prepareMinWethOutputAmount() internal returns (uint) {
        return _prepareWethOutputAmount(1);
    }

    function _prepareWethOutputAmount(uint wethOutputAmount) internal returns (uint) {
        vm.deal(address(weth), wethOutputAmount);
        weth.mint(address(zap), wethOutputAmount);
        return wethOutputAmount;
    }

    function _labelAccounts() private {
        vm.label(ROUTER, "Router");
        vm.label(address(weth), "WETH");
        vm.label(testAccount0, "TestAccount0");
        vm.label(testAccount1, "TestAccount1");
        vm.label(address(outputToken), "OutputToken");
        vm.label(address(crispToken), "CrispToken");
        vm.label(address(zap), "Zap");
        vm.label(address(fcbt), "FCBT");
        vm.label(SWM, "SWM");
    }

    function _prepareZap() private {
        fcbt.mint(testAccount0, BATCH_ID, INITIAL_TOKEN_AMOUNT, "");

        vm.prank(testAccount0);
        fcbt.setApprovalForAll(address(zap), true);
    }
}
