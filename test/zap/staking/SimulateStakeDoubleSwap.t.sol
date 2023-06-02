// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.t.sol";

contract SimulateStakeDoubleSwapTest is BaseSolidZapStaker {
    function testSimulateStakeDoubleSwap_transfersOverTheInputTokenAmount() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_transferFrom(testAccount0, 1000);
        zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            emptySwap1,
            emptySwap2
        );
    }

    function testSimulateStakeDoubleSwap_approvesRouterToSpendInputToken() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            emptySwap1,
            emptySwap2
        );

        uint actual = inputToken.allowance(address(zapStaker), ROUTER);
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeDoubleSwap_doesNotApproveRouterToSpendInputTokenIfAlreadyApproved() public {
        vm.prank(address(zapStaker));
        inputToken.approve(ROUTER, type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            emptySwap1,
            emptySwap2
        );
    }

    function testSimulateStakeDoubleSwap_executesSwap1() public {
        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 0);
        zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            emptySwap1,
            emptySwap2
        );
    }

    function testSimulateStakeDoubleSwap_executesSwap1_revertsWithGenericErrorIfRouterGivesEmptyReason()
        public
    {
        bytes memory swap1 = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zapStaker.simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, emptySwap2);
    }

    function testSimulateStakeDoubleSwap_executesSwap1_revertsWithProvidedReason() public {
        bytes memory swap1 = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zapStaker.simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, emptySwap2);
    }

    function testSimulateStakeDoubleSwap_executesSwap2() public {
        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN1, 0);
        zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            emptySwap1,
            emptySwap2
        );
    }

    function testSimulateStakeDoubleSwap_executesSwap2_revertsWithGenericErrorIfRouterGivesEmptyReason()
        public
    {
        bytes memory swap2 = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zapStaker.simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, swap2);
    }

    function testSimulateStakeDoubleSwap_executesSwap2_revertsWithProvidedReason() public {
        bytes memory swap2 = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zapStaker.simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, swap2);
    }

    function testSimulateStakeDoubleSwap_callsIUniProxyForCurrentRatio() public {
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        vm.prank(testAccount0);
        _expectCall_getDepositAmount(address(hypervisor), address(token0), token0AcquiredFromSwap);
        zapStaker.simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2);
    }
}
