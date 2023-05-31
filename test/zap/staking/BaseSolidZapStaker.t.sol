// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "../../BaseTest_0_8_18.sol";
import "../../../contracts/zap/staking/SolidZapStaker.sol";
import "../../../contracts/interfaces/staking/ISolidZapStaker.sol";
import "../../liquidity-deployer/TestToken.sol";

abstract contract BaseSolidZapStaker is BaseTest {
    address public ROUTER;
    address public IUNIPROXY;
    address public SOLIDSTAKING;
    address public testAccount0;
    TestToken public inputToken;
    TestToken public hypervisor;

    ISolidZapStaker public zapStaker;

    function setUp() public {
        ROUTER = vm.addr(1);
        IUNIPROXY = vm.addr(2);
        SOLIDSTAKING = vm.addr(3);
        testAccount0 = vm.addr(4);
        inputToken = new TestToken("Input Token", "IT", 18);
        hypervisor = new TestToken("Hypervisor", "LP", 18);

        zapStaker = new SolidZapStaker(ROUTER, IUNIPROXY, SOLIDSTAKING);

        _labelAccounts();
        _prepareZap();
    }

    function _expectCall_ERC20_transferFrom(address from, uint amount) internal {
        vm.expectCall(
            address(inputToken),
            abi.encodeCall(IERC20.transferFrom, (from, address(zapStaker), amount))
        );
    }

    function _expectCall_ERC20_approve_maxUint(address spender) internal {
        vm.expectCall(address(inputToken), abi.encodeCall(IERC20.approve, (spender, type(uint256).max)));
    }

    function _doNotExpectCall_ERC20_approve_maxUint(address spender) internal {
        vm.expectCall(address(inputToken), abi.encodeCall(IERC20.approve, (spender, type(uint256).max)), 0);
    }

    function _expectCall_swap(uint dummy) internal {
        vm.expectCall(ROUTER, abi.encodeWithSignature("swap(uint256)", dummy));
    }

    function _expectRevert_GenericSwapError() internal {
        vm.expectRevert(abi.encodeWithSelector(ISolidZapStaker.GenericSwapError.selector));
    }

    function _mockRouter_swap(uint dummy) internal {
        vm.mockCall(ROUTER, abi.encodeWithSignature("swap(uint256)", dummy), abi.encode());
    }

    function _mockRouter_swapReverts(uint dummy) internal {
        vm.mockCallRevert(
            ROUTER,
            abi.encodeWithSignature("swap(uint256)", dummy),
            abi.encode("router_error")
        );
    }

    function _mockRouter_swapRevertsEmptyReason(uint dummy) internal {
        vm.mockCallRevert(ROUTER, abi.encodeWithSignature("swap(uint256)", dummy), abi.encode());
    }

    function _labelAccounts() private {
        vm.label(ROUTER, "Router");
        vm.label(IUNIPROXY, "IUniProxy");
        vm.label(SOLIDSTAKING, "SolidStaking");
        vm.label(testAccount0, "TestAccount0");
        vm.label(address(inputToken), "InputToken");
        vm.label(address(hypervisor), "Hypervisor");
        vm.label(address(zapStaker), "ZapStaker");
    }

    function _prepareZap() private {
        inputToken.mint(testAccount0, 1000000);

        vm.prank(testAccount0);
        inputToken.approve(address(zapStaker), 1000000);
    }
}
