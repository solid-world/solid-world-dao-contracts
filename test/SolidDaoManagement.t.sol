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

    address internal governorAddress = vm.addr(1);
    address internal guardianAddress = vm.addr(2);
    address internal policyAddress = vm.addr(3);
    address internal vaultAddress = vm.addr(4);

    address internal newGovernorAddress = vm.addr(5);
    address internal newGuardianAddress = vm.addr(6);
    address internal newPolicyAddress = vm.addr(7);
    address internal newVaultAddress = vm.addr(8);

    address internal otherAddress = vm.addr(9);
    
    function setUp() public {
        solidDaoManagement = new SolidDaoManagement(
            governorAddress,
            guardianAddress,
            policyAddress,
            vaultAddress
        );
    }

    function testGovernorAddress() public {
        assertEq(solidDaoManagement.governor(), governorAddress);
    }

    function testGuardianAddress() public {
        assertEq(solidDaoManagement.guardian(), guardianAddress);
    }

    function testPolicyAddress() public {
        assertEq(solidDaoManagement.policy(), policyAddress);
    }

    function testVaultAddress() public {
        assertEq(solidDaoManagement.vault(), vaultAddress);
    }

    function testPushGovernor() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit GovernorPushed(newGovernorAddress, newGovernorAddress, true);
        solidDaoManagement.pushGovernor(newGovernorAddress, true);
        assertEq(solidDaoManagement.governor(), newGovernorAddress);
        assertEq(solidDaoManagement.newGovernor(), newGovernorAddress);
    }

    function testUnautorizedPushGovernor() public {
        vm.expectRevert(bytes("UNAUTHORIZED"));
        vm.prank(otherAddress);
        solidDaoManagement.pushGovernor(newGovernorAddress, true);
        assertEq(solidDaoManagement.governor(), governorAddress);
    }

    function testPullGovernor() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit GovernorPushed(governorAddress, newGovernorAddress, false);
        solidDaoManagement.pushGovernor(newGovernorAddress, false);
        assertEq(solidDaoManagement.governor(), governorAddress);
        vm.prank(newGovernorAddress);
        vm.expectEmit(true, true, true, true);
        emit GovernorPulled(governorAddress, newGovernorAddress);
        solidDaoManagement.pullGovernor();
        assertEq(solidDaoManagement.governor(), newGovernorAddress);
        assertEq(solidDaoManagement.newGovernor(), newGovernorAddress);
    }

    function testUnauthorizedPullGovernor() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit GovernorPushed(governorAddress, newGovernorAddress, false);
        solidDaoManagement.pushGovernor(newGovernorAddress, false);
        vm.expectRevert(bytes("!newGovernor"));
        vm.prank(governorAddress);
        solidDaoManagement.pullGovernor();
        assertEq(solidDaoManagement.governor(), governorAddress);
    }

    function testPushGuardian() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit GuardianPushed(newGuardianAddress, newGuardianAddress, true);
        solidDaoManagement.pushGuardian(newGuardianAddress, true);
        assertEq(solidDaoManagement.guardian(), newGuardianAddress);
        assertEq(solidDaoManagement.newGuardian(), newGuardianAddress);
    }

    function testUnautorizedPushGuardian() public {
        vm.expectRevert(bytes("UNAUTHORIZED"));
        vm.prank(otherAddress);
        solidDaoManagement.pushGuardian(newGovernorAddress, true);
        assertEq(solidDaoManagement.guardian(), guardianAddress);
    }

    function testPullGuardian() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit GuardianPushed(guardianAddress, newGuardianAddress, false);
        solidDaoManagement.pushGuardian(newGuardianAddress, false);
        assertEq(solidDaoManagement.guardian(), guardianAddress);
        vm.prank(newGuardianAddress);
        vm.expectEmit(true, true, true, true);
        emit GuardianPulled(guardianAddress, newGuardianAddress);
        solidDaoManagement.pullGuardian();
        assertEq(solidDaoManagement.guardian(), newGuardianAddress);
        assertEq(solidDaoManagement.newGuardian(), newGuardianAddress);
    }

    function testUnauthorizedPullGuardian() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit GuardianPushed(guardianAddress, newGuardianAddress, false);
        solidDaoManagement.pushGuardian(newGuardianAddress, false);
        vm.expectRevert(bytes("!newGuard"));
        vm.prank(governorAddress);
        solidDaoManagement.pullGuardian();
        assertEq(solidDaoManagement.guardian(), guardianAddress);
    }

    function testPushPolicy() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit PolicyPushed(newPolicyAddress, newPolicyAddress, true);
        solidDaoManagement.pushPolicy(newPolicyAddress, true);
        assertEq(solidDaoManagement.policy(), newPolicyAddress);
        assertEq(solidDaoManagement.newPolicy(), newPolicyAddress);
    }

    function testUnautorizedPushPolicy() public {
        vm.expectRevert(bytes("UNAUTHORIZED"));
        vm.prank(otherAddress);
        solidDaoManagement.pushPolicy(newPolicyAddress, true);
        assertEq(solidDaoManagement.policy(), policyAddress);
    }

    function testPullPolicy() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit PolicyPushed(policyAddress, newPolicyAddress, false);
        solidDaoManagement.pushPolicy(newPolicyAddress, false);
        assertEq(solidDaoManagement.policy(), policyAddress);
        vm.prank(newPolicyAddress);
        vm.expectEmit(true, true, true, true);
        emit PolicyPulled(policyAddress, newPolicyAddress);
        solidDaoManagement.pullPolicy();
        assertEq(solidDaoManagement.policy(), newPolicyAddress);
        assertEq(solidDaoManagement.newPolicy(), newPolicyAddress);
    }

    function testUnauthorizedPullPolicy() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit PolicyPushed(policyAddress, newPolicyAddress, false);
        solidDaoManagement.pushPolicy(newPolicyAddress, false);
        vm.expectRevert(bytes("!newPolicy"));
        vm.prank(governorAddress);
        solidDaoManagement.pullPolicy();
        assertEq(solidDaoManagement.policy(), policyAddress);
    }

    function testPushVault() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit VaultPushed(newVaultAddress, newVaultAddress, true);
        solidDaoManagement.pushVault(newVaultAddress, true);
        assertEq(solidDaoManagement.vault(), newVaultAddress);
        assertEq(solidDaoManagement.newVault(), newVaultAddress);
    }

    function testUnautorizedPushVault() public {
        vm.expectRevert(bytes("UNAUTHORIZED"));
        vm.prank(otherAddress);
        solidDaoManagement.pushVault(newVaultAddress, true);
        assertEq(solidDaoManagement.vault(), vaultAddress);
    }

    function testPullVault() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit VaultPushed(vaultAddress, newVaultAddress, false);
        solidDaoManagement.pushVault(newVaultAddress, false);
        assertEq(solidDaoManagement.vault(), vaultAddress);
        vm.prank(newVaultAddress);
        vm.expectEmit(true, true, true, true);
        emit VaultPulled(vaultAddress, newVaultAddress);
        solidDaoManagement.pullVault();
        assertEq(solidDaoManagement.vault(), newVaultAddress);
        assertEq(solidDaoManagement.newVault(), newVaultAddress);
    }

    function testUnauthorizedPullVault() public {
        vm.prank(governorAddress);
        vm.expectEmit(true, true, true, true);
        emit VaultPushed(vaultAddress, newVaultAddress, false);
        solidDaoManagement.pushVault(newVaultAddress, false);
        vm.expectRevert(bytes("!newVault"));
        vm.prank(governorAddress);
        solidDaoManagement.pullVault();
        assertEq(solidDaoManagement.vault(), vaultAddress);
    }

}
