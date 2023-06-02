// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/staking/ISolidZapStaker.sol";
import "../../interfaces/staking/ISolidStakingActions_0_8_18.sol";
import "../../interfaces/liquidity-deployer/IHypervisor_0_8_18.sol";
import "../../interfaces/liquidity-deployer/IUniProxy_0_8_18.sol";
import "../../libraries/GPv2SafeERC20_0_8_18.sol";

/// @author Solid World
contract SolidZapStaker is ISolidZapStaker, ReentrancyGuard {
    using GPv2SafeERC20 for IERC20;

    address public immutable router;
    address public immutable iUniProxy;
    address public immutable solidStaking;

    struct HypervisorTokens {
        address token0;
        address token1;
    }

    struct TokenBalances {
        uint token0Balance;
        uint token1Balance;
    }

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
        uint minShares,
        address recipient
    ) external nonReentrant returns (uint) {
        return _stakeDoubleSwap(inputToken, inputAmount, hypervisor, swap1, swap2, minShares, recipient);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares
    ) external nonReentrant returns (uint) {
        return _stakeDoubleSwap(inputToken, inputAmount, hypervisor, swap1, swap2, minShares, msg.sender);
    }

    function _stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) private returns (uint) {
        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        _approveTokenSpendingIfNeeded(inputToken, router);

        HypervisorTokens memory tokens = _fetchHypervisorTokens(hypervisor);
        TokenBalances memory balancesBeforeSwap = _fetchTokenBalances(tokens);
        _swapViaRouter(swap1);
        _swapViaRouter(swap2);
        TokenBalances memory balancesAfterSwap = _fetchTokenBalances(tokens);

        _approveTokenSpendingIfNeeded(tokens.token0, hypervisor);
        _approveTokenSpendingIfNeeded(tokens.token1, hypervisor);
        uint shares = _deployLiquidity(
            balancesAfterSwap.token0Balance - balancesBeforeSwap.token0Balance,
            balancesAfterSwap.token1Balance - balancesBeforeSwap.token1Balance,
            hypervisor
        );

        if (shares < minShares) {
            revert AcquiredSharesLessThanMin(shares, minShares);
        }

        _approveTokenSpendingIfNeeded(hypervisor, solidStaking);
        _stakeWithRecipient(hypervisor, shares, recipient);

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
        returns (HypervisorTokens memory tokens)
    {
        tokens.token0 = IHypervisor(hypervisor).token0();
        tokens.token1 = IHypervisor(hypervisor).token1();
    }

    function _fetchTokenBalances(HypervisorTokens memory tokens)
        private
        view
        returns (TokenBalances memory balances)
    {
        balances.token0Balance = IERC20(tokens.token0).balanceOf(address(this));
        balances.token1Balance = IERC20(tokens.token1).balanceOf(address(this));
    }

    function _deployLiquidity(
        uint token0Amount,
        uint token1Amount,
        address hypervisor
    ) private returns (uint shares) {
        shares = IUniProxy(iUniProxy).deposit(
            token0Amount,
            token1Amount,
            address(this),
            hypervisor,
            _uniProxyMinIn()
        );
    }

    function _stakeWithRecipient(
        address token,
        uint amount,
        address recipient
    ) private {
        ISolidStakingActions(solidStaking).stake(token, amount, recipient);
    }

    function _uniProxyMinIn() internal pure returns (uint[4] memory) {
        return [uint(0), uint(0), uint(0), uint(0)];
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
