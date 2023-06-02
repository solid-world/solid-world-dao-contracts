// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.t.sol";

contract StakeDoubleSwapTest is BaseSolidZapStaker {
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
        vm.prank(testAccount0);
        _expectCall_ERC20_transferFrom(testAccount0, 1000);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeDoubleSwap_approvesRouterToSpendInputToken() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);

        uint actual = inputToken.allowance(address(zapStaker), ROUTER);
        assertEq(actual, type(uint).max);
    }

    function testStakeDoubleSwap_doesNotApproveRouterToSpendInputTokenIfAlreadyApproved() public {
        vm.prank(address(zapStaker));
        inputToken.approve(ROUTER, type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeDoubleSwap_executesSwap1() public {
        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 0);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeDoubleSwap_executesSwap1_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap1 = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, emptySwap2, 0);
    }

    function testStakeDoubleSwap_executesSwap1_revertsWithProvidedReason() public {
        bytes memory swap1 = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, emptySwap2, 0);
    }

    function testStakeDoubleSwap_executesSwap2() public {
        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN1, 0);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeDoubleSwap_executesSwap2_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap2 = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, swap2, 0);
    }

    function testStakeDoubleSwap_executesSwap2_revertsWithProvidedReason() public {
        bytes memory swap2 = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, swap2, 0);
    }

    function testStakeDoubleSwap_approvesHypervisorToSpendToken0() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);

        uint actual = token0.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testStakeDoubleSwap_doesNotApproveHypervisorToSpendToken0IfAlreadyApproved() public {
        vm.prank(address(zapStaker));
        token0.approve(address(hypervisor), type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeDoubleSwap_approvesHypervisorToSpendToken1() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);

        uint actual = token1.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testStakeDoubleSwap_doesNotApproveHypervisorToSpendToken1IfAlreadyApproved() public {
        vm.prank(address(zapStaker));
        token1.approve(address(hypervisor), type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeDoubleSwap_depositsViaIUniProxy_exactTokenAmountsAfterSwaps() public {
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;
        uint token0BalanceBeforeSwap = 1000;
        uint token1BalanceBeforeSwap = 1001;

        _setBalancesBeforeSwap(token0BalanceBeforeSwap, token1BalanceBeforeSwap);

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _expectCall_deposit(
            token0AcquiredFromSwap,
            token1AcquiredFromSwap,
            address(zapStaker),
            address(hypervisor),
            _uniProxyMinIn()
        );
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, 0);
    }

    function testStakeDoubleSwap_depositsViaIUniProxy_revertsIfMintedSharesIsLessThanMin() public {
        uint token0AcquiredFromSwap = 500;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, token0AcquiredFromSwap);
        bytes memory swap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;
        uint minShares = sharesMinted + 1;
        uint token0BalanceBeforeSwap = 1000;
        uint token1BalanceBeforeSwap = 1001;

        _setBalancesBeforeSwap(token0BalanceBeforeSwap, token1BalanceBeforeSwap);

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _expectRevert_AcquiredSharesLessThanMin(sharesMinted, minShares);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), swap1, swap2, minShares);
    }

    function testStakeDoubleSwap_approvesSolidStakingToSpendShares() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(hypervisor), address(SOLIDSTAKING));
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);

        uint actual = hypervisor.allowance(address(zapStaker), address(SOLIDSTAKING));
        assertEq(actual, type(uint).max);
    }

    function testStakeDoubleSwap_doesNotApproveSolidStakingToSpendSharesIfAlreadyApproved() public {
        vm.prank(address(zapStaker));
        hypervisor.approve(address(SOLIDSTAKING), type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(hypervisor), address(SOLIDSTAKING));
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeDoubleSwap_stakesSharesWithRecipient() public {
        uint sharesMinted = 1500;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _expectCall_stake(address(hypervisor), sharesMinted, testAccount0);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);
    }

    function testStakeDoubleSwap_stakesSharesWithSpecifiedRecipient() public {
        uint sharesMinted = 1500;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _expectCall_stake(address(hypervisor), sharesMinted, testAccount1);
        zapStaker.stakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            emptySwap1,
            emptySwap2,
            0,
            testAccount1
        );
    }

    function testStakeDoubleSwap_returnsFinalStakedSharesAmount() public {
        uint sharesMinted = 1500;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        uint actual = zapStaker.stakeDoubleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            emptySwap1,
            emptySwap2,
            0
        );

        assertEq(actual, sharesMinted);
    }

    function testStakeDoubleSwap_emitsZapStakeEvent() public {
        uint sharesMinted = 1500;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _expectEmit_ZapStake(testAccount0, address(inputToken), 1000, sharesMinted);
        zapStaker.stakeDoubleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, emptySwap2, 0);
    }
}
