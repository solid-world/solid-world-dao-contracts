// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;
import "../../interfaces/staking/ISolidZapStaker.sol";

contract SolidZapStaker is ISolidZapStaker {
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
}
