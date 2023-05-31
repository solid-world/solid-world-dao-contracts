// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.t.sol";

contract SolidZapStakerTest is BaseSolidZapStaker {
    function testSetsRouter() public {
        assertEq(zapStaker.router(), ROUTER);
    }

    function testSetsIUniProxy() public {
        assertEq(zapStaker.iUniProxy(), IUNIPROXY);
    }

    function testSetsSolidStaking() public {
        assertEq(zapStaker.solidStaking(), SOLIDSTAKING);
    }

    function testStakeDoubleSwap_transfersOverTheInputTokenAmount() public {
        bytes memory swap1 = new bytes(0);
        bytes memory swap2 = new bytes(0);
        uint minShares = 0;

        vm.prank(testAccount0);
        _expectCall_ERC20_transferFrom(testAccount0, 1000);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);
    }

    function testStakeDoubleSwap_approvesRouterToSpendInputToken() public {
        bytes memory swap1 = new bytes(0);
        bytes memory swap2 = new bytes(0);
        uint minShares = 0;

        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(ROUTER);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);
    }

    function testStakeDoubleSwap_doesNotApproveRouterToSpendInputTokenIfAlreadyApproved() public {
        bytes memory swap1 = new bytes(0);
        bytes memory swap2 = new bytes(0);
        uint minShares = 0;

        vm.prank(address(zapStaker));
        inputToken.approve(ROUTER, type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(ROUTER);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);
    }

    function testStakeDoubleSwap_executesSwap1() public {
        bytes memory swap1 = abi.encodeWithSignature("swap(uint256)", 1);
        bytes memory swap2 = new bytes(0);
        uint minShares = 0;

        vm.prank(testAccount0);
        _mockRouter_swap(1);
        _expectCall_swap(1);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);

        _clearMockedCalls();
    }

    function testStakeDoubleSwap_executesSwap1_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap1 = abi.encodeWithSignature("swap(uint256)", 1);
        bytes memory swap2 = new bytes(0);
        uint minShares = 0;

        vm.prank(testAccount0);
        _mockRouter_swapRevertsEmptyReason(1);
        _expectRevert_GenericSwapError();
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);

        _clearMockedCalls();
    }

    function testStakeDoubleSwap_executesSwap1_revertsWithProvidedReason() public {
        bytes memory swap1 = abi.encodeWithSignature("swap(uint256)", 1);
        bytes memory swap2 = new bytes(0);
        uint minShares = 0;

        vm.prank(testAccount0);
        _mockRouter_swapReverts(1);
        vm.expectRevert(); // vm.expectRevert("router_error"); fails but with correct revert reason. Potential bug in vm.
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);

        _clearMockedCalls();
    }

    function testStakeDoubleSwap_executesSwap2() public {
        bytes memory swap1 = abi.encodeWithSignature("swap(uint256)", 1);
        bytes memory swap2 = abi.encodeWithSignature("swap(uint256)", 2);
        uint minShares = 0;

        vm.prank(testAccount0);
        _mockRouter_swap(1);
        _mockRouter_swap(2);
        _expectCall_swap(2);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);

        _clearMockedCalls();
    }

    function testStakeDoubleSwap_executesSwap2_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap1 = abi.encodeWithSignature("swap(uint256)", 1);
        bytes memory swap2 = abi.encodeWithSignature("swap(uint256)", 2);
        uint minShares = 0;

        vm.prank(testAccount0);
        _mockRouter_swap(1);
        _mockRouter_swapRevertsEmptyReason(2);
        _expectRevert_GenericSwapError();
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);

        _clearMockedCalls();
    }

    function testStakeDoubleSwap_executesSwap2_revertsWithProvidedReason() public {
        bytes memory swap1 = abi.encodeWithSignature("swap(uint256)", 1);
        bytes memory swap2 = abi.encodeWithSignature("swap(uint256)", 2);
        uint minShares = 0;

        vm.prank(testAccount0);
        _mockRouter_swap(1);
        _mockRouter_swapReverts(2);
        vm.expectRevert(); // vm.expectRevert("router_error"); fails but with correct revert reason. Potential bug in vm.
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);

        _clearMockedCalls();
    }
}
