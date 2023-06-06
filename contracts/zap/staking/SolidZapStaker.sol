// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../interfaces/staking/ISolidZapStaker.sol";
import "../../interfaces/staking/ISolidStakingActions_0_8_18.sol";
import "../../interfaces/staking/IWETH.sol";
import "../../interfaces/liquidity-deployer/IHypervisor_0_8_18.sol";
import "../../interfaces/liquidity-deployer/IUniProxy_0_8_18.sol";
import "../../libraries/GPv2SafeERC20_0_8_18.sol";

/// @author Solid World
contract SolidZapStaker is ISolidZapStaker, ReentrancyGuard {
    using GPv2SafeERC20 for IERC20;

    address public immutable router;
    address public immutable weth;
    address public immutable iUniProxy;
    address public immutable solidStaking;

    struct SwapResult {
        address _address;
        uint balance;
    }

    struct SwapResults {
        SwapResult token0;
        SwapResult token1;
    }

    constructor(
        address _router,
        address _weth,
        address _iUniProxy,
        address _solidStaking
    ) {
        router = _router;
        weth = _weth;
        iUniProxy = _iUniProxy;
        solidStaking = _solidStaking;

        IWETH(weth).approve(_router, type(uint).max);
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
        _prepareToSwap(inputToken, inputAmount);
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
        _prepareToSwap(inputToken, inputAmount);
        return _stakeDoubleSwap(inputToken, inputAmount, hypervisor, swap1, swap2, minShares, msg.sender);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares,
        address recipient
    ) external nonReentrant returns (uint) {
        _prepareToSwap(inputToken, inputAmount);
        return 0;
    }

    /// @inheritdoc ISolidZapStaker
    function stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares
    ) external nonReentrant returns (uint) {
        _prepareToSwap(inputToken, inputAmount);
        return 0;
    }

    /// @inheritdoc ISolidZapStaker
    function stakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) external payable nonReentrant returns (uint) {
        _wrap(msg.value);

        return _stakeDoubleSwap(weth, msg.value, hypervisor, swap1, swap2, minShares, recipient);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares
    ) external payable nonReentrant returns (uint) {
        _wrap(msg.value);

        return _stakeDoubleSwap(weth, msg.value, hypervisor, swap1, swap2, minShares, msg.sender);
    }

    /// @inheritdoc ISolidZapStaker
    function simulateStakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    )
        external
        nonReentrant
        returns (
            bool,
            uint,
            Fraction memory
        )
    {
        _prepareToSwap(inputToken, inputAmount);

        return _simulateStakeDoubleSwap(hypervisor, swap1, swap2);
    }

    /// @inheritdoc ISolidZapStaker
    function simulateStakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    )
        external
        payable
        nonReentrant
        returns (
            bool,
            uint,
            Fraction memory
        )
    {
        _wrap(msg.value);

        return _simulateStakeDoubleSwap(hypervisor, swap1, swap2);
    }

    function _simulateStakeDoubleSwap(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    )
        private
        returns (
            bool,
            uint,
            Fraction memory
        )
    {
        SwapResults memory swapResults = _doubleSwap(hypervisor, swap1, swap2);
        return _simulateLiquidityDeployment(hypervisor, swapResults);
    }

    function _simulateLiquidityDeployment(address hypervisor, SwapResults memory swapResults)
        private
        returns (
            bool isDustless,
            uint shares,
            Fraction memory ratio
        )
    {
        (isDustless, ratio) = _checkDustless(hypervisor, swapResults);

        if (isDustless) {
            shares = _deployLiquidity(swapResults.token0.balance, swapResults.token1.balance, hypervisor);
        }
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
        SwapResults memory swapResults = _doubleSwap(hypervisor, swap1, swap2);

        return _stake(inputToken, inputAmount, hypervisor, minShares, recipient, swapResults);
    }

    function _stake(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        uint minShares,
        address recipient,
        SwapResults memory swapResults
    ) private returns (uint shares) {
        _approveTokenSpendingIfNeeded(swapResults.token0._address, hypervisor);
        _approveTokenSpendingIfNeeded(swapResults.token1._address, hypervisor);
        shares = _deployLiquidity(swapResults.token0.balance, swapResults.token1.balance, hypervisor);

        if (shares < minShares) {
            revert AcquiredSharesLessThanMin(shares, minShares);
        }

        _approveTokenSpendingIfNeeded(hypervisor, solidStaking);
        _stakeWithRecipient(hypervisor, shares, recipient);

        emit ZapStake(recipient, inputToken, inputAmount, shares);
    }

    function _doubleSwap(
        address hypervisor,
        bytes memory swap1,
        bytes memory swap2
    ) private returns (SwapResults memory swapResults) {
        (address token0Address, address token1Address) = _fetchHypervisorTokens(hypervisor);
        (uint token0BalanceBefore, uint token1BalanceBefore) = _fetchTokenBalances(
            token0Address,
            token1Address
        );
        _swapViaRouter(swap1);
        _swapViaRouter(swap2);
        (uint token0BalanceAfter, uint token1BalanceAfter) = _fetchTokenBalances(
            token0Address,
            token1Address
        );

        swapResults.token0._address = token0Address;
        swapResults.token0.balance = token0BalanceAfter - token0BalanceBefore;

        swapResults.token1._address = token1Address;
        swapResults.token1.balance = token1BalanceAfter - token1BalanceBefore;
    }

    function _prepareToSwap(address inputToken, uint inputAmount) private {
        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        _approveTokenSpendingIfNeeded(inputToken, router);
    }

    function _approveTokenSpendingIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).approve(spender, type(uint).max);
        }
    }

    function _checkDustless(address hypervisor, SwapResults memory swapResults)
        private
        view
        returns (bool isDustless, Fraction memory actualRatio)
    {
        (uint amountStart, uint amountEnd) = IUniProxy(iUniProxy).getDepositAmount(
            hypervisor,
            swapResults.token0._address,
            swapResults.token0.balance
        );

        isDustless = _between(swapResults.token1.balance, amountStart, amountEnd);

        if (!isDustless) {
            actualRatio = Fraction(swapResults.token0.balance, Math.average(amountStart, amountEnd));
        }
    }

    function _swapViaRouter(bytes memory encodedSwap) private {
        (bool success, bytes memory retData) = router.call(encodedSwap);

        if (!success) {
            _propagateError(retData);
        }
    }

    function _wrap(uint amount) private {
        IWETH(weth).deposit{ value: amount }();
    }

    function _fetchHypervisorTokens(address hypervisor)
        private
        view
        returns (address token0, address token1)
    {
        token0 = IHypervisor(hypervisor).token0();
        token1 = IHypervisor(hypervisor).token1();
    }

    function _fetchTokenBalances(address token0, address token1)
        private
        view
        returns (uint token0Balance, uint token1Balance)
    {
        token0Balance = IERC20(token0).balanceOf(address(this));
        token1Balance = IERC20(token1).balanceOf(address(this));
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

    function _between(
        uint x,
        uint min,
        uint max
    ) private pure returns (bool) {
        return x >= min && x <= max;
    }

    function _uniProxyMinIn() private pure returns (uint[4] memory) {
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
