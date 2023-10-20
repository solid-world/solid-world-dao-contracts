// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BaseSolidZapDecollateralize.sol";

contract ZapDecollateralizeETHTest is BaseSolidZapDecollateralizeTest {
    function testZapDecollateralizeETH_wrapsTheValueReceived() public {
        hoax(testAccount0, 1 ether);
        _expectCall_deposit(1000);
        zap.zapDecollateralizeETH{ value: 1000 }(address(crispToken), basicSwap, testAccount1, emptyParams);
    }

    function testZapDecollateralizeETH_executesSwap() public {
        hoax(testAccount0, 1 ether);
        _expectCall_swap(RouterBehaviour.MINTS_TOKEN0, 1);
        zap.zapDecollateralizeETH{ value: 1000 }(address(crispToken), basicSwap, testAccount1, emptyParams);
    }

    function testZapDecollateralizeETH_executesSwap_revertsWithGenericErrorIfRouterGivesEmptyReason() public {
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_NO_REASON, 0);

        hoax(testAccount0, 1 ether);
        _expectRevert_GenericSwapError();
        zap.zapDecollateralizeETH{ value: 1000 }(address(crispToken), swap, testAccount1, emptyParams);
    }

    function testZapDecollateralizeETH_executesSwap_revertsWithProvidedReason() public {
        bytes memory swap = _encodeSwap(RouterBehaviour.REVERTS_WITH_REASON, 0);

        hoax(testAccount0, 1 ether);
        vm.expectRevert("invalid_swap");
        zap.zapDecollateralizeETH{ value: 1000 }(address(crispToken), swap, testAccount1, emptyParams);
    }

    function testZapDecollateralizeETH_approvesSWMToSpendCrispToken() public {
        hoax(testAccount0, 1 ether);
        _expectCall_ERC20_approve_maxUint(address(crispToken), SWM);
        zap.zapDecollateralizeETH{ value: 1000 }(address(crispToken), basicSwap, testAccount1, emptyParams);

        uint actual = crispToken.allowance(address(zap), SWM);
        assertEq(actual, type(uint).max);
    }

    function testZapDecollateralizeETH_doesNotApproveSWMToSpendCrispTokenIfAlreadyApproved() public {
        vm.prank(address(zap));
        crispToken.approve(SWM, type(uint).max);

        hoax(testAccount0, 1 ether);
        _doNotExpectCall_ERC20_approve_maxUint(address(crispToken), SWM);
        zap.zapDecollateralizeETH{ value: 1000 }(address(crispToken), basicSwap, testAccount1, emptyParams);
    }

    function testZapDecollateralizeETH_decollateralizesTokens() public {
        ISolidZapDecollateralize.DecollateralizeParams memory params = ISolidZapDecollateralize
            .DecollateralizeParams({
                batchIds: _toArray(1),
                amountsIn: _toArray(123),
                amountsOutMin: _toArray(150)
            });
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, params.amountsIn[0]);

        hoax(testAccount0, 1 ether);
        _expectCall_bulkDecollateralizeTokens(params.batchIds, params.amountsIn, params.amountsOutMin);
        _expectCall_onERC1155Received(SWM, address(0), params.batchIds[0], params.amountsOutMin[0] + 1, "");
        zap.zapDecollateralizeETH{ value: 1000 }(address(crispToken), swap, testAccount1, params);

        uint actualCrispBalance = crispToken.balanceOf(address(zap));
        assertEq(actualCrispBalance, 0);
        uint[] memory actualCreditsBalance = fcbt.balanceOfBatch(_toArray(testAccount0), params.batchIds);
        assertEq(actualCreditsBalance, _toArray(params.amountsOutMin[0] + 1));
    }

    function testZapDecollateralizeETH_transfersDust() public {
        ISolidZapDecollateralize.DecollateralizeParams memory params = ISolidZapDecollateralize
            .DecollateralizeParams({
                batchIds: _toArray(1),
                amountsIn: _toArray(123),
                amountsOutMin: _toArray(150)
            });
        uint dust = 1;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, params.amountsIn[0] + dust);

        hoax(testAccount0, 1 ether);
        zap.zapDecollateralizeETH{ value: 1000 }(address(crispToken), swap, testAccount1, params);

        uint actual = crispToken.balanceOf(testAccount1);
        assertEq(actual, dust);
    }

    function testZapDecollateralizeETH_returnsUnusedETHToReceiver() public {
        hoax(testAccount0, 1 ether);
        _expectCall_withdraw(1000);
        zap.zapDecollateralizeETH{ value: 1000 }(
            address(crispToken),
            basicSwap,
            testAccount1,
            emptyParams,
            testAccount1
        );

        assertEq(address(testAccount1).balance, 1000);
    }

    function testZapDecollateralizeETH_emitsEvent() public {
        ISolidZapDecollateralize.DecollateralizeParams memory params = ISolidZapDecollateralize
            .DecollateralizeParams({
                batchIds: _toArray(1),
                amountsIn: _toArray(123),
                amountsOutMin: _toArray(150)
            });
        uint dust = 1;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, params.amountsIn[0] + dust);

        hoax(testAccount0, 1 ether);
        _expectEmit_ZapDecollateralize(
            testAccount0,
            address(weth),
            0, /*all input tokens are refunded*/
            1,
            testAccount1,
            1
        );
        zap.zapDecollateralizeETH{ value: 1000 }(address(crispToken), swap, testAccount1, params);
    }

    function testZapDecollateralizeETH_emitsEvent_customReceiver() public {
        ISolidZapDecollateralize.DecollateralizeParams memory params = ISolidZapDecollateralize
            .DecollateralizeParams({
                batchIds: _toArray(1),
                amountsIn: _toArray(123),
                amountsOutMin: _toArray(150)
            });
        uint dust = 1;
        bytes memory swap = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, params.amountsIn[0] + dust);

        hoax(testAccount0, 1 ether);
        _expectEmit_ZapDecollateralize(
            testAccount1,
            address(weth),
            0, /*all input tokens are refunded*/
            1,
            testAccount1,
            1
        );
        zap.zapDecollateralizeETH{ value: 1000 }(
            address(crispToken),
            swap,
            testAccount1,
            params,
            testAccount1
        );
    }
}
