// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface ISolidZapStaker {
    function router() external view returns (address);

    function iUniProxy() external view returns (address);

    function solidStaking() external view returns (address);
}
