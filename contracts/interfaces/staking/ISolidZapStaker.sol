// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @author Solid World
interface ISolidZapStaker {
    error GenericSwapError();
    error InvalidInput();
    error AcquiredSharesLessThanMin(uint acquired, uint min);

    event ZapStake(
        address indexed recipient,
        address indexed inputToken,
        uint indexed inputAmount,
        uint shares
    );

    struct Fraction {
        uint numerator;
        uint denominator;
    }

    struct SwapResult {
        address _address;
        uint balance;
    }

    struct SwapResults {
        SwapResult token0;
        SwapResult token1;
    }

    function router() external view returns (address);

    function weth() external view returns (address);

    function iUniProxy() external view returns (address);

    function solidStaking() external view returns (address);

    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap1
    /// 2. Partially swaps `inputToken` to desired token via encoded swap2
    /// 3. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 4. Shares of the deployed liquidity are staked in `solidStaking`. `recipient` is the beneficiary of the staked shares
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `inputToken` to desired token
    /// @param swap2 Encoded swap to partially swap `inputToken` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @param recipient The beneficiary of the staked shares
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) external returns (uint shares);

    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap1
    /// 2. Partially swaps `inputToken` to desired token via encoded swap2
    /// 3. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 4. Shares of the deployed liquidity are staked in `solidStaking`. `msg.sender` is the beneficiary of the staked shares
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `inputToken` to desired token
    /// @param swap2 Encoded swap to partially swap `inputToken` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares
    ) external returns (uint shares);

    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap
    /// 3. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 4. Shares of the deployed liquidity are staked in `solidStaking`. `recipient` is the beneficiary of the staked shares
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @notice `inputToken` must be one of hypervisor's token0 or token1
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap Encoded swap to partially swap `inputToken` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @param recipient The beneficiary of the staked shares
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares,
        address recipient
    ) external returns (uint shares);

    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap
    /// 3. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 4. Shares of the deployed liquidity are staked in `solidStaking`. `msg.sender` is the beneficiary of the staked shares
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @notice `inputToken` must be one of hypervisor's token0 or token1
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap Encoded swap to partially swap `inputToken` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares
    ) external returns (uint shares);

    /// @notice Zap function that achieves the following:
    /// 1. Wraps `msg.value` to WETH
    /// 2. Partially swaps `WETH` to desired token via encoded swap1
    /// 3. Partially swaps `WETH` to desired token via encoded swap2
    /// 4. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 5. Shares of the deployed liquidity are staked in `solidStaking`. `recipient` is the beneficiary of the staked shares
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `WETH` to desired token
    /// @param swap2 Encoded swap to partially swap `WETH` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @param recipient The beneficiary of the staked shares
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) external payable returns (uint shares);

    /// @notice Zap function that achieves the following:
    /// 1. Wraps `msg.value` to WETH
    /// 2. Partially swaps `WETH` to desired token via encoded swap1
    /// 3. Partially swaps `WETH` to desired token via encoded swap2
    /// 4. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 5. Shares of the deployed liquidity are staked in `solidStaking`. `msg.sender` is the beneficiary of the staked shares
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `WETH` to desired token
    /// @param swap2 Encoded swap to partially swap `WETH` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares
    ) external payable returns (uint shares);

    /// @notice Function is meant to be called off-chain with _staticCall_.
    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap1
    /// 2. Partially swaps `inputToken` to desired token via encoded swap2
    /// 3. Resulting tokens are checked against Gamma Vault to determine if they qualify for a dustless liquidity deployment
    ///     * if dustless, the function deploys the liquidity to obtain the amounts of shares getting minted and returns
    ///     * if not dustless, the function computes the current gamma token ratio and returns
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `inputToken` to desired token
    /// @param swap2 Encoded swap to partially swap `inputToken` to desired token
    /// @return isDustless Whether the resulting tokens qualify for a dustless liquidity deployment
    /// @return shares The amount of shares minted from the dustless liquidity deployment
    /// @return ratio The current gamma token ratio, or empty if dustless
    function simulateStakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    )
        external
        returns (
            bool isDustless,
            uint shares,
            Fraction memory ratio
        );

    /// @notice Function is meant to be called off-chain with _staticCall_.
    /// @notice Zap function that achieves the following:
    /// 1. Wraps `msg.value` to WETH
    /// 2. Partially swaps `WETH` to desired token via encoded swap1
    /// 3. Partially swaps `WETH` to desired token via encoded swap2
    /// 4. Resulting tokens are checked against Gamma Vault to determine if they qualify for a dustless liquidity deployment
    ///     * if dustless, the function deploys the liquidity to obtain the amounts of shares getting minted and returns
    ///     * if not dustless, the function computes the current gamma token ratio and returns
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `WETH` to desired token
    /// @param swap2 Encoded swap to partially swap `WETH` to desired token
    /// @return isDustless Whether the resulting tokens qualify for a dustless liquidity deployment
    /// @return shares The amount of shares minted from the dustless liquidity deployment
    /// @return ratio The current gamma token ratio, or empty if dustless
    function simulateStakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    )
        external
        payable
        returns (
            bool isDustless,
            uint shares,
            Fraction memory ratio
        );

    /// @notice Function is meant to be called off-chain with _staticCall_.
    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap
    /// 2. Resulting tokens are checked against Gamma Vault to determine if they qualify for a dustless liquidity deployment
    ///     * if dustless, the function deploys the liquidity to obtain the amounts of shares getting minted and returns
    ///     * if not dustless, the function computes the current gamma token ratio and returns
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @notice `inputToken` must be one of hypervisor's token0 or token1
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap Encoded swap to partially swap `inputToken` to desired token
    /// @return isDustless Whether the resulting tokens qualify for a dustless liquidity deployment
    /// @return shares The amount of shares minted from the dustless liquidity deployment
    /// @return ratio The current gamma token ratio, or empty if dustless
    function simulateStakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap
    )
        external
        returns (
            bool isDustless,
            uint shares,
            Fraction memory ratio
        );
}
