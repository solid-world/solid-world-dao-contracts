// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BaseSolidStaking.t.sol";

contract SolidStakingTest is BaseSolidStakingTest {
    function testSetupFailsWhenAlreadyInitialized() public {
        _expectRevert_AlreadyInitialized();
        solidStaking.setup(IRewardsController(rewardsController), ownerAccount);
    }

    function testAddToken() public {
        (, address tokenAddress) = _createTestToken();

        _expectEmit_tokenAdded(tokenAddress);
        solidStaking.addToken(tokenAddress);

        assertTrue(solidStaking.tokenAdded(tokenAddress));
        assertEq(address(solidStaking.tokens(0)), address(tokenAddress));
    }

    function testAddTokenFailsWhenAddingSameTokenTwice() public {
        (, address tokenAddress) = _configuredTestToken();

        _expectRevert_TokenAlreadyAdded(tokenAddress);
        solidStaking.addToken(tokenAddress);
    }

    function testStake() public {
        uint stakeAmount = 100;
        (CollateralizedBasketToken token, address tokenAddress) = _configuredTestToken();

        vm.prank(testAccount);
        _expectCall_RewardsController_handleUserStakeChanged(tokenAddress);
        _expectEmit_Stake(testAccount, tokenAddress, stakeAmount);
        solidStaking.stake(tokenAddress, stakeAmount);

        assertEq(solidStaking.userStake(tokenAddress, testAccount), stakeAmount);
        assertEq(
            token.balanceOf(address(solidStaking)),
            stakeAmount,
            "SolidStaking contract balance should be updated"
        );
    }

    function testStake_revertsIfComplianceCheckFails() public {
        uint stakeAmount = 100;
        (, address token0Address) = _configuredTestToken();
        (, address token1Address) = _configuredTestToken();

        solidStaking.setKYCRequired(token1Address, true);

        vm.prank(testAccount);
        solidStaking.stake(token0Address, stakeAmount);

        vm.prank(testAccount);
        _expectRevert_NotRegulatoryCompliant(token1Address, testAccount);
        solidStaking.stake(token1Address, stakeAmount);

        verificationRegistry.registerVerification(testAccount);
        vm.prank(testAccount);
        solidStaking.stake(token1Address, stakeAmount);

        verificationRegistry.blacklist(testAccount2);
        vm.startPrank(testAccount2);
        _expectRevert_NotRegulatoryCompliant(token0Address, testAccount2);
        solidStaking.stake(token0Address, stakeAmount);
        _expectRevert_NotRegulatoryCompliant(token1Address, testAccount2);
        solidStaking.stake(token1Address, stakeAmount);
    }

    function testStake_failsForInvalidTokenAddress() public {
        address invalidTokenAddress = vm.addr(777);

        _expectRevert_InvalidTokenAddress(invalidTokenAddress);
        solidStaking.stake(invalidTokenAddress, 100);
    }

    function testStake_failsIfNotEnoughFunds() public {
        (CollateralizedBasketToken token, address tokenAddress) = _createTestToken();
        solidStaking.addToken(tokenAddress);

        vm.startPrank(testAccount);
        token.approve(address(solidStaking), type(uint).max);
        _expectRevertWithMessage("ERC20: transfer amount exceeds balance");
        solidStaking.stake(tokenAddress, 100);
    }

    function testWithdraw() public {
        uint amountToStake = 100;
        uint amountToWithdraw = 50;
        (CollateralizedBasketToken token, address tokenAddress) = _configuredTestToken();

        vm.startPrank(testAccount);
        solidStaking.stake(tokenAddress, amountToStake);

        _expectCall_RewardsController_handleUserStakeChanged(tokenAddress, amountToStake, amountToStake);
        _expectEmit_Withdraw(testAccount, tokenAddress, amountToWithdraw);
        solidStaking.withdraw(tokenAddress, amountToWithdraw);

        assertEq(solidStaking.userStake(tokenAddress, testAccount), amountToStake - amountToWithdraw);

        assertEq(
            token.balanceOf(address(solidStaking)),
            amountToStake - amountToWithdraw,
            "SolidStaking contract balance should be updated"
        );
    }

    function testWithdrawFailsWhenNotEnoughStaked() public {
        uint amountToStake = 100;
        uint amountToWithdraw = 150;
        (, address tokenAddress) = _configuredTestToken();

        vm.startPrank(testAccount);
        solidStaking.stake(tokenAddress, amountToStake);

        _expectRevert_ArithmeticError();
        solidStaking.withdraw(tokenAddress, amountToWithdraw);
    }

    function testWithdraw_failsForInvalidTokenAddress() public {
        address invalidTokenAddress = vm.addr(777);

        _expectRevert_InvalidTokenAddress(invalidTokenAddress);
        solidStaking.withdraw(invalidTokenAddress, 100);
    }

    function testWithdrawStakeAndClaimRewards() public {
        uint amountToStake = 100;
        uint amountToWithdraw = 50;
        (, address tokenAddress) = _configuredTestToken();
        address[] memory assets = _toArray(tokenAddress);

        vm.startPrank(testAccount);
        solidStaking.stake(tokenAddress, amountToStake);

        _expectCall_RewardsController_handleUserStakeChanged(tokenAddress, amountToStake, amountToStake);
        _expectCall_RewardsController_claimAllRewardsOnBehalf(assets);
        _expectEmit_Withdraw(testAccount, tokenAddress, amountToWithdraw);
        solidStaking.withdrawStakeAndClaimRewards(tokenAddress, amountToWithdraw);

        assertEq(
            solidStaking.userStake(tokenAddress, testAccount),
            amountToStake - amountToWithdraw,
            "User stake should be updated"
        );
    }

    function testWithdrawStakeAndClaimRewards_failsForInvalidTokenAddress() public {
        address invalidTokenAddress = vm.addr(777);

        _expectRevert_InvalidTokenAddress(invalidTokenAddress);
        solidStaking.withdrawStakeAndClaimRewards(invalidTokenAddress, 100);
    }

    function testWithdrawStakeAndClaimRewards_revertsIfComplianceCheckFails() public {
        uint amountToStake = 100;
        uint amountToWithdraw = 50;
        (, address token0Address) = _configuredTestToken();
        (, address token1Address) = _configuredTestToken();

        vm.prank(testAccount);
        solidStaking.stake(token0Address, amountToStake);
        vm.prank(testAccount);
        solidStaking.stake(token1Address, amountToStake);

        solidStaking.setKYCRequired(token1Address, true);

        vm.prank(testAccount);
        solidStaking.withdrawStakeAndClaimRewards(token0Address, amountToWithdraw);

        vm.prank(testAccount);
        _expectRevert_NotRegulatoryCompliant(token1Address, testAccount);
        solidStaking.withdrawStakeAndClaimRewards(token1Address, amountToWithdraw);

        verificationRegistry.registerVerification(testAccount);
        vm.prank(testAccount);
        solidStaking.withdrawStakeAndClaimRewards(token0Address, amountToWithdraw);

        verificationRegistry.blacklist(testAccount);

        vm.startPrank(testAccount);
        _expectRevert_NotRegulatoryCompliant(token0Address, testAccount);
        solidStaking.withdrawStakeAndClaimRewards(token0Address, amountToWithdraw);
        _expectRevert_NotRegulatoryCompliant(token1Address, testAccount);
        solidStaking.withdrawStakeAndClaimRewards(token1Address, amountToWithdraw);
    }

    function testBalanceOf() public {
        uint amountToStake = 100;
        (, address tokenAddress) = _configuredTestToken();

        vm.prank(testAccount);
        solidStaking.stake(tokenAddress, amountToStake);

        assertEq(solidStaking.balanceOf(tokenAddress, testAccount), amountToStake);
    }

    function testTotalStaked() public {
        uint amountToStake = 100;
        uint amountToStake2 = 55;
        (, address tokenAddress) = _configuredTestToken();
        (, address tokenAddress2) = _configuredTestToken();

        vm.startPrank(testAccount);
        solidStaking.stake(tokenAddress, amountToStake);
        solidStaking.stake(tokenAddress2, amountToStake2);
        vm.stopPrank();

        vm.startPrank(testAccount2);
        solidStaking.stake(tokenAddress, amountToStake);
        solidStaking.stake(tokenAddress2, amountToStake2);
        vm.stopPrank();

        assertEq(solidStaking.totalStaked(tokenAddress), amountToStake * 2);
        assertEq(solidStaking.totalStaked(tokenAddress2), amountToStake2 * 2);
    }

    function testGetTokens() public {
        (, address tokenAddress1) = _configuredTestToken();
        (, address tokenAddress2) = _configuredTestToken();
        (, address tokenAddress3) = _configuredTestToken();

        address[] memory tokens = solidStaking.getTokens();

        assertEq(tokens.length, 3);
        assertEq(tokens[0], tokenAddress1);
        assertEq(tokens[1], tokenAddress2);
        assertEq(tokens[2], tokenAddress3);
    }

    function testIsKYCRequired() public {
        address asset = vm.addr(1);
        assertFalse(solidStaking.isKYCRequired(asset));
    }

    function testSetKYCRequired() public {
        address asset = vm.addr(1);

        solidStaking.setKYCRequired(asset, true);
        assertTrue(solidStaking.isKYCRequired(asset));
    }

    function testSetKYCRequired_revertsIfNotOwner() public {
        address asset = vm.addr(1);

        vm.prank(testAccount);
        _expectRevertWithMessage("Ownable: caller is not the owner");
        solidStaking.setKYCRequired(asset, true);
    }

    function testSetKYCRequired_emitsEvent() public {
        address asset = vm.addr(1);

        _expectEmit_KYCRequiredSet(asset, true);
        solidStaking.setKYCRequired(asset, true);
    }

    function testSetVerificationRegistry_revertsIfNotOwner() public {
        address verificationRegistry = vm.addr(1);

        vm.prank(testAccount);
        _expectRevertWithMessage("Ownable: caller is not the owner");
        solidStaking.setVerificationRegistry(verificationRegistry);
    }

    function testSetVerificationRegistry_setsRegistry() public {
        address verificationRegistry = vm.addr(1);

        solidStaking.setVerificationRegistry(verificationRegistry);
        assertEq(solidStaking.getVerificationRegistry(), verificationRegistry);
    }
}
