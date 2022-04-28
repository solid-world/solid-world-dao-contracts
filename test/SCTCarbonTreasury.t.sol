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

}