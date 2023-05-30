// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "../../BaseTest_0_8_18.sol";
import "../../../contracts/zap/staking/SolidZapStaker.sol";

abstract contract BaseSolidZapStaker is BaseTest {
    address public constant ROUTER = address(123);

    SolidZapStaker public zapStaker;

    function setUp() public {
        zapStaker = new SolidZapStaker(ROUTER);

        _labelAccounts();
    }

    function _labelAccounts() private {
        vm.label(ROUTER, "Router");
        vm.label(address(zapStaker), "ZapStaker");
    }
}
