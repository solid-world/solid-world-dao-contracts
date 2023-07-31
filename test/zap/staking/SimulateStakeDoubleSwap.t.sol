// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.sol";

contract SimulateStakeDoubleSwapTest is BaseSolidZapStakerTest {
    function testSimulateStakeDoubleSwap_transfersOverTheInputTokenAmount() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_transferFrom(testAccount0, 1000);
        zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            basicSwap0,
            basicSwap1
        );
    }

    function testSimulateStakeDoubleSwap_approvesRouterToSpendInputToken() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            basicSwap0,
            basicSwap1
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
            basicSwap0,
            basicSwap1
        );
    }

    function testSimulateStakeDoubleSwap_executesSwap0() public {
        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 1);
        zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            basicSwap0,
            basicSwap1
        );
    }

    function testSimulateStakeDoubleSwap_executesSwap0_revertsWithGenericErrorIfRouterGivesEmptyReason()
        public
    {
        bytes memory swap1 = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zapStaker.simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, basicSwap1);
    }

    function testSimulateStakeDoubleSwap_executesSwap0_revertsWithProvidedReason() public {
        bytes memory swap1 = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zapStaker.simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, basicSwap1);
    }

    function testSimulateStakeDoubleSwap_executesSwap1() public {
        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN1, 1);
        zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            basicSwap0,
            basicSwap1
        );
    }

    function testSimulateStakeDoubleSwap_executesSwap1_revertsWithGenericErrorIfRouterGivesEmptyReason()
        public
    {
        bytes memory swap2 = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zapStaker.simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), basicSwap0, swap2);
    }

    function testSimulateStakeDoubleSwap_executesSwap1_revertsWithProvidedReason() public {
        bytes memory swap2 = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zapStaker.simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), basicSwap0, swap2);
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

    function testSimulateStakeDoubleSwap_ifDustless_deploysLiquidityIntoGammaAndReturns() public {
        uint sharesMinted = 100;
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _expectCall_deposit(
            token0AcquiredFromSwap,
            token1AcquiredFromSwap,
            address(zapStaker),
            address(hypervisor),
            _uniProxyMinIn()
        );
        (bool actualIsDustless, uint actualShares, ISolidZapStaker.Fraction memory actualRatio) = zapStaker
            .simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2);

        assertEq(actualIsDustless, true);
        assertEq(actualShares, sharesMinted);
        assertEq(actualRatio.numerator, 0);
        assertEq(actualRatio.denominator, 0);
    }

    function testSimulateStakeDoubleSwap_ifDustless_approvesHypervisorToSpendToken0() public {
        uint sharesMinted = 100;
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _expectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            swap1,
            swap2
        );

        assertEq(actualIsDustless, true);
        uint actual = token0.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeDoubleSwap_ifDustless_doesNotApproveHypervisorToSpendToken0IfAlreadyApproved()
        public
    {
        vm.prank(address(zapStaker));
        token0.approve(address(hypervisor), type(uint).max);

        uint sharesMinted = 100;
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _doNotExpectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            swap1,
            swap2
        );

        assertEq(actualIsDustless, true);
        uint actual = token0.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeDoubleSwap_ifDustless_approvesHypervisorToSpendToken1() public {
        uint sharesMinted = 100;
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _expectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            swap1,
            swap2
        );

        assertEq(actualIsDustless, true);
        uint actual = token1.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeDoubleSwap_ifDustless_doesNotApproveHypervisorToSpendToken1IfAlreadyApproved()
        public
    {
        vm.prank(address(zapStaker));
        token1.approve(address(hypervisor), type(uint).max);

        uint sharesMinted = 100;
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _doNotExpectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            swap1,
            swap2
        );

        assertEq(actualIsDustless, true);
        uint actual = token1.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeDoubleSwap_ifNotDustless_doesNotDeployLiquidityAndReturnsCurrentRatio() public {
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        uint token1DustlessAmount = 800;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        vm.prank(testAccount0);
        _mockUniProxy_getDepositAmount(token1DustlessAmount);
        _doNotExpectCall_deposit();
        (bool actualIsDustless, uint actualShares, ISolidZapStaker.Fraction memory actualRatio) = zapStaker
            .simulateStakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2);

        assertEq(actualIsDustless, false);
        assertEq(actualShares, 0);
        assertEq(actualRatio.numerator, token0AcquiredFromSwap);
        assertEq(actualRatio.denominator, token1DustlessAmount);
    }
}
