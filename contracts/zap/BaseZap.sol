// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/staking/IWETH.sol";
import "../interfaces/zap/ISolidZapStaker.sol";
import "../libraries/GPv2SafeERC20_0_8_18.sol";

/// @author Solid World
abstract contract BaseZap {
    using GPv2SafeERC20 for IERC20;

    error GenericSwapError();
    error InvalidInput();

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
            IERC20(token).approve(spender, type(uint).max);
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

    function _sweepTokensTo(address token, address zapRecipient) internal returns (uint sweptAmount) {
        sweptAmount = IERC20(token).balanceOf(address(this));
        if (sweptAmount > 0) {
            IERC20(token).safeTransfer(zapRecipient, sweptAmount);
        }
    }
}
