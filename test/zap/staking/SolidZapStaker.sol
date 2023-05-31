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

        vm.startPrank(testAccount0);
        inputToken.approve(address(zapStaker), 1000);

        _expectCall_ERC20_transferFrom(testAccount0, 1000);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);
    }
}
