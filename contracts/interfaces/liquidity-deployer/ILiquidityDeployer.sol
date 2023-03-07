// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World
interface ILiquidityDeployer {
    function getToken0() external view returns (address);

    function getToken1() external view returns (address);

    function getGammaVault() external view returns (address);

    function getUniProxy() external view returns (address);

    function getConversionRate() external view returns (uint);
}
