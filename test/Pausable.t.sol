// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../contracts/Pausable.sol";
import "forge-std/Test.sol";

contract PausableImpl is Pausable {}

contract PausableTest is Test {
    event Pause();
    event Unpause();

    PausableImpl pausable;

    function setUp() public {
        pausable = new PausableImpl();
    }

    function testPause() public {
        vm.expectEmit(false, false, false, false, address(pausable));
        emit Pause();
        pausable.pause();
        assertTrue(pausable.paused());
    }

    function testUnpause() public {
        pausable.pause();

        vm.expectEmit(false, false, false, false, address(pausable));
        emit Unpause();
        pausable.unpause();
        assertFalse(pausable.paused());
    }

    function testPauseWhenPaused() public {
        pausable.pause();
        vm.expectRevert(abi.encodeWithSelector(Pausable.Paused.selector));
        pausable.pause();
    }

    function testUnpauseWhenNotPaused() public {
        vm.expectRevert(abi.encodeWithSelector(Pausable.NotPaused.selector));
        pausable.unpause();
    }
}
