// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @author Gamma Strategies
interface IHypervisor {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function whitelistedAddress() external view returns (address);

    function pool() external view returns (address);
}
