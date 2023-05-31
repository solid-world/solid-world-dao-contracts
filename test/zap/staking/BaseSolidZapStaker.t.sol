// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "../../BaseTest_0_8_18.sol";
import "../../../contracts/zap/staking/SolidZapStaker.sol";
import "../../../contracts/interfaces/staking/ISolidZapStaker.sol";

abstract contract BaseSolidZapStaker is BaseTest {
    address public ROUTER;
    address public IUNIPROXY;
    address public SOLIDSTAKING;

    ISolidZapStaker public zapStaker;

    function setUp() public {
        ROUTER = vm.addr(1);
        IUNIPROXY = vm.addr(2);
        SOLIDSTAKING = vm.addr(3);

        zapStaker = new SolidZapStaker(ROUTER, IUNIPROXY, SOLIDSTAKING);

        _labelAccounts();
    }

    function _labelAccounts() private {
        vm.label(ROUTER, "Router");
        vm.label(IUNIPROXY, "IUniProxy");
        vm.label(SOLIDSTAKING, "SolidStaking");
        vm.label(address(zapStaker), "ZapStaker");
    }
}
