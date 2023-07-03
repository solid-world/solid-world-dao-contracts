// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @author Solid World
interface ISolidZapCollateralize {
    function router() external view returns (address);

    function weth() external view returns (address);

    function swManager() external view returns (address);

    function forwardContractBatch() external view returns (address);
}
