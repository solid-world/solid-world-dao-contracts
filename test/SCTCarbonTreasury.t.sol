// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../contracts/SolidDaoManagement.sol";
import "../contracts/SCTERC20.sol";
import "../contracts/tokens/ERC1155-flat.sol";
import "../contracts/SCTCarbonTreasury.sol";

contract SCTCarbonTreasuryTest is Test {

  event Deposited(address indexed token, uint256 indexed tokenId, address indexed owner, uint256 amount);
  event CreatedOffer(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 totalValue);
  event CanceledOffer(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 totalValue);
  event Sold(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed owner, address buyer, uint256 amount, uint256 totalValue);
  event UpdatedInfo(address indexed token, uint256 indexed tokenId, bool isActive);
  event ChangedTimelock(bool timelock);
  event SetOnChainGovernanceTimelock(uint256 blockNumber);
  event Permissioned(SCTCarbonTreasury.STATUS indexed status, address token, bool result);
  event PermissionOrdered(SCTCarbonTreasury.STATUS indexed status, address token);

  SolidDaoManagement private solidDaoManagement;
  SCTERC20Token private sctERC20;
  CarbonCredit private carbonCredit;
  SCTCarbonTreasury private sctTreasury;

  address internal governor = vm.addr(1);
  address internal guardian = vm.addr(2);
  address internal policy = vm.addr(3);
  address internal vault = vm.addr(4);

  address internal manager = vm.addr(5);

  address internal userOne = vm.addr(6);
  address internal userTwo = vm.addr(7);
  address internal userThree = vm.addr(8);
  address internal userFour = vm.addr(9);

  function setUp() public {
    solidDaoManagement = new SolidDaoManagement(
      governor,
      policy,
      guardian,
      vault
    );
    sctERC20 = new SCTERC20Token(address(solidDaoManagement));
    carbonCredit = new CarbonCredit();
    sctTreasury = new SCTCarbonTreasury(address(solidDaoManagement), address(sctERC20), 10);
    vm.startPrank(governor);
    solidDaoManagement.pushVault(address(sctERC20), true);
    carbonCredit.initialize('url');
    vm.stopPrank();
  }

  function setUpPermissions() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.disableTimelock();
    vm.roll(block.number + 100); 
    sctTreasury.disableTimelock();
    sctTreasury.enable(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    sctTreasury.enable(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    vm.stopPrank();
  }
  
  function testTotalReserves() public {
    assertEq(sctTreasury.totalReserves(), 0);
  }

  function testOfferIdCounter() public {
    assertEq(sctTreasury.offerIdCounter(), 0);
  }

  function testBlocksNeededForOrder() public {
    assertEq(sctTreasury.blocksNeededForOrder(), 10);
  }

  function testTimelockEnabled() public {
    assertFalse(sctTreasury.timelockEnabled());
  }

  function testInitialized() public {
    assertFalse(sctTreasury.initialized());
  }

  function testOnChainGovernanceTimelock() public {
    assertEq(sctTreasury.onChainGovernanceTimelock(), 0);
  }

  function testBaseSupply() public {
    assertEq(sctTreasury.baseSupply(), 0);
  }

  function testInitializeWithSuccess() public {
    vm.prank(governor);
    sctTreasury.initialize();
    assertTrue(sctTreasury.initialized());
  }

  function testInitializeUnauthorized() public {
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.initialize();
    assertFalse(sctTreasury.initialized());
  }

  function testOrderTimelockReserveTokenWithSuccess() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    vm.expectEmit(true, true, true, true);
    emit PermissionOrdered(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.stopPrank();
  }

  function testOrderTimelockReserveTokenUnauthorized() public {
    vm.prank(governor);
    sctTreasury.initialize();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
  }

  function testOrderTimelockReserveTokenInvalidAddress() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    vm.expectRevert(bytes("SCT Treasury: invalid address"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(0));
    vm.stopPrank();
  }

  function testOrderTimelockReserveTokenTimelockDisabled() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.disableTimelock();
    vm.roll(block.number + 100);
    sctTreasury.disableTimelock();
    vm.expectRevert(bytes("SCT Treasury: timelock is disabled, use enable"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.stopPrank();
  }

  function testOrderTimelockReserveManagerWithSuccess() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    vm.expectEmit(true, true, true, true);
    emit PermissionOrdered(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    vm.stopPrank();
  }

  function testOrderTimelockReserveManagerUnauthorized() public {
    vm.prank(governor);
    sctTreasury.initialize();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
  }

  function testOrderTimelockReserveManagerInvalidAddress() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    vm.expectRevert(bytes("SCT Treasury: invalid address"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVEMANAGER, address(0));
    vm.stopPrank();
  }

  function testOrderTimelockReserveManagerTimelockDisabled() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.disableTimelock();
    vm.roll(block.number + 100);
    sctTreasury.disableTimelock();
    vm.expectRevert(bytes("SCT Treasury: timelock is disabled, use enable"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVEMANAGER, address(carbonCredit));
    vm.stopPrank();
  }


  function testExecuteWithSuccess() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.roll(block.number + 10);
    vm.expectEmit(true, true, true, true);
    emit Permissioned(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit), true);
    sctTreasury.execute(0);
    vm.stopPrank();
  }

  function testExecuteTimelockNotComplete() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.roll(block.number + 9);
    vm.expectRevert(bytes("SCT Treasury: timelock not complete"));
    sctTreasury.execute(0);
    vm.stopPrank();
  }

  function testExecuteOrderAlreadyExecuted() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.roll(block.number + 10);
    vm.expectEmit(true, true, true, true);
    emit Permissioned(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit), true);
    sctTreasury.execute(0);
    vm.expectRevert(bytes("SCT Treasury: order has already been executed"));
    sctTreasury.execute(0);
    vm.stopPrank();
  }

  function testExecuteOrderNullified() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.roll(block.number + 10);
    sctTreasury.nullify(0);
    vm.expectRevert(bytes("SCT Treasury: order has been nullified"));
    sctTreasury.execute(0);
    vm.stopPrank();
  }

  function testExecuteTimelockDisabled() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    sctTreasury.disableTimelock(); 
    vm.roll(block.number + 100);   
    sctTreasury.disableTimelock();
    vm.expectRevert(bytes("SCT Treasury: timelock is disabled, use enable"));
    sctTreasury.execute(0);
    vm.stopPrank();
  }

  function testNullifyWithSuccess() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    sctTreasury.nullify(0);
    vm.stopPrank();
  }

  function testNullifyUnauthorized() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.stopPrank();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.nullify(0);
  }

  function testEnableTimelockWithSuccess() public {
    setUpPermissions();
    vm.prank(governor);
    vm.expectEmit(true, true, true, true);
    emit ChangedTimelock(true);
    sctTreasury.enableTimelock();
    assertTrue(sctTreasury.timelockEnabled());
  }

  function testEnableTimelockUnautorized() public {
    setUpPermissions();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.enableTimelock();
    assertFalse(sctTreasury.timelockEnabled());
  }

  function testEnableTimelockAlreadyEnabled() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    vm.expectRevert(bytes("SCT Treasury: timelock already enabled"));
    sctTreasury.enableTimelock();
    vm.stopPrank();
    assertTrue(sctTreasury.timelockEnabled());
  }

}