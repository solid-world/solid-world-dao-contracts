// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapCollateralize.sol";

contract ZapCollateralizeTest is BaseSolidZapCollateralizeTest {
    function testZapCollateralize_transferForwardCreditsFromUserToZap() public {
        uint amountIn = 100;

        vm.prank(testAccount0);
        _expectCall_ERC1155_safeTransferFrom(testAccount0, amountIn);
        zap.zapCollateralize(
            address(outputToken),
            address(crispToken),
            BATCH_ID,
            amountIn,
            0,
            emptySwap,
            testAccount1
        );

        uint userBalance = fcbt.balanceOf(testAccount0, BATCH_ID);
        assertEq(userBalance, INITIAL_TOKEN_AMOUNT - amountIn);
    }

    function testZapCollateralize_collateralizesTheForwardCredits() public {
        uint amountIn = 100;
        uint amountOutMin = 100 ether;

        vm.prank(testAccount0);
        _expectCall_collateralizeBatch(BATCH_ID, amountIn, amountOutMin);
        zap.zapCollateralize(
            address(outputToken),
            address(crispToken),
            BATCH_ID,
            amountIn,
            amountOutMin,
            emptySwap,
            testAccount1
        );

        uint zapForwardCreditsBalance = fcbt.balanceOf(address(zap), BATCH_ID);
        assertEq(zapForwardCreditsBalance, 0);
    }

    function testZapCollateralize_approvesRouterToSpendCrispToken() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(crispToken), ROUTER);
        zap.zapCollateralize(
            address(outputToken),
            address(crispToken),
            BATCH_ID,
            0,
            0,
            emptySwap,
            testAccount1
        );

        uint actual = crispToken.allowance(address(zap), ROUTER);
        assertEq(actual, type(uint).max);
    }

    function testZapCollateralize_doesNotApproveRouterToSpendCrispTokenIfAlreadyApproved() public {
        vm.prank(address(zap));
        crispToken.approve(ROUTER, type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(crispToken), ROUTER);
        zap.zapCollateralize(
            address(outputToken),
            address(crispToken),
            BATCH_ID,
            0,
            0,
            emptySwap,
            testAccount1
        );
    }

    function testZapCollateralize_executesSwap() public {
        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 0);
        zap.zapCollateralize(
            address(outputToken),
            address(crispToken),
            BATCH_ID,
            0,
            0,
            emptySwap,
            testAccount1
        );
    }

    function testZapCollateralize_executesSwap_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zap.zapCollateralize(address(outputToken), address(crispToken), BATCH_ID, 0, 0, swap, testAccount1);
    }

    function testZapCollateralize_executesSwap_revertsWithProvidedReason() public {
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zap.zapCollateralize(address(outputToken), address(crispToken), BATCH_ID, 0, 0, swap, testAccount1);
    }

    function testZapCollateralize_transfersOutputTokenBalanceToMsgSender() public {
        uint amountIn = 100;
        uint amountOutMin = 100 ether;
        uint expectedOutputTokenAmount = 50 ether;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, expectedOutputTokenAmount);

        vm.prank(testAccount0);
        zap.zapCollateralize(
            address(outputToken),
            address(crispToken),
            BATCH_ID,
            amountIn,
            amountOutMin,
            swap,
            testAccount1
        );

        uint actualOutputTokenAmount = outputToken.balanceOf(testAccount0);
        assertEq(actualOutputTokenAmount, expectedOutputTokenAmount);
    }

    function testZapCollateralize_transfersOutputTokenBalanceToReceiver() public {
        uint amountIn = 100;
        uint amountOutMin = 100 ether;
        uint expectedOutputTokenAmount = 50 ether;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, expectedOutputTokenAmount);

        vm.prank(testAccount0);
        zap.zapCollateralize(
            address(outputToken),
            address(crispToken),
            BATCH_ID,
            amountIn,
            amountOutMin,
            swap,
            testAccount1,
            testAccount1
        );

        uint actualOutputTokenAmount = outputToken.balanceOf(testAccount1);
        assertEq(actualOutputTokenAmount, expectedOutputTokenAmount);
    }

    function testZapCollateralize_transfersCrispTokenDustToDustReceiver() public {
        uint amountIn = 100;
        uint dust = 1 ether;

        vm.prank(testAccount0);
        zap.zapCollateralize(
            address(outputToken),
            address(crispToken),
            BATCH_ID,
            amountIn,
            dust,
            emptySwap,
            testAccount1
        );

        uint actualDustReceived = crispToken.balanceOf(testAccount1);
        assertEq(actualDustReceived, dust);
    }
}
