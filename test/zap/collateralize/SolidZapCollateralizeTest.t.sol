// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "./BaseSolidZapCollateralize.t.sol";

contract SolidZapCollateralizeTest is BaseSolidZapCollateralizeTest {
    function testSetsRouter() public {
        assertEq(zap.router(), ROUTER);
    }

    function testSetsWETH() public {
        assertEq(zap.weth(), address(weth));
    }

    function testSetsSWM() public {
        assertEq(zap.swManager(), address(SWM));
    }

    function testSetsFCBT() public {
        assertEq(zap.forwardContractBatch(), address(fcbt));
    }
}
