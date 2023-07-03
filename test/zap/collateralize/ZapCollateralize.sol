// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapCollateralize.sol";

contract ZapCollateralizeTest is BaseSolidZapCollateralizeTest {
    function testZapCollateralize_transferForwardCreditsFromUserToZap() public {
        uint amountIn = 100;

        vm.prank(testAccount0);
        zap.zapCollateralize(
            address(outputToken),
            address(crispToken),
            BATCH_ID,
            amountIn,
            0,
            emptySwap,
            testAccount1
        );

        uint zapBalance = fcbt.balanceOf(address(zap), BATCH_ID);
        assertEq(zapBalance, amountIn);

        uint userBalance = fcbt.balanceOf(testAccount0, BATCH_ID);
        assertEq(userBalance, INITIAL_TOKEN_AMOUNT - amountIn);
    }
}
