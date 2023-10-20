// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/staking/IWETH.sol";
import "../interfaces/zap/ISolidZapStaker.sol";
import "../interfaces/zap/ISWManager.sol";
import "../libraries/GPv2SafeERC20_0_8_18.sol";
import "../libraries/SafeTransferLib.sol";

/// @author Solid World
abstract contract BaseZap {
    using GPv2SafeERC20 for IERC20;
    using SafeTransferLib for address;

    error GenericSwapError();
    error InvalidInput();
    error SweepAmountZero();
    error ETHTransferFailed();

    function _swapViaRouter(address router, bytes calldata encodedSwap) internal {
        (bool success, bytes memory retData) = router.call(encodedSwap);

        if (!success) {
            _propagateError(retData);
        }
    }

    function _propagateError(bytes memory revertReason) internal pure {
        if (revertReason.length == 0) {
            revert GenericSwapError();
        }

        assembly {
            revert(add(32, revertReason), mload(revertReason))
        }
    }

    function _wrap(address weth, uint amount) internal {
        IWETH(weth).deposit{ value: amount }();
    }

    function _approveTokenSpendingIfNeeded(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            token.safeApprove(spender, type(uint).max);
        }
    }

    function _prepareToSwap(
        address inputToken,
        uint inputAmount,
        address _router
    ) internal {
        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        _approveTokenSpendingIfNeeded(inputToken, _router);
    }

    function _sweepTokens(address token, address recipient) internal returns (uint sweptAmount) {
        sweptAmount = _safeSweepTokens(token, recipient, false);
    }

    function _safeSweepTokens(
        address token,
        address recipient,
        bool revertOnSweepAmountZero
    ) internal returns (uint sweptAmount) {
        sweptAmount = IERC20(token).balanceOf(address(this));
        if (sweptAmount == 0 && revertOnSweepAmountZero) {
            revert SweepAmountZero();
        }

        if (sweptAmount > 0) {
            IERC20(token).safeTransfer(recipient, sweptAmount);
        }
    }

    function _sweepETH(address weth, address recipient) internal returns (uint sweptAmount) {
        sweptAmount = _safeSweepETH(weth, recipient, false);
    }

    function _safeSweepETH(
        address weth,
        address recipient,
        bool revertOnSweepAmountZero
    ) internal returns (uint sweptAmount) {
        sweptAmount = IERC20(weth).balanceOf(address(this));
        if (sweptAmount == 0 && revertOnSweepAmountZero) {
            revert SweepAmountZero();
        }

        if (sweptAmount > 0) {
            IWETH(weth).withdraw(sweptAmount);
            (bool success, ) = payable(recipient).call{ value: sweptAmount }("");
            if (!success) {
                revert ETHTransferFailed();
            }
        }
    }
}
