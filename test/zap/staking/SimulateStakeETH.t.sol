// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.sol";

contract SimulateStakeETHTest is BaseSolidZapStakerTest {
    function testSimulateStakeETH_wrapsTheValueReceived() public {
        uint wethBalanceBefore = weth.balanceOf(address(zapStaker));

        hoax(testAccount0, 1 ether);
        zapStaker.simulateStakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2);

        uint wethBalanceAfter = weth.balanceOf(address(zapStaker));
        assertEq(wethBalanceAfter - wethBalanceBefore, 1000);
        assertEq(testAccount0.balance, 1 ether - 1000);
    }

    function testSimulateStakeETH_executesSwap1() public {
        hoax(testAccount0, 1 ether);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 0);
        zapStaker.simulateStakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2);
    }

    function testSimulateStakeETH_executesSwap1_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap1 = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        hoax(testAccount0, 1 ether);
        _expectRevert_GenericSwapError();
        zapStaker.simulateStakeETH{ value: 1000 }(address(hypervisor), swap1, emptySwap2);
    }

    function testSimulateStakeETH_executesSwap1_revertsWithProvidedReason() public {
        bytes memory swap1 = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        hoax(testAccount0, 1 ether);
        vm.expectRevert("invalid_swap");
        zapStaker.simulateStakeETH{ value: 1000 }(address(hypervisor), swap1, emptySwap2);
    }

    function testSimulateStakeETH_executesSwap2() public {
        hoax(testAccount0, 1 ether);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN1, 0);
        zapStaker.simulateStakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2);
    }

    function testSimulateStakeETH_executesSwap2_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap2 = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        hoax(testAccount0, 1 ether);
        _expectRevert_GenericSwapError();
        zapStaker.simulateStakeETH{ value: 1000 }(address(hypervisor), emptySwap1, swap2);
    }

    function testSimulateStakeETH_executesSwap2_revertsWithProvidedReason() public {
        bytes memory swap2 = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        hoax(testAccount0, 1 ether);
        vm.expectRevert("invalid_swap");
        zapStaker.simulateStakeETH{ value: 1000 }(address(hypervisor), emptySwap1, swap2);
    }

    function testSimulateStakeETH_callsIUniProxyForCurrentRatio() public {
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        hoax(testAccount0, 1 ether);
        _expectCall_getDepositAmount(address(hypervisor), address(token0), token0AcquiredFromSwap);
        zapStaker.simulateStakeETH{ value: 1000 }(address(hypervisor), swap1, swap2);
    }

    function testSimulateStakeETH_ifDustless_deploysLiquidityIntoGammaAndReturns() public {
        uint sharesMinted = 100;
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        hoax(testAccount0, 1 ether);
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
            .simulateStakeETH{ value: 1000 }(address(hypervisor), swap1, swap2);

        assertEq(actualIsDustless, true);
        assertEq(actualShares, sharesMinted);
        assertEq(actualRatio.numerator, 0);
        assertEq(actualRatio.denominator, 0);
    }

    function testSimulateStakeETH_ifDustless_approvesHypervisorToSpendToken0() public {
        uint sharesMinted = 100;
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        hoax(testAccount0, 1 ether);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _expectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeETH{ value: 1000 }(
            address(hypervisor),
            swap1,
            swap2
        );

        assertEq(actualIsDustless, true);
        uint actual = token0.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeETH_ifDustless_doesNotApproveHypervisorToSpendToken0IfAlreadyApproved() public {
        vm.prank(address(zapStaker));
        token0.approve(address(hypervisor), type(uint).max);

        uint sharesMinted = 100;
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        hoax(testAccount0, 1 ether);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _doNotExpectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeETH{ value: 1000 }(
            address(hypervisor),
            swap1,
            swap2
        );

        assertEq(actualIsDustless, true);
        uint actual = token0.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeETH_ifDustless_approvesHypervisorToSpendToken1() public {
        uint sharesMinted = 100;
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        hoax(testAccount0, 1 ether);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _expectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeETH{ value: 1000 }(
            address(hypervisor),
            swap1,
            swap2
        );

        assertEq(actualIsDustless, true);
        uint actual = token1.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeETH_ifDustless_doesNotApproveHypervisorToSpendToken1IfAlreadyApproved() public {
        vm.prank(address(zapStaker));
        token1.approve(address(hypervisor), type(uint).max);

        uint sharesMinted = 100;
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        hoax(testAccount0, 1 ether);
        _mockUniProxy_deposit(sharesMinted);
        _mockUniProxy_getDepositAmount(token1AcquiredFromSwap);
        _doNotExpectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        (bool actualIsDustless, , ) = zapStaker.simulateStakeETH{ value: 1000 }(
            address(hypervisor),
            swap1,
            swap2
        );

        assertEq(actualIsDustless, true);
        uint actual = token1.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testSimulateStakeETH_ifNotDustless_doesNotDeployLiquidityAndReturnsCurrentRatio() public {
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        uint token1DustlessAmount = 800;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);

        hoax(testAccount0, 1 ether);
        _mockUniProxy_getDepositAmount(token1DustlessAmount);
        _doNotExpectCall_deposit();
        (bool actualIsDustless, uint actualShares, ISolidZapStaker.Fraction memory actualRatio) = zapStaker
            .simulateStakeETH{ value: 1000 }(address(hypervisor), swap1, swap2);

        assertEq(actualIsDustless, false);
        assertEq(actualShares, 0);
        assertEq(actualRatio.numerator, token0AcquiredFromSwap);
        assertEq(actualRatio.denominator, token1DustlessAmount);
    }
}
