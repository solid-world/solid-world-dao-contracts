// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../interfaces/liquidity-deployer/IHypervisor.sol";
import "../../interfaces/liquidity-deployer/IUniProxy.sol";
import "../../interfaces/staking/ISolidStakingActions_0_8_18.sol";
import "../BaseZap.sol";

/// @author Solid World
abstract contract BaseSolidZapStaker is BaseZap, ISolidZapStaker, ReentrancyGuard {
    address public immutable router;
    address public immutable weth;
    address public immutable solidStaking;

    constructor(
        address _router,
        address _weth,
        address _solidStaking
    ) {
        router = _router;
        weth = _weth;
        solidStaking = _solidStaking;

        IWETH(weth).approve(_router, type(uint).max);
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

    function _deployLiquidity(SwapResults memory swapResults, address hypervisor)
        internal
        returns (uint shares)
    {
        _approveTokenSpendingIfNeeded(swapResults.token0._address, hypervisor);
        _approveTokenSpendingIfNeeded(swapResults.token1._address, hypervisor);
        shares = IUniProxy(getUniProxy(hypervisor)).deposit(
            swapResults.token0.balance,
            swapResults.token1.balance,
            address(this),
            hypervisor,
            _uniProxyMinIn()
        );
    }

    function _stakeWithRecipient(
        address token,
        uint amount,
        address zapRecipient
    ) internal {
        ISolidStakingActions(solidStaking).stake(token, amount, zapRecipient);
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

    function getUniProxy(address hypervisor) internal view returns (address) {
        return IHypervisor(hypervisor).whitelistedAddress();
    }
}
