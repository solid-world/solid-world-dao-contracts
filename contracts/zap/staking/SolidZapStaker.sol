// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.sol";

/// @author Solid World
contract SolidZapStaker is BaseSolidZapStaker {
    using GPv2SafeERC20 for IERC20;

    constructor(
        address _router,
        address _weth,
        address _iUniProxy,
        address _solidStaking
    ) BaseSolidZapStaker(_router, _weth, _iUniProxy, _solidStaking) {}

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
        return _stakeSingleSwap(inputToken, inputAmount, hypervisor, swap, minShares, recipient);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares
    ) external nonReentrant returns (uint) {
        return _stakeSingleSwap(inputToken, inputAmount, hypervisor, swap, minShares, msg.sender);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) external payable nonReentrant returns (uint) {
        _wrap(weth, msg.value);

        return _stakeDoubleSwap(weth, msg.value, hypervisor, swap1, swap2, minShares, recipient);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares
    ) external payable nonReentrant returns (uint) {
        _wrap(weth, msg.value);

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
        _wrap(weth, msg.value);

        return _simulateStakeDoubleSwap(hypervisor, swap1, swap2);
    }

    /// @inheritdoc ISolidZapStaker
    function simulateStakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap
    )
        external
        nonReentrant
        returns (
            bool isDustless,
            uint shares,
            Fraction memory ratio
        )
    {
        SwapResults memory swapResults = _singleSwap(inputToken, inputAmount, hypervisor, swap);

        return _simulateLiquidityDeployment(hypervisor, swapResults);
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
            shares = _deployLiquidity(swapResults, hypervisor);
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

    function _stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares,
        address recipient
    ) private returns (uint) {
        SwapResults memory swapResults = _singleSwap(inputToken, inputAmount, hypervisor, swap);

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
        shares = _deployLiquidity(swapResults, hypervisor);

        if (shares < minShares) {
            revert AcquiredSharesLessThanMin(shares, minShares);
        }

        _approveTokenSpendingIfNeeded(hypervisor, solidStaking);
        _stakeWithRecipient(hypervisor, shares, recipient);

        emit ZapStake(recipient, inputToken, inputAmount, shares);
    }

    function _doubleSwap(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    ) private returns (SwapResults memory swapResults) {
        (address token0Address, address token1Address) = _fetchHypervisorTokens(hypervisor);
        (uint token0BalanceBefore, uint token1BalanceBefore) = _fetchTokenBalances(
            token0Address,
            token1Address
        );

        _swapViaRouter(router, swap1);
        _swapViaRouter(router, swap2);

        (uint token0BalanceAfter, uint token1BalanceAfter) = _fetchTokenBalances(
            token0Address,
            token1Address
        );

        swapResults.token0._address = token0Address;
        swapResults.token0.balance = token0BalanceAfter - token0BalanceBefore;

        swapResults.token1._address = token1Address;
        swapResults.token1.balance = token1BalanceAfter - token1BalanceBefore;
    }

    function _singleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap
    ) private returns (SwapResults memory swapResults) {
        (address token0Address, address token1Address) = _fetchHypervisorTokens(hypervisor);

        if (inputToken != token0Address && inputToken != token1Address) {
            revert InvalidInput();
        }

        (uint token0BalanceBefore, uint token1BalanceBefore) = _fetchTokenBalances(
            token0Address,
            token1Address
        );

        _prepareToSwap(inputToken, inputAmount);
        _swapViaRouter(router, swap);

        (uint token0BalanceAfter, uint token1BalanceAfter) = _fetchTokenBalances(
            token0Address,
            token1Address
        );

        swapResults.token0._address = token0Address;
        swapResults.token0.balance = token0BalanceAfter - token0BalanceBefore;

        swapResults.token1._address = token1Address;
        swapResults.token1.balance = token1BalanceAfter - token1BalanceBefore;
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

    function _prepareToSwap(address inputToken, uint inputAmount) private {
        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        _approveTokenSpendingIfNeeded(inputToken, router);
    }
}
