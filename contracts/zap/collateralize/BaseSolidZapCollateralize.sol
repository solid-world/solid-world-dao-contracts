// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../../interfaces/zap/ISolidZapCollateralize.sol";
import "../../interfaces/staking/IWETH.sol";
import "../BaseZap.sol";

/// @author Solid World
abstract contract BaseSolidZapCollateralize is BaseZap, ISolidZapCollateralize, ReentrancyGuard {
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

        IERC1155(forwardContractBatch).setApprovalForAll(swManager, true);
    }
}
