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

        uint zapCrispBalance = crispToken.balanceOf(address(zap));
        assertEq(zapCrispBalance, amountOutMin);
        uint zapForwardCreditsBalance = fcbt.balanceOf(address(zap), BATCH_ID);
        assertEq(zapForwardCreditsBalance, 0);
    }
}
