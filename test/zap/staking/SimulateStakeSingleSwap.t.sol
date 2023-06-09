// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.t.sol";

contract SimulateStakeSingleSwapTest is BaseSolidZapStakerTest {
    function testSimulateStakeSingleSwap_revertsIfInputTokenIsNotAHypervisorToken() public {
        vm.prank(testAccount0);
        _expectRevert_InvalidInput();
        zapStaker.simulateStakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1);
    }

    function testSimulateStakeSingleSwap_transfersOverTheInputTokenAmount() public {
        _overwriteToken0();
        vm.prank(testAccount0);
        _expectCall_ERC20_transferFrom(testAccount0, 1000);
        zapStaker.simulateStakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1);
    }

    function testSimulateStakeSingleSwap_approvesRouterToSpendInputToken() public {
        _overwriteToken0();
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zapStaker.simulateStakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1);

        uint actual = inputToken.allowance(address(zapStaker), ROUTER);
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeSingleSwap_doesNotApproveRouterToSpendInputTokenIfAlreadyApproved() public {
        _overwriteToken0();
        vm.prank(address(zapStaker));
        inputToken.approve(ROUTER, type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zapStaker.simulateStakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1);
    }

    function testSimulateStakeSingleSwap_executesSwap() public {
        _overwriteToken0();
        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 0);
        zapStaker.simulateStakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1);
    }

    function testSimulateStakeSingleSwap_executesSwap_revertsWithGenericErrorIfRouterGivesEmptyReason()
        public
    {
        _overwriteToken0();
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zapStaker.simulateStakeSingleSwap(address(inputToken), 1000, address(hypervisor), swap);
    }

    function testSimulateStakeSingleSwap_executesSwap_revertsWithProvidedReason() public {
        _overwriteToken0();
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zapStaker.simulateStakeSingleSwap(address(inputToken), 1000, address(hypervisor), swap);
    }

    function testSimulateStakeSingleSwap_callsIUniProxyForCurrentRatio() public {
        _overwriteToken0();
        uint inputAmount = 1000;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint remainingToken0BalanceAfterSwap = inputAmount; // in tests, tokens are not deducted when swapping

        vm.prank(testAccount0);
        _expectCall_getDepositAmount(address(hypervisor), address(token0), remainingToken0BalanceAfterSwap);
        zapStaker.simulateStakeSingleSwap(address(inputToken), inputAmount, address(hypervisor), swap);
    }

    function testSimulateStakeSingleSwap_ifDustless_deploysLiquidityIntoGammaAndReturns() public {
        _overwriteToken0();
        uint inputAmount = 1000;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;
        uint remainingToken0BalanceAfterSwap = inputAmount; // in tests, tokens are not deducted when swapping

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _expectCall_deposit(
            remainingToken0BalanceAfterSwap,
            token1AcquiredFromSwap,
            address(zapStaker),
            address(hypervisor),
            _uniProxyMinIn()
        );
        (bool actualIsDustless, uint actualShares, ISolidZapStaker.Fraction memory actualRatio) = zapStaker
            .simulateStakeSingleSwap(address(inputToken), inputAmount, address(hypervisor), swap);

        assertEq(actualIsDustless, true);
        assertEq(actualShares, sharesMinted);
        assertEq(actualRatio.numerator, 0);
        assertEq(actualRatio.denominator, 0);
    }

    function testSimulateStakeSingleSwap_ifDustless_approvesHypervisorToSpendToken0() public {
        _overwriteToken0();
        uint token1AcquiredFromSwap = 600;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _expectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeSingleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            swap
        );

        assertEq(actualIsDustless, true);
        uint actual = token0.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeSingleSwap_ifDustless_doesNotApproveHypervisorToSpendToken0IfAlreadyApproved()
        public
    {
        _overwriteToken0();
        vm.prank(address(zapStaker));
        token0.approve(address(hypervisor), type(uint).max);

        uint token1AcquiredFromSwap = 600;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _doNotExpectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeSingleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            swap
        );

        assertEq(actualIsDustless, true);
        uint actual = token0.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeSingleSwap_ifDustless_approvesHypervisorToSpendToken1() public {
        _overwriteToken0();
        uint token1AcquiredFromSwap = 600;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _expectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeSingleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            swap
        );

        assertEq(actualIsDustless, true);
        uint actual = token1.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeSingleSwap_ifDustless_doesNotApproveHypervisorToSpendToken1IfAlreadyApproved()
        public
    {
        _overwriteToken0();
        vm.prank(address(zapStaker));
        token1.approve(address(hypervisor), type(uint).max);

        uint token1AcquiredFromSwap = 600;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _doNotExpectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeSingleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            swap
        );

        assertEq(actualIsDustless, true);
        uint actual = token1.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeSingleSwap_ifNotDustless_doesNotDeployLiquidityAndReturnsCurrentRatio() public {
        _overwriteToken0();
        uint inputAmount = 1000;
        uint token1AcquiredFromSwap = 600;
        uint token1DustlessAmount = 800;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint remainingToken0BalanceAfterSwap = inputAmount; // in tests, tokens are not deducted when swapping

        vm.prank(testAccount0);
        _mockUniProxy_getDepositAmount(token1DustlessAmount);
        _doNotExpectCall_deposit();
        (bool actualIsDustless, uint actualShares, ISolidZapStaker.Fraction memory actualRatio) = zapStaker
            .simulateStakeSingleSwap(address(inputToken), inputAmount, address(hypervisor), swap);

        assertEq(actualIsDustless, false);
        assertEq(actualShares, 0);
        assertEq(actualRatio.numerator, remainingToken0BalanceAfterSwap);
        assertEq(actualRatio.denominator, token1DustlessAmount);
    }
}
