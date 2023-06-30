// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.sol";

contract StakeSingleSwapTest is BaseSolidZapStakerTest {
    function testStakeSingleSwap_revertsIfInputTokenIsNotAHypervisorToken() public {
        vm.prank(testAccount0);
        _expectRevert_InvalidInput();
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);
    }

    function testStakeSingleSwap_transfersOverTheInputTokenAmount() public {
        _overwriteToken0();
        vm.prank(testAccount0);
        _expectCall_ERC20_transferFrom(testAccount0, 1000);
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);
    }

    function testStakeSingleSwap_approvesRouterToSpendInputToken() public {
        _overwriteToken0();
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);

        uint actual = inputToken.allowance(address(zapStaker), ROUTER);
        assertEq(actual, type(uint).max);
    }

    function testStakeSingleSwap_doesNotApproveRouterToSpendInputTokenIfAlreadyApproved() public {
        _overwriteToken0();
        vm.prank(address(zapStaker));
        inputToken.approve(ROUTER, type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);
    }

    function testStakeSingleSwap_executesSwap() public {
        _overwriteToken0();
        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 0);
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);
    }

    function testStakeSingleSwap_executesSwap_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        _overwriteToken0();
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), swap, 0);
    }

    function testStakeSingleSwap_executesSwap_revertsWithProvidedReason() public {
        _overwriteToken0();
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), swap, 0);
    }

    function testStakeSingleSwap_approvesHypervisorToSpendToken0() public {
        _overwriteToken0();

        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);

        uint actual = token0.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testStakeSingleSwap_doesNotApproveHypervisorToSpendToken0IfAlreadyApproved() public {
        _overwriteToken0();
        vm.prank(address(zapStaker));
        token0.approve(address(hypervisor), type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(token0), address(hypervisor));
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);
    }

    function testStakeSingleSwap_approvesHypervisorToSpendToken1() public {
        _overwriteToken0();
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);

        uint actual = token1.allowance(address(zapStaker), address(hypervisor));
        assertEq(actual, type(uint).max);
    }

    function testStakeSingleSwap_doesNotApproveHypervisorToSpendToken1IfAlreadyApproved() public {
        _overwriteToken0();
        vm.prank(address(zapStaker));
        token1.approve(address(hypervisor), type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(token1), address(hypervisor));
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);
    }

    function testStakeSingleSwap_depositsViaIUniProxy_exactTokenAmountsAfterSwap() public {
        _overwriteToken0();
        uint inputAmount = 1000;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;
        uint remainingToken0BalanceAfterSwap = inputAmount; // in tests, tokens are not deducted when swapping

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _expectCall_deposit(
            remainingToken0BalanceAfterSwap,
            token1AcquiredFromSwap,
            address(zapStaker),
            address(hypervisor),
            _uniProxyMinIn()
        );
        zapStaker.stakeSingleSwap(address(inputToken), inputAmount, address(hypervisor), swap, 0);
    }

    function testStakeSingleSwap_depositsViaIUniProxy_revertsIfMintedSharesIsLessThanMin() public {
        _overwriteToken0();
        uint inputAmount = 1000;
        uint token1AcquiredFromSwap = 600;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, token1AcquiredFromSwap);
        uint sharesMinted = 100;
        uint minShares = sharesMinted + 1;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _expectRevert_AcquiredSharesLessThanMin(sharesMinted, minShares);
        zapStaker.stakeSingleSwap(address(inputToken), inputAmount, address(hypervisor), swap, minShares);
    }

    function testStakeSingleSwap_approvesSolidStakingToSpendShares() public {
        _overwriteToken0();
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(hypervisor), address(SOLIDSTAKING));
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);

        uint actual = hypervisor.allowance(address(zapStaker), address(SOLIDSTAKING));
        assertEq(actual, type(uint).max);
    }

    function testStakeSingleSwap_doesNotApproveSolidStakingToSpendSharesIfAlreadyApproved() public {
        _overwriteToken0();
        vm.prank(address(zapStaker));
        hypervisor.approve(address(SOLIDSTAKING), type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(hypervisor), address(SOLIDSTAKING));
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);
    }

    function testStakeSingleSwap_stakesSharesWithRecipient() public {
        _overwriteToken0();
        uint sharesMinted = 1500;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _expectCall_stake(address(hypervisor), sharesMinted, testAccount0);
        zapStaker.stakeSingleSwap(address(inputToken), 1000, address(hypervisor), emptySwap1, 0);
    }

    function testStakeSingleSwap_stakesSharesWithSpecifiedRecipient() public {
        _overwriteToken0();
        uint sharesMinted = 1500;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _expectCall_stake(address(hypervisor), sharesMinted, testAccount1);
        zapStaker.stakeSingleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            emptySwap1,
            0,
            testAccount1
        );
    }

    function testStakeSingleSwap_returnsFinalStakedSharesAmount() public {
        _overwriteToken0();
        uint sharesMinted = 1500;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        uint actual = zapStaker.stakeSingleSwap(
            address(inputToken),
            1000,
            address(hypervisor),
            emptySwap1,
            0
        );

        assertEq(actual, sharesMinted);
    }

    function testStakeSingleSwap_emitsZapStakeEvent() public {
        _overwriteToken0();
        uint inputAmount = 1000;
        uint sharesMinted = 1500;

        vm.prank(testAccount0);
        _mockUniProxy_deposit(sharesMinted);
        _expectEmit_ZapStake(testAccount0, address(inputToken), inputAmount, sharesMinted);
        zapStaker.stakeSingleSwap(address(inputToken), inputAmount, address(hypervisor), emptySwap1, 0);
    }
}
