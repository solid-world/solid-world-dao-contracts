// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/LiquidityDeployer.sol";
import "./TestToken.sol";

abstract contract BaseLiquidityDeployerTest is BaseTest {
    address token0;
    address token1;
    address gammaVault = vm.addr(3);
    address uniProxy = vm.addr(4);
    uint conversionRate = 255;
    uint8 conversionRateDecimals = 1;

    ILiquidityDeployer liquidityDeployer;

    function setUp() public {
        token0 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        token1 = address(new TestToken("USD Coin", "USDC", 6));

        liquidityDeployer = new LiquidityDeployer(
            token0,
            token1,
            gammaVault,
            uniProxy,
            conversionRate,
            conversionRateDecimals
        );

        _labelAccounts();
    }

    function _labelAccounts() private {
        vm.label(token0, "MCBT");
        vm.label(token1, "USDC");
        vm.label(gammaVault, "Gamma Vault");
        vm.label(uniProxy, "UniProxy");
    }

    function _expectRevert_InvalidInput() internal {
        vm.expectRevert(abi.encodeWithSelector(ILiquidityDeployer.InvalidInput.selector));
    }
}
