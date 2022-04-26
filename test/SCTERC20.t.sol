// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../contracts/SolidDaoManagement.sol";
import "../contracts/SCTERC20.sol";
import "../contracts/lib/ECDSA.sol";

contract SCTERC20Test is Test {

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  SolidDaoManagement private solidDaoManagement;
  SCTERC20Token private sct;

  bytes32 typeHash = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
  );
  bytes32 permitTypeHash = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
  );
  bytes32 hashedName = keccak256(bytes("SCT"));
  bytes32 hashedVersion = keccak256(bytes("1"));

  address internal governor = vm.addr(1);
  address internal guardian = vm.addr(2);
  address internal policy = vm.addr(3);
  address internal vault = vm.addr(4);

  address internal userOne = vm.addr(5);
  address internal userTwo = vm.addr(6);
  address internal userThree = vm.addr(7);
  address internal userFour = vm.addr(8);
  
  function setUp() public {
    solidDaoManagement = new SolidDaoManagement(
      governor,
      policy,
      guardian,
      vault
    );
    sct = new SCTERC20Token(address(solidDaoManagement));
    vm.startPrank(vault);
    sct.mint(userOne, 1000);
    sct.mint(userTwo, 1000);
    vm.stopPrank();
  }

  function testName() public {
    assertEq(sct.name(), "SCT");
  }

  function testSymbol() public {
    assertEq(sct.symbol(), "SCT");
  }

  function testDecimals() public {
    assertEq(sct.decimals(), 9);
  }

  function testTotalSupply() public {
    assertEq(sct.totalSupply(), 2000);
  }

  function testBalanceOf() public {
    assertEq(sct.balanceOf(userOne), 1000);
    assertEq(sct.balanceOf(userTwo), 1000);
    assertEq(sct.balanceOf(userThree), 0);
    assertEq(sct.balanceOf(userFour), 0);
  }

  function testTransferWithSuccess() public {
    vm.prank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Transfer(userOne, userThree, 500);
    sct.transfer(userThree, 500);
    assertEq(sct.balanceOf(userOne), 500);
    assertEq(sct.balanceOf(userThree), 500);
  }

  function testTransferWhenAmmountExceedsBalance() public {
    vm.prank(userOne);
    vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
    sct.transfer(userThree, 999999);
    assertEq(sct.balanceOf(userOne), 1000);
    assertEq(sct.balanceOf(userThree), 0);
  }

  function testTransferWhenAmmountIsZero() public {
    vm.prank(userThree);
    vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
    sct.transfer(userFour, 1);
    assertEq(sct.balanceOf(userThree), 0);
    assertEq(sct.balanceOf(userFour), 0);
  }

  function testTransferToZeroAddress() public {
    vm.prank(userOne);
    vm.expectRevert(bytes("ERC20: transfer to the zero address"));
    sct.transfer(address(0), 1);
    assertEq(sct.balanceOf(userOne), 1000);
    assertEq(sct.balanceOf(address(0)), 0);
  }

  function testApproveWithSuccess() public {
    vm.prank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userThree, 999999);
    sct.approve(userThree, 999999);
    assertEq(sct.balanceOf(userOne), 1000);
    assertEq(sct.allowance(userOne, userThree), 999999);
  }

  function testApproveFromZeroAddress() public {
    vm.prank(address(0));
    vm.expectRevert(bytes("ERC20: approve from the zero address"));
    sct.approve(userOne, 1000);
    assertEq(sct.allowance(address(0), userOne), 0);
  }

  function testApproveToZeroAddress() public {
    vm.prank(userOne);
    vm.expectRevert(bytes("ERC20: approve to the zero address"));
    sct.approve(address(0), 1000);
    assertEq(sct.allowance(userOne, address(0)), 0);
  }

  function testTransferFromWithSuccess() public {
    vm.prank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userThree, 500);
    sct.approve(userThree, 500);
    assertEq(sct.allowance(userOne, userThree), 500);
    vm.prank(userThree);
    vm.expectEmit(true, true, true, true);
    emit Transfer(userOne, userFour, 500);
    sct.transferFrom(userOne, userFour, 500);
    assertEq(sct.allowance(userOne, userThree), 0);
    assertEq(sct.balanceOf(userOne), 500);
    assertEq(sct.balanceOf(userFour), 500);
  }

  function testTransferFromInsufficientAllowance() public {
    vm.prank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userThree, 500);
    sct.approve(userThree, 500);
    assertEq(sct.allowance(userOne, userThree), 500);
    vm.prank(userThree);
    vm.expectRevert(bytes("ERC20: insufficient allowance"));
    sct.transferFrom(userOne, userFour, 1000);
    assertEq(sct.allowance(userOne, userThree), 500);
    assertEq(sct.balanceOf(userOne), 1000);
    assertEq(sct.balanceOf(userFour), 0);
  }

  function testTransferFromInsufficientBalance() public {
    vm.prank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userThree, 999999);
    sct.approve(userThree, 999999);
    assertEq(sct.allowance(userOne, userThree), 999999);
    vm.prank(userThree);
    vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
    sct.transferFrom(userOne, userFour, 999999);
    assertEq(sct.allowance(userOne, userThree), 999999);
    assertEq(sct.balanceOf(userOne), 1000);
    assertEq(sct.balanceOf(userFour), 0);
  }

  function testIncreaseAllowancewWithSuccess() public {
    vm.startPrank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userThree, 1000);
    sct.increaseAllowance(userThree, 1000);
    assertEq(sct.allowance(userOne, userThree), 1000);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userThree, 2000);
    sct.increaseAllowance(userThree, 1000);
    assertEq(sct.allowance(userOne, userThree), 2000);
    vm.stopPrank();
  }

  function testDecreaseAllowancewWithSuccess() public {
    vm.startPrank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userThree, 1000);
    sct.increaseAllowance(userThree, 1000);
    assertEq(sct.allowance(userOne, userThree), 1000);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userThree, 500);
    sct.decreaseAllowance(userThree, 500);
    assertEq(sct.allowance(userOne, userThree), 500);
    vm.stopPrank();
  }

  function testDecreaseAllowancewBellowZero() public {
    vm.startPrank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userThree, 1000);
    sct.increaseAllowance(userThree, 1000);
    assertEq(sct.allowance(userOne, userThree), 1000);
    vm.expectRevert(bytes("ERC20: decreased allowance below zero"));
    sct.decreaseAllowance(userThree, 99999);
    assertEq(sct.allowance(userOne, userThree), 1000);
    vm.stopPrank();
  }

  function testMintWithSuccess() public {
    vm.prank(vault);
    vm.expectEmit(true, true, true, true);
    emit Transfer(address(0), userThree, 1000);
    sct.mint(userThree, 1000);
    assertEq(sct.balanceOf(userThree), 1000);
    assertEq(sct.totalSupply(), 3000);
  }

  function testMintWithNoAuthorization() public {
    vm.prank(governor);
    vm.expectRevert(bytes("UNAUTHORIZED"));
    sct.mint(userThree, 1000);
    assertEq(sct.balanceOf(userThree), 0);
    assertEq(sct.totalSupply(), 2000);
  }

  function testMintToZeroAddress() public {
    vm.prank(vault);
    vm.expectRevert(bytes("ERC20: mint to the zero address"));
    sct.mint(address(0), 1000);
    assertEq(sct.balanceOf(address(0)), 0);
    assertEq(sct.totalSupply(), 2000);
  }

  function testBurnWithSuccess() public {
    vm.prank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Transfer(userOne, address(0), 1000);
    sct.burn(1000);
    assertEq(sct.balanceOf(userOne), 0);
    assertEq(sct.totalSupply(), 1000);
  }

  function testBurnWithZeroBalance() public {
    vm.prank(userThree);
    vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
    sct.burn(1000);
    assertEq(sct.balanceOf(userThree), 0);
  }

  function testBurnWhenAmmountExceedsBalance() public {
    vm.prank(userOne);
    vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
    sct.burn(999999);
    assertEq(sct.balanceOf(userOne), 1000);
  }

  function testBurnZeroAddress() public {
    vm.prank(address(0));
    vm.expectRevert(bytes("ERC20: burn from the zero address"));
    sct.burn(1000);
    assertEq(sct.balanceOf(address(0)), 0);
  }

  function testBurnFromWithSuccess() public {
    vm.prank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userTwo, 500);
    sct.approve(userTwo, 500);
    assertEq(sct.allowance(userOne, userTwo), 500);
    vm.prank(userTwo);
    vm.expectEmit(true, true, true, true);
    emit Transfer(userOne, address(0), 500);
    sct.burnFrom(userOne, 500);
    assertEq(sct.allowance(userOne, userTwo), 0);
    assertEq(sct.balanceOf(userOne), 500);
    assertEq(sct.totalSupply(), 1500);
  }

  function testBurnFromInsufficientAllowance() public {
    vm.prank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userTwo, 500);
    sct.approve(userTwo, 500);
    assertEq(sct.allowance(userOne, userTwo), 500);
    vm.prank(userTwo);
    vm.expectRevert(stdError.arithmeticError);
    sct.burnFrom(userOne, 999999);
    assertEq(sct.allowance(userOne, userTwo), 500);
    assertEq(sct.balanceOf(userOne), 1000);
    assertEq(sct.totalSupply(), 2000);
  }

  function testBurnFromInsufficientBalance() public {
    vm.prank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userTwo, 999999);
    sct.approve(userTwo, 999999);
    assertEq(sct.allowance(userOne, userTwo), 999999);
    vm.prank(userTwo);
    vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
    sct.burnFrom(userOne, 999999);
    assertEq(sct.allowance(userOne, userTwo), 999999);
    assertEq(sct.balanceOf(userOne), 1000);
    assertEq(sct.totalSupply(), 2000);
  }

  function testPermitWithSuccess() public {
    bytes32 domainSeparator = keccak256(
      abi.encode(typeHash, hashedName, hashedVersion, block.chainid, address(sct))
    );
    uint256 nonce = vm.getNonce(userOne);
    bytes32 structHash = keccak256(
      abi.encode(permitTypeHash, userOne, userTwo, 1000, nonce, 1700000000)
    );
    bytes32 hash = ECDSA.toTypedDataHash(domainSeparator, structHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(5, hash);
    vm.warp(1600000000);
    vm.prank(userOne);
    vm.expectEmit(true, true, true, true);
    emit Approval(userOne, userTwo, 1000);
    sct.permit(userOne, userTwo, 1000, 1700000000, v, r, s);
    assertEq(sct.allowance(userOne, userTwo), 1000);
  }

  function testPermitExpiredDeadline() public {
    bytes32 domainSeparator = keccak256(
      abi.encode(typeHash, hashedName, hashedVersion, block.chainid, address(sct))
    );
    uint256 nonce = vm.getNonce(userOne);
    bytes32 structHash = keccak256(
      abi.encode(permitTypeHash, userOne, userTwo, 1000, nonce, 1700000000)
    );
    bytes32 hash = ECDSA.toTypedDataHash(domainSeparator, structHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(5, hash);
    vm.warp(1800000000);
    vm.prank(userOne);
    vm.expectRevert(bytes("ERC20Permit: expired deadline"));
    sct.permit(userOne, userTwo, 1000, 1700000000, v, r, s);
    assertEq(sct.allowance(userOne, userTwo), 0);
  }

  function testPermitInvalidSignature() public {
    bytes32 domainSeparator = keccak256(
      abi.encode(typeHash, hashedName, hashedVersion, block.chainid, address(sct))
    );
    uint256 nonce = vm.getNonce(userOne);
    bytes32 structHash = keccak256(
      abi.encode(permitTypeHash, userOne, userTwo, 1000, nonce, 1700000000)
    );
    bytes32 hash = ECDSA.toTypedDataHash(domainSeparator, structHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
    vm.warp(1600000000);
    vm.prank(userOne);
    vm.expectRevert(bytes("ERC20Permit: invalid signature"));
    sct.permit(userOne, userTwo, 1000, 1700000000, v, r, s);
    assertEq(sct.allowance(userOne, userTwo), 0);
  }

  function testPermitToZeroAddress() public {
    bytes32 domainSeparator = keccak256(
      abi.encode(typeHash, hashedName, hashedVersion, block.chainid, address(sct))
    );
    uint256 nonce = vm.getNonce(userOne);
    bytes32 structHash = keccak256(
      abi.encode(permitTypeHash, userOne, address(0), 1000, nonce, 1700000000)
    );
    bytes32 hash = ECDSA.toTypedDataHash(domainSeparator, structHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(5, hash);
    vm.warp(1600000000);
    vm.prank(userOne);
    vm.expectRevert(bytes("ERC20: approve to the zero address"));
    sct.permit(userOne, address(0), 1000, 1700000000, v, r, s);
    assertEq(sct.allowance(userOne, address(0)), 0);
  }

}