// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/LiquidityDeployer.sol";

abstract contract BaseLiquidityDeployerTest is BaseTest {
    address token0 = vm.addr(1);
    address token1 = vm.addr(2);
    address gammaVault = vm.addr(3);
    address uniProxy = vm.addr(4);
    uint conversionRate = 1;
    uint8 conversionRateDecimals = 6;

    ILiquidityDeployer liquidityDeployer;

    function setUp() public {
        liquidityDeployer = new LiquidityDeployer(
            token0,
            token1,
            gammaVault,
            uniProxy,
            conversionRate,
            conversionRateDecimals
        );
    }

    function _expectRevert_InvalidInput() internal {
        vm.expectRevert(abi.encodeWithSelector(ILiquidityDeployer.InvalidInput.selector));
    }
}
