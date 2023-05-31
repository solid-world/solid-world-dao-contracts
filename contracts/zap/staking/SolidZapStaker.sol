// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/staking/ISolidZapStaker.sol";
import "../../interfaces/liquidity-deployer/IHypervisor_0_8_18.sol";
import "../../libraries/GPv2SafeERC20_0_8_18.sol";

/// @author Solid World
contract SolidZapStaker is ISolidZapStaker, ReentrancyGuard {
    using GPv2SafeERC20 for IERC20;

    address public immutable router;
    address public immutable iUniProxy;
    address public immutable solidStaking;

    constructor(
        address _router,
        address _iUniProxy,
        address _solidStaking
    ) {
        router = _router;
        iUniProxy = _iUniProxy;
        solidStaking = _solidStaking;
    }

    /// @inheritdoc ISolidZapStaker
    function stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint
    ) external nonReentrant returns (uint) {
        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);

        _approveTokenSpendingIfNeeded(inputToken, router);
        _swapViaRouter(swap1);
        _swapViaRouter(swap2);

        (address token0, address token1) = _fetchHypervisorTokens(hypervisor);
        _approveTokenSpendingIfNeeded(token0, hypervisor);
        _approveTokenSpendingIfNeeded(token1, hypervisor);

        return 0;
    }

    function _approveTokenSpendingIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).approve(spender, type(uint).max);
        }
    }

    function _swapViaRouter(bytes memory encodedSwap) private {
        (bool success, bytes memory retData) = router.call(encodedSwap);

        if (!success) {
            _propagateError(retData);
        }
    }

    function _fetchHypervisorTokens(address hypervisor)
        private
        view
        returns (address token0, address token1)
    {
        token0 = IHypervisor(hypervisor).token0();
        token1 = IHypervisor(hypervisor).token1();
    }

    function _propagateError(bytes memory revertReason) private pure {
        if (revertReason.length == 0) {
            revert GenericSwapError();
        }

        assembly {
            revert(add(32, revertReason), mload(revertReason))
        }
    }
}
