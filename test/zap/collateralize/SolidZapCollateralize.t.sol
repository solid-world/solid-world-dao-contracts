// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "./BaseSolidZapCollateralize.sol";

contract SolidZapCollateralizeTest is BaseSolidZapCollateralizeTest {
    function testSetsRouter() public {
        assertEq(zap.router(), ROUTER);
    }

    function testSetsWETH() public {
        assertEq(zap.weth(), address(weth));
    }

    function testSetsSWM() public {
        assertEq(zap.swManager(), SWM);
    }

    function testSetsFCBT() public {
        assertEq(zap.forwardContractBatch(), address(fcbt));
    }

    function testApprovesManagerToSpendERC1155() public {
        assertTrue(IERC1155(fcbt).isApprovedForAll(address(zap), SWM));
    }
}
