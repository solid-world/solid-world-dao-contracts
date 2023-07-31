// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapCollateralize.sol";

contract ZapCollateralizeETHTest is BaseSolidZapCollateralizeTest {
    function testZapCollateralizeETH_transferForwardCreditsFromUserToZap() public {
        _prepareMinWethOutputAmount();

        uint amountIn = 100;

        vm.prank(testAccount0);
        _expectCall_ERC1155_safeTransferFrom(testAccount0, amountIn);
        zap.zapCollateralizeETH(address(crispToken), BATCH_ID, amountIn, 0, basicSwap, testAccount1);

        uint userBalance = fcbt.balanceOf(testAccount0, BATCH_ID);
        assertEq(userBalance, INITIAL_TOKEN_AMOUNT - amountIn);
    }

    function testZapCollateralizeETH_collateralizesTheForwardCredits() public {
        _prepareMinWethOutputAmount();

        uint amountIn = 100;
        uint amountOutMin = 100 ether;

        vm.prank(testAccount0);
        _expectCall_collateralizeBatch(BATCH_ID, amountIn, amountOutMin);
        zap.zapCollateralizeETH(
            address(crispToken),
            BATCH_ID,
            amountIn,
            amountOutMin,
            basicSwap,
            testAccount1
        );

        uint zapForwardCreditsBalance = fcbt.balanceOf(address(zap), BATCH_ID);
        assertEq(zapForwardCreditsBalance, 0);
    }

    function testZapCollateralizeETH_approvesRouterToSpendCrispToken() public {
        _prepareMinWethOutputAmount();

        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(crispToken), ROUTER);
        zap.zapCollateralizeETH(address(crispToken), BATCH_ID, 0, 0, basicSwap, testAccount1);

        uint actual = crispToken.allowance(address(zap), ROUTER);
        assertEq(actual, type(uint).max);
    }

    function testZapCollateralizeETH_doesNotApproveRouterToSpendCrispTokenIfAlreadyApproved() public {
        _prepareMinWethOutputAmount();

        vm.prank(address(zap));
        crispToken.approve(ROUTER, type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(crispToken), ROUTER);
        zap.zapCollateralizeETH(address(crispToken), BATCH_ID, 0, 0, basicSwap, testAccount1);
    }

    function testZapCollateralizeETH_executesSwap() public {
        _prepareMinWethOutputAmount();

        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 1);
        zap.zapCollateralizeETH(address(crispToken), BATCH_ID, 0, 0, basicSwap, testAccount1);
    }

    function testZapCollateralizeETH_executesSwap_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zap.zapCollateralizeETH(address(crispToken), BATCH_ID, 0, 0, swap, testAccount1);
    }

    function testZapCollateralizeETH_executesSwap_revertsWithProvidedReason() public {
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zap.zapCollateralizeETH(address(crispToken), BATCH_ID, 0, 0, swap, testAccount1);
    }

    function testZapCollateralizeETH_unwrapsWETH() public {
        uint wethOutputAmount = _prepareWethOutputAmount(1 ether);

        vm.prank(testAccount0);
        _expectCall_withdraw(wethOutputAmount);
        zap.zapCollateralizeETH(address(crispToken), BATCH_ID, 0, 0, basicSwap, testAccount1);
    }

    function testZapCollateralizeETH_transfersETHBalanceToMsgSender() public {
        uint amountIn = 100;
        uint amountOutMin = 100 ether;
        uint wethOutputAmount = _prepareWethOutputAmount(1 ether);

        vm.prank(testAccount0);
        zap.zapCollateralizeETH(
            address(crispToken),
            BATCH_ID,
            amountIn,
            amountOutMin,
            basicSwap,
            testAccount1
        );

        uint actualETHAmount = testAccount0.balance;
        assertEq(actualETHAmount, wethOutputAmount);
    }

    function testZapCollateralizeETH_transfersETHTokenBalanceToReceiver() public {
        uint amountIn = 100;
        uint amountOutMin = 100 ether;
        uint wethOutputAmount = _prepareWethOutputAmount(1 ether);

        vm.prank(testAccount0);
        zap.zapCollateralizeETH(
            address(crispToken),
            BATCH_ID,
            amountIn,
            amountOutMin,
            basicSwap,
            testAccount1,
            testAccount1
        );

        uint actualETHAmount = testAccount1.balance;
        assertEq(actualETHAmount, wethOutputAmount);
    }

    function testZapCollateralizeETH_transfersCrispTokenDustToDustRecipient() public {
        _prepareMinWethOutputAmount();

        uint amountIn = 100;
        uint dust = 1 ether;

        vm.prank(testAccount0);
        zap.zapCollateralizeETH(address(crispToken), BATCH_ID, amountIn, dust, basicSwap, testAccount1);

        uint actualDustReceived = crispToken.balanceOf(testAccount1);
        assertEq(actualDustReceived, dust);
    }

    function testZapCollateralizeETH_emitsEvent() public {
        uint amountIn = 100;
        uint amountOutMin = 100 ether;
        uint wethOutputAmount = _prepareWethOutputAmount(1 ether);

        vm.prank(testAccount0);
        _expectEmit_ZapCollateralize(
            testAccount0,
            address(weth),
            wethOutputAmount,
            amountOutMin,
            testAccount1,
            1
        );
        zap.zapCollateralizeETH(
            address(crispToken),
            BATCH_ID,
            amountIn,
            amountOutMin,
            basicSwap,
            testAccount1
        );
    }

    function testZapCollateralizeETH_emitsEvent_customRecipient() public {
        uint amountIn = 100;
        uint amountOutMin = 100 ether;
        uint wethOutputAmount = _prepareWethOutputAmount(1 ether);

        vm.prank(testAccount0);
        _expectEmit_ZapCollateralize(
            testAccount1,
            address(weth),
            wethOutputAmount,
            amountOutMin,
            testAccount1,
            1
        );
        zap.zapCollateralizeETH(
            address(crispToken),
            BATCH_ID,
            amountIn,
            amountOutMin,
            basicSwap,
            testAccount1,
            testAccount1
        );
    }
}
