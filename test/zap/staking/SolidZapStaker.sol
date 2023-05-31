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

    function testStakeDoubleSwap() public {}
}
