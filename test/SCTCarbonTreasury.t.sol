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
    solidDaoManagement.pushVault(address(sctTreasury), true);
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

  function setUpCarbonProject() public {
    setUpPermissions();
    vm.startPrank(manager);
    sctTreasury.createOrUpdateCarbonProject( SCTCarbonTreasury.CarbonProject ({
      token: address(carbonCredit),
      tokenId: 1,
      tons: 10000,
      flatRate: 1,
      sdgPremium: 1,
      daysToRealization: 1,
      closenessPremium: 1,
      isActive: true,
      isCertified: false,
      isRedeemed: false
    }));
    vm.stopPrank();
  }

  function setUpCarbonToken() public {
    vm.startPrank(governor);
    carbonCredit.mint(userOne, 1, 10000, 'data');
    carbonCredit.mint(userTwo, 2, 10000, 'data');
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
    ( , address toPermit, uint256 timelockEnd, bool nullify, bool executed) = sctTreasury.permissionOrder(0);
    assertEq(toPermit, address(carbonCredit));
    assertEq(timelockEnd, 10);
    assertEq(nullify, false);
    assertEq(executed, false);
  }

  function testOrderTimelockReserveTokenUnauthorized() public {
    vm.prank(governor);
    sctTreasury.initialize();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.expectRevert();
    sctTreasury.permissionOrder(0);
  }

  function testOrderTimelockReserveTokenInvalidAddress() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    vm.expectRevert(bytes("SCT Treasury: invalid address"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(0));
    vm.stopPrank();
    vm.expectRevert();
    sctTreasury.permissionOrder(0);
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
    vm.expectRevert();
    sctTreasury.permissionOrder(0);
  }

  function testOrderTimelockReserveManagerWithSuccess() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    vm.expectEmit(true, true, true, true);
    emit PermissionOrdered(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    vm.stopPrank();
    ( , address toPermit, uint256 timelockEnd, bool nullify, bool executed) = sctTreasury.permissionOrder(0);
    assertEq(toPermit, manager);
    assertEq(timelockEnd, 10);
    assertEq(nullify, false);
    assertEq(executed, false);
  }

  function testOrderTimelockReserveManagerUnauthorized() public {
    vm.prank(governor);
    sctTreasury.initialize();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    vm.expectRevert();
    sctTreasury.permissionOrder(0);
  }

  function testOrderTimelockReserveManagerInvalidAddress() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    vm.expectRevert(bytes("SCT Treasury: invalid address"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVEMANAGER, address(0));
    vm.stopPrank();
    vm.expectRevert();
    sctTreasury.permissionOrder(0);
  }

  function testOrderTimelockReserveManagerTimelockDisabled() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.disableTimelock();
    vm.roll(block.number + 100);
    sctTreasury.disableTimelock();
    vm.expectRevert(bytes("SCT Treasury: timelock is disabled, use enable"));
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    vm.stopPrank();
    vm.expectRevert();
    sctTreasury.permissionOrder(0);
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
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit)), true);
    ( , address toPermit, uint256 timelockEnd, bool nullify, bool executed) = sctTreasury.permissionOrder(0);
    assertEq(toPermit, address(carbonCredit));
    assertEq(timelockEnd, 10);
    assertEq(nullify, false);
    assertEq(executed, true);
  }

  function testExecuteTimelockNotComplete() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.roll(block.number + 9);
    vm.expectRevert(bytes("SCT Treasury: timelock not complete"));
    sctTreasury.execute(0);
    vm.stopPrank();
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit)), false);
    ( , address toPermit, uint256 timelockEnd, bool nullify, bool executed) = sctTreasury.permissionOrder(0);
    assertEq(toPermit, address(carbonCredit));
    assertEq(timelockEnd, 10);
    assertEq(nullify, false);
    assertEq(executed, false);
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
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit)), true);
    ( , address toPermit, uint256 timelockEnd, bool nullify, bool executed) = sctTreasury.permissionOrder(0);
    assertEq(toPermit, address(carbonCredit));
    assertEq(timelockEnd, 10);
    assertEq(nullify, false);
    assertEq(executed, true);
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
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit)), false);
    ( , address toPermit, uint256 timelockEnd, bool nullify, bool executed) = sctTreasury.permissionOrder(0);
    assertEq(toPermit, address(carbonCredit));
    assertEq(timelockEnd, 10);
    assertEq(nullify, true);
    assertEq(executed, false);
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
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit)), false);
    ( , address toPermit, uint256 timelockEnd, bool nullify, bool executed) = sctTreasury.permissionOrder(0);
    assertEq(toPermit, address(carbonCredit));
    assertEq(timelockEnd, 10);
    assertEq(nullify, false);
    assertEq(executed, false);
  }

  function testNullifyWithSuccess() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    sctTreasury.nullify(0);
    vm.stopPrank();
    ( , address toPermit, uint256 timelockEnd, bool nullify, bool executed) = sctTreasury.permissionOrder(0);
    assertEq(toPermit, address(carbonCredit));
    assertEq(timelockEnd, 10);
    assertEq(nullify, true);
    assertEq(executed, false);
  }

  function testNullifyUnauthorized() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.orderTimelock(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.stopPrank();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.nullify(0);
    ( , address toPermit, uint256 timelockEnd, bool nullify, bool executed) = sctTreasury.permissionOrder(0);
    assertEq(toPermit, address(carbonCredit));
    assertEq(timelockEnd, 10);
    assertEq(nullify, false);
    assertEq(executed, false);
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

  function testDisableTimelockWithSuccess() public {
    setUpPermissions();
    vm.prank(governor);
    sctTreasury.enableTimelock();
    vm.prank(governor);
    vm.expectEmit(true, true, true, true);
    emit ChangedTimelock(false);
    sctTreasury.disableTimelock();
    assertFalse(sctTreasury.timelockEnabled());
  }

  function testDisableTimelockUnautorized() public {
    setUpPermissions();
    vm.prank(governor);
    sctTreasury.enableTimelock();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.disableTimelock();
    assertTrue(sctTreasury.timelockEnabled());
  }

  function testDisableTimelockAlreadyDisabled() public {
    setUpPermissions();
    vm.startPrank(governor);
    vm.expectRevert(bytes("SCT Treasury: timelock already disabled"));
    sctTreasury.disableTimelock();
    vm.stopPrank();
    assertFalse(sctTreasury.timelockEnabled());
  }

  function testEnableReserveManagerWithSuccess() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.disableTimelock();
    vm.roll(block.number + 100); 
    sctTreasury.disableTimelock();
    vm.expectEmit(true, true, true, true);
    emit Permissioned(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager, true);
    sctTreasury.enable(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    vm.stopPrank();
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager), true);
  }

  function testEnableReserveManagerUnauthorized() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.disableTimelock();
    vm.roll(block.number + 100); 
    sctTreasury.disableTimelock();
    vm.stopPrank();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.enable(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager), false);
  }

  function testEnableReserveManagerTimelockEnabled() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    vm.expectRevert(bytes("SCT Treasury: timelock enabled"));
    sctTreasury.enable(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    vm.stopPrank();
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager), false);
  }

  function testEnableReserveTokenWithSuccess() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.disableTimelock();
    vm.roll(block.number + 100); 
    sctTreasury.disableTimelock();
    vm.expectEmit(true, true, true, true);
    emit Permissioned(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit), true);
    sctTreasury.enable(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.stopPrank();
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit)), true);
  }

  function testEnableReserveTokenUnauthorized() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    sctTreasury.disableTimelock();
    vm.roll(block.number + 100); 
    sctTreasury.disableTimelock();
    vm.stopPrank();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.enable(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit)), false);
  }

  function testEnableReserveTokenTimelockEnabled() public {
    vm.startPrank(governor);
    sctTreasury.initialize();
    vm.expectRevert(bytes("SCT Treasury: timelock enabled"));
    sctTreasury.enable(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    vm.stopPrank();
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit)), false);
  }

  function testDisableReserveManagerWithSuccess() public {
    setUpPermissions();
    vm.prank(governor);
    vm.expectEmit(true, true, true, true);
    emit Permissioned(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager, false);
    sctTreasury.disable(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager), false);
  }

  function testDisableReserveManagerUnauthorized() public {
    setUpPermissions();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.disable(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager);
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVEMANAGER, manager), true);
  }

  function testDisableReserveTokenWithSuccess() public {
    setUpPermissions();
    vm.prank(governor);
    vm.expectEmit(true, true, true, true);
    emit Permissioned(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit), false);
    sctTreasury.disable(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit)), false);
  }

  function testDisableReserveTokenUnauthorized() public {
    setUpPermissions();
    vm.prank(userOne);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sctTreasury.disable(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit));
    assertEq(sctTreasury.permissions(SCTCarbonTreasury.STATUS.RESERVETOKEN, address(carbonCredit)), true);
  }

  function testCreateCarbonProjectWithSuccess() public {
    setUpPermissions();
    vm.prank(manager);
    vm.expectEmit(true, true, true, true);
    emit UpdatedInfo(address(carbonCredit), 1, true);
    sctTreasury.createOrUpdateCarbonProject( SCTCarbonTreasury.CarbonProject ({
      token: address(carbonCredit),
      tokenId: 1,
      tons: 10000,
      flatRate: 1,
      sdgPremium: 1,
      daysToRealization: 1,
      closenessPremium: 1,
      isActive: true,
      isCertified: false,
      isRedeemed: false
    }));
    (address token, uint256 tokenId , uint256 tons, , , , , bool isActive, ,) = sctTreasury.carbonProjects(address(carbonCredit), 1);
    assertEq(token, address(carbonCredit));
    assertEq(tokenId, 1);
    assertEq(tons, 10000);
    assertEq(isActive, true);
  }

  function testCreateCarbonProjectUnauthorized() public {
    setUpPermissions();
    vm.prank(governor);
    vm.expectRevert(bytes("SCT Treasury: reserve manager not permitted"));
    sctTreasury.createOrUpdateCarbonProject( SCTCarbonTreasury.CarbonProject ({
      token: address(carbonCredit),
      tokenId: 1,
      tons: 10000,
      flatRate: 1,
      sdgPremium: 1,
      daysToRealization: 1,
      closenessPremium: 1,
      isActive: true,
      isCertified: false,
      isRedeemed: false
    }));
    (address token, uint256 tokenId, uint256 tons, , , , , bool isActive, ,) = sctTreasury.carbonProjects(address(carbonCredit), 1);
    assertEq(token, address(0));
    assertEq(tokenId, 0);
    assertEq(tons, 0);
    assertEq(isActive, false);
  }

  function testCreateCarbonProjectReserveTokenNotPermitted() public {
    setUpPermissions();
    vm.prank(manager);
    vm.expectRevert(bytes("SCT Treasury: reserve token not permitted"));
    sctTreasury.createOrUpdateCarbonProject( SCTCarbonTreasury.CarbonProject ({
      token: address(sctERC20),
      tokenId: 1,
      tons: 10000,
      flatRate: 1,
      sdgPremium: 1,
      daysToRealization: 1,
      closenessPremium: 1,
      isActive: true,
      isCertified: false,
      isRedeemed: false
    }));
    (address token, uint256 tokenId, uint256 tons, , , , , bool isActive, ,) = sctTreasury.carbonProjects(address(sctERC20), 1);
    assertEq(token, address(0));
    assertEq(tokenId, 0);
    assertEq(tons, 0);
    assertEq(isActive, false);
  }

  function testUpdateCarbonProjectWithSuccess() public {
    setUpCarbonProject();
    vm.prank(manager);
    vm.expectEmit(true, true, true, true);
    emit UpdatedInfo(address(carbonCredit), 1, false);
    sctTreasury.createOrUpdateCarbonProject( SCTCarbonTreasury.CarbonProject ({
      token: address(carbonCredit),
      tokenId: 1,
      tons: 9999,
      flatRate: 1,
      sdgPremium: 1,
      daysToRealization: 1,
      closenessPremium: 1,
      isActive: false,
      isCertified: false,
      isRedeemed: false
    }));
    (address token, uint256 tokenId, uint256 tons, , , , , bool isActive, ,) = sctTreasury.carbonProjects(address(carbonCredit), 1);
    assertEq(token, address(carbonCredit));
    assertEq(tokenId, 1);
    assertEq(tons, 9999);
    assertEq(isActive, false);
  }

  function testUpdateCarbonProjectUnauthorized() public {
    setUpCarbonProject();
    vm.prank(governor);
    vm.expectRevert(bytes("SCT Treasury: reserve manager not permitted"));
    sctTreasury.createOrUpdateCarbonProject( SCTCarbonTreasury.CarbonProject ({
      token: address(carbonCredit),
      tokenId: 1,
      tons: 9999,
      flatRate: 1,
      sdgPremium: 1,
      daysToRealization: 1,
      closenessPremium: 1,
      isActive: true,
      isCertified: false,
      isRedeemed: false
    }));
    (address token, uint256 tokenId, uint256 tons, , , , , bool isActive, ,) = sctTreasury.carbonProjects(address(carbonCredit), 1);
    assertEq(token, address(carbonCredit));
    assertEq(tokenId, 1);
    assertEq(tons, 10000);
    assertEq(isActive, true);
  }

  function testDepositReserveTokenWithSuccess() public {
    setUpCarbonProject();
    setUpCarbonToken();
    vm.startPrank(userOne);
    carbonCredit.setApprovalForAll(address(sctTreasury), true);
    vm.expectEmit(true, true, true, true);
    emit Deposited(address(carbonCredit), 1, address(userOne), 10000);
    sctTreasury.depositReserveToken(address(carbonCredit), 1, 10000, address(userOne));
    vm.stopPrank();
    assertEq(carbonCredit.balanceOf(address(userOne), 1), 0);
    assertEq(carbonCredit.balanceOf(address(sctTreasury), 1), 10000);
    assertEq(sctERC20.balanceOf(address(userOne)), 10000);
    assertEq(sctTreasury.carbonProjectTons(address(carbonCredit), 1), 10000);
    assertEq(sctTreasury.carbonProjectBalances(address(carbonCredit), 1, userOne), 10000);
    assertEq(sctTreasury.totalReserves(), 10000);
    assertEq(sctTreasury.baseSupply(), 10000);
  }

  function testDepositReserveTokenNotPermitted() public {
    setUpCarbonToken();
    vm.startPrank(userOne);
    carbonCredit.setApprovalForAll(address(sctTreasury), true);
    vm.expectRevert(bytes("SCT Treasury: reserve token not permitted"));
    vm.stopPrank();
    sctTreasury.depositReserveToken(address(carbonCredit), 1, 10000, address(userOne));
    assertEq(carbonCredit.balanceOf(address(userOne), 1), 10000);
    assertEq(carbonCredit.balanceOf(address(sctTreasury), 1), 0);
    assertEq(sctERC20.balanceOf(address(userOne)), 0);
    assertEq(sctTreasury.carbonProjectTons(address(carbonCredit), 1), 0);
    assertEq(sctTreasury.carbonProjectBalances(address(carbonCredit), 1, userOne), 0);
    assertEq(sctTreasury.totalReserves(), 0);
    assertEq(sctTreasury.baseSupply(), 0);
  }

  function testDepositReserveTokenNotActive() public {
    setUpPermissions();
    setUpCarbonToken();
    vm.startPrank(userOne);
    carbonCredit.setApprovalForAll(address(sctTreasury), true);
    vm.expectRevert(bytes("SCT Treasury: carbon project not active"));
    vm.stopPrank();
    sctTreasury.depositReserveToken(address(carbonCredit), 1, 10000, address(userOne));
    assertEq(carbonCredit.balanceOf(address(userOne), 1), 10000);
    assertEq(carbonCredit.balanceOf(address(sctTreasury), 1), 0);
    assertEq(sctERC20.balanceOf(address(userOne)), 0);
    assertEq(sctTreasury.carbonProjectTons(address(carbonCredit), 1), 0);
    assertEq(sctTreasury.carbonProjectBalances(address(carbonCredit), 1, userOne), 0);
    assertEq(sctTreasury.totalReserves(), 0);
    assertEq(sctTreasury.baseSupply(), 0);
  }

  function testDepositReserveTokenInsuficientBalance() public {
    setUpCarbonProject();
    setUpCarbonToken();
    vm.startPrank(userOne);
    carbonCredit.setApprovalForAll(address(sctTreasury), true);
    vm.expectRevert(bytes("SCT Treasury: owner insuficient ERC1155 balance"));
    vm.stopPrank();
    sctTreasury.depositReserveToken(address(carbonCredit), 1, 999999, address(userOne));
    assertEq(carbonCredit.balanceOf(address(userOne), 1), 10000);
    assertEq(carbonCredit.balanceOf(address(sctTreasury), 1), 0);
    assertEq(sctERC20.balanceOf(address(userOne)), 0);
    assertEq(sctTreasury.carbonProjectTons(address(carbonCredit), 1), 0);
    assertEq(sctTreasury.carbonProjectBalances(address(carbonCredit), 1, userOne), 0);
    assertEq(sctTreasury.totalReserves(), 0);
    assertEq(sctTreasury.baseSupply(), 0);
  }

  function testDepositReserveTokenNotApproved() public {
    setUpCarbonProject();
    setUpCarbonToken();
    vm.prank(userOne);
    vm.expectRevert(bytes("SCT Treasury: owner not approved this contract spend ERC1155"));
    sctTreasury.depositReserveToken(address(carbonCredit), 1, 10000, address(userOne));
    assertEq(carbonCredit.balanceOf(address(userOne), 1), 10000);
    assertEq(carbonCredit.balanceOf(address(sctTreasury), 1), 0);
    assertEq(sctERC20.balanceOf(address(userOne)), 0);
    assertEq(sctTreasury.carbonProjectTons(address(carbonCredit), 1), 0);
    assertEq(sctTreasury.carbonProjectBalances(address(carbonCredit), 1, userOne), 0);
    assertEq(sctTreasury.totalReserves(), 0);
    assertEq(sctTreasury.baseSupply(), 0);
  }

  //Tests createOffer

  //Tests cancelOffer

  //Tests acceptOffer

}