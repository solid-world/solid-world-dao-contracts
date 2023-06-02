// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.t.sol";

contract StakeETHTest is BaseSolidZapStaker {
    function testApprovesRouterToSpendWETH() public {
        assertEq(weth.allowance(address(zapStaker), ROUTER), type(uint).max);
    }

    function testStakeDoubleSwap_wrapsTheValueReceived() public {
        uint wethBalanceBefore = weth.balanceOf(address(zapStaker));

        hoax(testAccount0, 1 ether);
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);

        uint wethBalanceAfter = weth.balanceOf(address(zapStaker));
        assertEq(wethBalanceAfter - wethBalanceBefore, 1000);
        assertEq(testAccount0.balance, 1 ether - 1000);
    }
}
