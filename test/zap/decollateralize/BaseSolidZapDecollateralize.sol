// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "../TestERC1155.sol";
import "../MockRouter.sol";
import "../WMATIC.sol";
import "../../BaseTest_0_8_18.sol";
import "../../TestToken.sol";
import "../../../contracts/interfaces/zap/ISolidZapDecollateralize.sol";
import "../../../contracts/zap/decollateralize/SolidZapDecollateralize.sol";
import "../MockSWM.sol";

abstract contract BaseSolidZapDecollateralizeTest is BaseTest {
    uint internal constant INITIAL_TOKEN_AMOUNT = 1000000;

    address internal ROUTER;
    address internal SWM;
    TestERC1155 internal fcbt;
    TestToken internal inputToken;
    TestToken internal crispToken;
    WMATIC internal weth;

    address internal testAccount0;
    address internal testAccount1;
    bytes internal basicSwap;

    ISolidZapDecollateralize internal zap;
    ISolidZapDecollateralize.DecollateralizeParams internal emptyParams;

    event ZapDecollateralize(
        address indexed receiver,
        address indexed inputToken,
        uint indexed inputAmount,
        uint dust,
        address dustRecipient,
        uint categoryId
    );

    function setUp() public {
        basicSwap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, 1);
        emptyParams = ISolidZapDecollateralize.DecollateralizeParams({
            batchIds: _toArray(0),
            amountsIn: _toArray(0),
            amountsOutMin: _toArray(0)
        });

        testAccount0 = vm.addr(3);
        testAccount1 = vm.addr(4);
        inputToken = new TestToken("Input Token", "IT", 18);
        crispToken = new TestToken("CRISP SCORED MANGROVES", "CRISP-M", 18);
        weth = new WMATIC();
        ROUTER = address(new MockRouter(address(crispToken), address(crispToken)));
        fcbt = new TestERC1155("");
        SWM = address(new MockSWM(fcbt, crispToken));
        zap = new SolidZapDecollateralize(ROUTER, address(weth), SWM, address(fcbt));

        _labelAccounts();
        _prepareZap();
    }

    function _expectCall_ERC20_transferFrom(address from, uint amount) internal {
        vm.expectCall(address(inputToken), abi.encodeCall(IERC20.transferFrom, (from, address(zap), amount)));
    }

    function _expectCall_ERC20_approve_maxUint(address token, address spender) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.approve, (spender, type(uint256).max)));
    }

    function _doNotExpectCall_ERC20_approve_maxUint(address token, address spender) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.approve, (spender, type(uint256).max)), 0);
    }

    function _expectCall_bulkDecollateralizeTokens(
        uint[] memory batchIds,
        uint[] memory amountsIn,
        uint[] memory amountsOutMin
    ) internal {
        vm.expectCall(
            SWM,
            abi.encodeWithSelector(
                MockSWM.bulkDecollateralizeTokens.selector,
                batchIds,
                amountsIn,
                amountsOutMin
            )
        );
    }

    function _expectCall_onERC1155Received(
        address operator,
        address from,
        uint id,
        uint value,
        bytes memory data
    ) internal {
        vm.expectCall(
            address(zap),
            abi.encodeWithSelector(
                IERC1155Receiver.onERC1155Received.selector,
                operator,
                from,
                id,
                value,
                data
            )
        );
    }

    function _expectCall_swap(RouterBehaviour behaviour, uint acquiredAmount) internal {
        vm.expectCall(ROUTER, _encodeSwap(behaviour, acquiredAmount));
    }

    function _expectRevert_GenericSwapError() internal {
        vm.expectRevert(abi.encodeWithSelector(BaseZap.GenericSwapError.selector));
    }

    function _encodeSwap(RouterBehaviour behaviour, uint acquiredAmount)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSignature("swap(uint256,uint256)", uint(behaviour), acquiredAmount);
    }

    function _expectEmit_ZapDecollateralize(
        address receiver,
        address _inputToken,
        uint inputAmount,
        uint dust,
        address dustRecipient,
        uint categoryId
    ) internal {
        vm.expectEmit(true, true, true, true, address(zap));
        emit ZapDecollateralize(receiver, _inputToken, inputAmount, dust, dustRecipient, categoryId);
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
        vm.label(SWM, "SWM");
    }

    function _prepareZap() private {
        inputToken.mint(testAccount0, INITIAL_TOKEN_AMOUNT);

        vm.prank(testAccount0);
        inputToken.approve(address(zap), INITIAL_TOKEN_AMOUNT);
    }
}
