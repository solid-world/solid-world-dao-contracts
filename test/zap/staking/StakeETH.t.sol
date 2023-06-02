// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.t.sol";

contract StakeETHTest is BaseSolidZapStaker {
    function testApprovesRouterToSpendWETH() public {
        assertEq(weth.allowance(address(zapStaker), ROUTER), type(uint).max);
    }

    function testStakeETH_wrapsTheValueReceived() public {
        uint wethBalanceBefore = weth.balanceOf(address(zapStaker));

        hoax(testAccount0, 1 ether);
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);

        uint wethBalanceAfter = weth.balanceOf(address(zapStaker));
        assertEq(wethBalanceAfter - wethBalanceBefore, 1000);
        assertEq(testAccount0.balance, 1 ether - 1000);
    }

    function testStakeETH_executesSwap1() public {
        hoax(testAccount0, 1 ether);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 0);
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeETH_executesSwap1_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap1 = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        hoax(testAccount0, 1 ether);
        _expectRevert_GenericSwapError();
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), swap1, emptySwap2, 0);
    }

    function testStakeETH_executesSwap1_revertsWithProvidedReason() public {
        bytes memory swap1 = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        hoax(testAccount0, 1 ether);
        vm.expectRevert("invalid_swap");
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), swap1, emptySwap2, 0);
    }

    function testStakeETH_executesSwap2() public {
        hoax(testAccount0, 1 ether);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN1, 0);
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeETH_executesSwap2_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap2 = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        hoax(testAccount0, 1 ether);
        _expectRevert_GenericSwapError();
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, swap2, 0);
    }

    function testStakeETH_executesSwap2_revertsWithProvidedReason() public {
        bytes memory swap2 = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        hoax(testAccount0, 1 ether);
        vm.expectRevert("invalid_swap");
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, swap2, 0);
    }

    function testStakeETH_approvesHypervisorToSpendToken0() public {
        hoax(testAccount0, 1 ether);
        _expectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);

        uint actual = token0.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testStakeETH_doesNotApproveHypervisorToSpendToken0IfAlreadyApproved() public {
        vm.prank(address(zapStaker));
        token0.approve(address(hypervisor), type(uint).max);

        hoax(testAccount0, 1 ether);
        _doNotExpectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeETH_approvesHypervisorToSpendToken1() public {
        hoax(testAccount0, 1 ether);
        _expectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);

        uint actual = token1.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testStakeETH_doesNotApproveHypervisorToSpendToken1IfAlreadyApproved() public {
        vm.prank(address(zapStaker));
        token1.approve(address(hypervisor), type(uint).max);

        hoax(testAccount0, 1 ether);
        _doNotExpectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeETH_depositsViaIUniProxy_exactTokenAmountsAfterSwaps() public {
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;
        uint token0BalanceBeforeSwap = 1000;
        uint token1BalanceBeforeSwap = 1001;

        _setBalancesBeforeSwap(token0BalanceBeforeSwap, token1BalanceBeforeSwap);

        hoax(testAccount0, 1 ether);
        _mockUniProxy_deposit(sharesMinted);
        _expectCall_deposit(
            token0AcquiredFromSwap,
            token1AcquiredFromSwap,
            address(zapStaker),
            address(hypervisor),
            _uniProxyMinIn()
        );
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), swap1, swap2, 0);
    }

    function testStakeETH_depositsViaIUniProxy_revertsIfMintedSharesIsLessThanMin() public {
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;
        uint minShares = sharesMinted + 1;
        uint token0BalanceBeforeSwap = 1000;
        uint token1BalanceBeforeSwap = 1001;

        _setBalancesBeforeSwap(token0BalanceBeforeSwap, token1BalanceBeforeSwap);

        hoax(testAccount0, 1 ether);
        _mockUniProxy_deposit(sharesMinted);
        _expectRevert_AcquiredSharesLessThanMin(sharesMinted, minShares);
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), swap1, swap2, minShares);
    }

    function testStakeETH_approvesSolidStakingToSpendShares() public {
        hoax(testAccount0, 1 ether);
        _expectCall_ERC20_approve_maxUint(address(hypervisor), address(SOLIDSTAKING));
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);

        uint actual = hypervisor.allowance(address(zapStaker), address(SOLIDSTAKING));
        assertEq(actual, type(uint).max);
    }

    function testStakeETH_doesNotApproveSolidStakingToSpendSharesIfAlreadyApproved() public {
        vm.prank(address(zapStaker));
        hypervisor.approve(address(SOLIDSTAKING), type(uint).max);

        hoax(testAccount0, 1 ether);
        _doNotExpectCall_ERC20_approve_maxUint(address(hypervisor), address(SOLIDSTAKING));
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeETH_stakesSharesWithRecipient() public {
        uint sharesMinted = 1500;

        hoax(testAccount0, 1 ether);
        _mockUniProxy_deposit(sharesMinted);
        _expectCall_stake(address(hypervisor), sharesMinted, testAccount0);
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeETH_stakesSharesWithSpecifiedRecipient() public {
        uint sharesMinted = 1500;

        hoax(testAccount0, 1 ether);
        _mockUniProxy_deposit(sharesMinted);
        _expectCall_stake(address(hypervisor), sharesMinted, testAccount1);
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0, testAccount1);
    }

    function testStakeETH_returnsFinalStakedSharesAmount() public {
        uint sharesMinted = 1500;

        hoax(testAccount0, 1 ether);
        _mockUniProxy_deposit(sharesMinted);
        uint actual = zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);

        assertEq(actual, sharesMinted);
    }

    function testStakeETH_emitsZapStakeEvent() public {
        uint sharesMinted = 1500;

        hoax(testAccount0, 1 ether);
        _mockUniProxy_deposit(sharesMinted);
        _expectEmit_ZapStake(testAccount0, address(weth), 1000, sharesMinted);
        zapStaker.stakeETH{ value: 1000 }(address(hypervisor), emptySwap1, emptySwap2, 0);
    }
}
