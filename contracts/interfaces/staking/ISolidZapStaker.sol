// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @author Solid World
interface ISolidZapStaker {
    error GenericSwapError();
    error AcquiredSharesLessThanMin(uint acquired, uint min);

    event ZapStake(
        address indexed recipient,
        address indexed inputToken,
        uint indexed inputAmount,
        uint shares
    );

    function router() external view returns (address);

    function iUniProxy() external view returns (address);

    function solidStaking() external view returns (address);

    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap1
    /// 2. Partially swaps `inputToken` to desired token via encoded swap2
    /// 3. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 4. Shares of the deployed liquidity are staked in `solidStaking`. `recipient` is the beneficiary of the staked shares
    /// @notice The msg.sender must approve this contract to spend `inputToken`
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `inputToken` to desired token
    /// @param swap2 Encoded swap to partially swap `inputToken` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @param recipient The beneficiary of the staked shares
    /// @return The amount of shares staked in `solidStaking`
    function stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) external returns (uint);

    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap1
    /// 2. Partially swaps `inputToken` to desired token via encoded swap2
    /// 3. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 4. Shares of the deployed liquidity are staked in `solidStaking`. `msg.sender` is the beneficiary of the staked shares
    /// @notice The msg.sender must approve this contract to spend `inputToken`
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `inputToken` to desired token
    /// @param swap2 Encoded swap to partially swap `inputToken` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @return The amount of shares staked in `solidStaking`
    function stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares
    ) external returns (uint);
}
