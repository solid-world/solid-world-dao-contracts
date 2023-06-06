// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../interfaces/liquidity-deployer/IHypervisor_0_8_18.sol";
import "../../interfaces/liquidity-deployer/IUniProxy_0_8_18.sol";
import "../../interfaces/staking/ISolidStakingActions_0_8_18.sol";
import "../../interfaces/staking/IWETH.sol";
import "../../interfaces/staking/ISolidZapStaker.sol";
import "../../libraries/GPv2SafeERC20_0_8_18.sol";

/// @author Solid World
abstract contract BaseSolidZapStaker is ISolidZapStaker {
    address public immutable router;
    address public immutable weth;
    address public immutable iUniProxy;
    address public immutable solidStaking;

    constructor(
        address _router,
        address _weth,
        address _iUniProxy,
        address _solidStaking
    ) {
        router = _router;
        weth = _weth;
        iUniProxy = _iUniProxy;
        solidStaking = _solidStaking;

        IWETH(weth).approve(_router, type(uint).max);
    }

    function _swapViaRouter(bytes calldata encodedSwap) internal {
        (bool success, bytes memory retData) = router.call(encodedSwap);

        if (!success) {
            _propagateError(retData);
        }
    }

    function _wrap(uint amount) internal {
        IWETH(weth).deposit{ value: amount }();
    }

    function _fetchHypervisorTokens(address hypervisor)
        internal
        view
        returns (address token0, address token1)
    {
        token0 = IHypervisor(hypervisor).token0();
        token1 = IHypervisor(hypervisor).token1();
    }

    function _fetchTokenBalances(address token0, address token1)
        internal
        view
        returns (uint token0Balance, uint token1Balance)
    {
        token0Balance = IERC20(token0).balanceOf(address(this));
        token1Balance = IERC20(token1).balanceOf(address(this));
    }

    function _approveTokenSpendingIfNeeded(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).approve(spender, type(uint).max);
        }
    }

    function _deployLiquidity(
        uint token0Amount,
        uint token1Amount,
        address hypervisor
    ) internal returns (uint shares) {
        shares = IUniProxy(iUniProxy).deposit(
            token0Amount,
            token1Amount,
            address(this),
            hypervisor,
            _uniProxyMinIn()
        );
    }

    function _stakeWithRecipient(
        address token,
        uint amount,
        address recipient
    ) internal {
        ISolidStakingActions(solidStaking).stake(token, amount, recipient);
    }

    function _between(
        uint x,
        uint min,
        uint max
    ) internal pure returns (bool) {
        return x >= min && x <= max;
    }

    function _uniProxyMinIn() internal pure returns (uint[4] memory) {
        return [uint(0), uint(0), uint(0), uint(0)];
    }

    function _propagateError(bytes memory revertReason) internal pure {
        if (revertReason.length == 0) {
            revert GenericSwapError();
        }

        assembly {
            revert(add(32, revertReason), mload(revertReason))
        }
    }
}
