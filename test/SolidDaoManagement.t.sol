// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../contracts/SolidDaoManagement.sol";

contract SolidDaoManagementTest is Test {

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);    

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    SolidDaoManagement private solidDaoManagement;
    function setUp() public {
        solidDaoManagement = new SolidDaoManagement(
            address(1),
            address(2),
            address(3),
            address(4)
        );
    }

    function testGovernorAddress() public {
        assertEq(solidDaoManagement.governor(), address(1));
    }

    function testGuardianAddress() public {
        assertEq(solidDaoManagement.guardian(), address(2));
    }

    function testPolicyAddress() public {
        assertEq(solidDaoManagement.policy(), address(3));
    }

    function testVaultAddress() public {
        assertEq(solidDaoManagement.vault(), address(4));
    }

    function testPushGovernor() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit GovernorPushed(address(5), address(5), true);
        solidDaoManagement.pushGovernor(address(5), true);
        assertEq(solidDaoManagement.governor(), address(5));
        assertEq(solidDaoManagement.newGovernor(), address(5));
    }

    function testUnautorizedPushGovernor() public {
        vm.expectRevert(bytes("UNAUTHORIZED"));
        vm.prank(address(100));
        solidDaoManagement.pushGovernor(address(5), true);
        assertEq(solidDaoManagement.governor(), address(1));
    }

    function testPullGovernor() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit GovernorPushed(address(1), address(5), false);
        solidDaoManagement.pushGovernor(address(5), false);
        assertEq(solidDaoManagement.governor(), address(1));
        vm.prank(address(5));
        vm.expectEmit(true, true, true, true);
        emit GovernorPulled(address(1), address(5));
        solidDaoManagement.pullGovernor();
        assertEq(solidDaoManagement.governor(), address(5));
        assertEq(solidDaoManagement.newGovernor(), address(5));
    }

    function testUnauthorizedPullGovernor() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit GovernorPushed(address(1), address(5), false);
        solidDaoManagement.pushGovernor(address(5), false);
        vm.expectRevert(bytes("!newGovernor"));
        vm.prank(address(1));
        solidDaoManagement.pullGovernor();
        assertEq(solidDaoManagement.governor(), address(1));
    }

    function testPushGuardian() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit GuardianPushed(address(6), address(6), true);
        solidDaoManagement.pushGuardian(address(6), true);
        assertEq(solidDaoManagement.guardian(), address(6));
        assertEq(solidDaoManagement.newGuardian(), address(6));
    }

    function testUnautorizedPushGuardian() public {
        vm.expectRevert(bytes("UNAUTHORIZED"));
        vm.prank(address(100));
        solidDaoManagement.pushGuardian(address(5), true);
        assertEq(solidDaoManagement.guardian(), address(2));
    }

    function testPullGuardian() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit GuardianPushed(address(2), address(6), false);
        solidDaoManagement.pushGuardian(address(6), false);
        assertEq(solidDaoManagement.guardian(), address(2));
        vm.prank(address(6));
        vm.expectEmit(true, true, true, true);
        emit GuardianPulled(address(2), address(6));
        solidDaoManagement.pullGuardian();
        assertEq(solidDaoManagement.guardian(), address(6));
        assertEq(solidDaoManagement.newGuardian(), address(6));
    }

    function testUnauthorizedPullGuardian() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit GuardianPushed(address(2), address(6), false);
        solidDaoManagement.pushGuardian(address(6), false);
        vm.expectRevert(bytes("!newGuard"));
        vm.prank(address(1));
        solidDaoManagement.pullGuardian();
        assertEq(solidDaoManagement.guardian(), address(2));
    }

    function testPushPolicy() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit PolicyPushed(address(7), address(7), true);
        solidDaoManagement.pushPolicy(address(7), true);
        assertEq(solidDaoManagement.policy(), address(7));
        assertEq(solidDaoManagement.newPolicy(), address(7));
    }

    function testUnautorizedPushPolicy() public {
        vm.expectRevert(bytes("UNAUTHORIZED"));
        vm.prank(address(100));
        solidDaoManagement.pushPolicy(address(7), true);
        assertEq(solidDaoManagement.policy(), address(3));
    }

    function testPullPolicy() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit PolicyPushed(address(3), address(7), false);
        solidDaoManagement.pushPolicy(address(7), false);
        assertEq(solidDaoManagement.policy(), address(3));
        vm.prank(address(7));
        vm.expectEmit(true, true, true, true);
        emit PolicyPulled(address(3), address(7));
        solidDaoManagement.pullPolicy();
        assertEq(solidDaoManagement.policy(), address(7));
        assertEq(solidDaoManagement.newPolicy(), address(7));
    }

    function testUnauthorizedPullPolicy() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit PolicyPushed(address(3), address(7), false);
        solidDaoManagement.pushPolicy(address(7), false);
        vm.expectRevert(bytes("!newPolicy"));
        vm.prank(address(1));
        solidDaoManagement.pullPolicy();
        assertEq(solidDaoManagement.policy(), address(3));
    }

    function testPushVault() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit VaultPushed(address(8), address(8), true);
        solidDaoManagement.pushVault(address(8), true);
        assertEq(solidDaoManagement.vault(), address(8));
        assertEq(solidDaoManagement.newVault(), address(8));
    }

    function testUnautorizedPushVault() public {
        vm.expectRevert(bytes("UNAUTHORIZED"));
        vm.prank(address(100));
        solidDaoManagement.pushVault(address(8), true);
        assertEq(solidDaoManagement.vault(), address(4));
    }

    function testPullVault() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit VaultPushed(address(4), address(8), false);
        solidDaoManagement.pushVault(address(8), false);
        assertEq(solidDaoManagement.vault(), address(4));
        vm.prank(address(8));
        vm.expectEmit(true, true, true, true);
        emit VaultPulled(address(4), address(8));
        solidDaoManagement.pullVault();
        assertEq(solidDaoManagement.vault(), address(8));
        assertEq(solidDaoManagement.newVault(), address(8));
    }

    function testUnauthorizedPullVault() public {
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true);
        emit VaultPushed(address(4), address(8), false);
        solidDaoManagement.pushVault(address(8), false);
        vm.expectRevert(bytes("!newVault"));
        vm.prank(address(1));
        solidDaoManagement.pullVault();
        assertEq(solidDaoManagement.vault(), address(4));
    }

}
