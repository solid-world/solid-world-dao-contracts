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
}
