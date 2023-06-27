// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/zap/ISolidZapCollateralize.sol";
import "../../interfaces/staking/IWETH.sol";

/// @author Solid World
abstract contract BaseSolidZapCollateralize is ISolidZapCollateralize, ReentrancyGuard {
    address public immutable router;
    address public immutable weth;
    address public immutable swManager;
    address public immutable forwardContractBatch;

    constructor(
        address _router,
        address _weth,
        address _swManager,
        address _forwardContractBatch
    ) {
        router = _router;
        weth = _weth;
        swManager = _swManager;
        forwardContractBatch = _forwardContractBatch;

        IWETH(weth).approve(_router, type(uint).max);
    }
}
