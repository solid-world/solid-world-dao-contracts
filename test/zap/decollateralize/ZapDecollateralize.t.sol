// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapDecollateralize.sol";

contract ZapDecollateralizeTest is BaseSolidZapDecollateralizeTest {
    function testZapDecollateralize_transfersOverTheInputTokenAmount() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_transferFrom(testAccount0, 1000);
        zap.zapDecollateralize(
            address(inputToken),
            1000,
            address(crispToken),
            emptySwap,
            testAccount1,
            emptyParams
        );
    }

    function testZapDecollateralize_approvesRouterToSpendInputToken() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zap.zapDecollateralize(
            address(inputToken),
            1000,
            address(crispToken),
            emptySwap,
            testAccount1,
            emptyParams
        );

        uint actual = inputToken.allowance(address(zap), ROUTER);
        assertEq(actual, type(uint).max);
    }

    function testZapDecollateralize_doesNotApproveRouterToSpendInputTokenIfAlreadyApproved() public {
        vm.prank(address(zap));
        inputToken.approve(ROUTER, type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(inputToken), ROUTER);
        zap.zapDecollateralize(
            address(inputToken),
            1000,
            address(crispToken),
            emptySwap,
            testAccount1,
            emptyParams
        );
    }

    function testZapDecollateralize_executesSwap() public {
        vm.prank(testAccount0);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 0);
        zap.zapDecollateralize(
            address(inputToken),
            1000,
            address(crispToken),
            emptySwap,
            testAccount1,
            emptyParams
        );
    }

    function testZapDecollateralize_executesSwap_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        vm.prank(testAccount0);
        _expectRevert_GenericSwapError();
        zap.zapDecollateralize(
            address(inputToken),
            1000,
            address(crispToken),
            swap,
            testAccount1,
            emptyParams
        );
    }

    function testZapDecollateralize_executesSwap_revertsWithProvidedReason() public {
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        vm.prank(testAccount0);
        vm.expectRevert("invalid_swap");
        zap.zapDecollateralize(
            address(inputToken),
            1000,
            address(crispToken),
            swap,
            testAccount1,
            emptyParams
        );
    }

    function testZapDecollateralize_approvesSWMToSpendCrispToken() public {
        vm.prank(testAccount0);
        _expectCall_ERC20_approve_maxUint(address(crispToken), SWM);
        zap.zapDecollateralize(
            address(inputToken),
            1000,
            address(crispToken),
            emptySwap,
            testAccount1,
            emptyParams
        );

        uint actual = crispToken.allowance(address(zap), SWM);
        assertEq(actual, type(uint).max);
    }

    function testZapDecollateralize_doesNotApproveSWMToSpendCrispTokenIfAlreadyApproved() public {
        vm.prank(address(zap));
        crispToken.approve(SWM, type(uint).max);

        vm.prank(testAccount0);
        _doNotExpectCall_ERC20_approve_maxUint(address(crispToken), SWM);
        zap.zapDecollateralize(
            address(inputToken),
            1000,
            address(crispToken),
            emptySwap,
            testAccount1,
            emptyParams
        );
    }

    function testZapDecollateralize_decollateralizesTokens() public {
        ISolidZapDecollateralize.DecollateralizeParams memory params = ISolidZapDecollateralize
            .DecollateralizeParams({
                batchIds: _toArray(1),
                amountsIn: _toArray(123),
                amountsOutMin: _toArray(150)
            });
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, params.amountsIn[0]);

        vm.prank(testAccount0);
        _expectCall_bulkDecollateralizeTokens(params.batchIds, params.amountsIn, params.amountsOutMin);
        _expectCall_onERC1155Received(SWM, address(0), params.batchIds[0], params.amountsOutMin[0], "");
        zap.zapDecollateralize(address(inputToken), 1000, address(crispToken), swap, testAccount1, params);

        uint actualCrispBalance = crispToken.balanceOf(address(zap));
        assertEq(actualCrispBalance, 0);
        uint[] memory actualCreditsBalance = fcbt.balanceOfBatch(_toArray(testAccount0), params.batchIds);
        assertEq(actualCreditsBalance, params.amountsOutMin);
    }

    function testZapDecollateralize_transfersDust() public {
        ISolidZapDecollateralize.DecollateralizeParams memory params = ISolidZapDecollateralize
            .DecollateralizeParams({
                batchIds: _toArray(1),
                amountsIn: _toArray(123),
                amountsOutMin: _toArray(150)
            });
        uint dust = 1;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, params.amountsIn[0] + dust);

        vm.prank(testAccount0);
        zap.zapDecollateralize(address(inputToken), 1000, address(crispToken), swap, testAccount1, params);

        uint actual = crispToken.balanceOf(testAccount1);
        assertEq(actual, dust);
    }

    function testZapDecollateralize_emitsEvent() public {
        ISolidZapDecollateralize.DecollateralizeParams memory params = ISolidZapDecollateralize
            .DecollateralizeParams({
                batchIds: _toArray(1),
                amountsIn: _toArray(123),
                amountsOutMin: _toArray(150)
            });
        uint dust = 1;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, params.amountsIn[0] + dust);

        vm.prank(testAccount0);
        _expectEmit_ZapDecollateralize(testAccount0, address(inputToken), 1000, 1, testAccount1, 1);
        zap.zapDecollateralize(address(inputToken), 1000, address(crispToken), swap, testAccount1, params);
    }

    function testZapDecollateralize_emitsEvent_customReceiver() public {
        ISolidZapDecollateralize.DecollateralizeParams memory params = ISolidZapDecollateralize
            .DecollateralizeParams({
                batchIds: _toArray(1),
                amountsIn: _toArray(123),
                amountsOutMin: _toArray(150)
            });
        uint dust = 1;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, params.amountsIn[0] + dust);

        vm.prank(testAccount0);
        _expectEmit_ZapDecollateralize(testAccount1, address(inputToken), 1000, 1, testAccount1, 1);
        zap.zapDecollateralize(
            address(inputToken),
            1000,
            address(crispToken),
            swap,
            testAccount1,
            params,
            testAccount1
        );
    }
}
