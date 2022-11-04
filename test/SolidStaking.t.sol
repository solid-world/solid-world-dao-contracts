pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/SolidStaking.sol";
import "../contracts/CollateralizedBasketToken.sol";
import "../contracts/RewardsController.sol";

contract SolidStakingTest is Test {
    RewardsController rewardsController;
    SolidStaking solidStaking;

    address root = address(this);
    address testAccount = vm.addr(1);

    event Stake(address indexed account, address indexed token, uint indexed amount);
    event Withdraw(address indexed account, address indexed token, uint indexed amount);
    event TokenAdded(address indexed token);

    function setUp() public {
        rewardsController = new RewardsController();
        solidStaking = new SolidStaking(rewardsController);

        vm.label(root, "Root account");
        vm.label(testAccount, "Test account");
    }

    function testAddToken() public {
        IERC20 token = new CollateralizedBasketToken("Test Token", "TT");
        address tokenAddress = address(token);
        vm.label(tokenAddress, "Test token");

        assertFalse(solidStaking.tokenAdded(tokenAddress), "Token should not be added yet");

        vm.expectEmit(true, false, false, false, address(solidStaking));
        emit TokenAdded(tokenAddress);
        solidStaking.addToken(tokenAddress);

        assertTrue(solidStaking.tokenAdded(tokenAddress), "Token should be added");
        assertEq(
            address(solidStaking.tokens(0)),
            address(tokenAddress),
            "Tokens array should have the added token"
        );
    }

    function testAddTokenFailsWhenAddingSameTokenTwice() public {
        IERC20 token = new CollateralizedBasketToken("Test Token", "TT");
        address tokenAddress = address(token);
        vm.label(tokenAddress, "Test token");

        assertFalse(solidStaking.tokenAdded(tokenAddress), "Token should not be added yet");

        solidStaking.addToken(tokenAddress);

        vm.expectRevert(abi.encodePacked("SolidStaking: Token already added"));
        solidStaking.addToken(tokenAddress);
    }

    function testValidTokenModifier() public {
        IERC20 token = new CollateralizedBasketToken("Test Token", "TT");
        address tokenAddress = address(token);
        vm.label(tokenAddress, "Test token");

        vm.expectRevert(abi.encodePacked("SolidStaking: Invalid token address"));
        solidStaking.stake(tokenAddress, 100);
    }

    function testStake() public {
        CollateralizedBasketToken token = new CollateralizedBasketToken("Test Token", "TT");
        address tokenAddress = address(token);
        vm.label(tokenAddress, "Test token");

        solidStaking.addToken(tokenAddress);

        uint amount = 100;
        token.mint(testAccount, amount);

        vm.startPrank(testAccount);
        token.approve(address(solidStaking), amount);

        vm.expectCall(
            address(rewardsController),
            abi.encodeCall(rewardsController.handleAction, (testAccount, 0, 0))
        );
        vm.expectEmit(true, true, true, false, address(solidStaking));
        emit Stake(testAccount, tokenAddress, amount);
        solidStaking.stake(tokenAddress, amount);
        vm.stopPrank();

        assertEq(
            solidStaking.userStake(tokenAddress, testAccount),
            amount,
            "User stake should be updated"
        );

        assertEq(
            token.balanceOf(address(solidStaking)),
            amount,
            "SolidStaking contract balance should be updated"
        );
    }

    function testWithdraw() public {
        CollateralizedBasketToken token = new CollateralizedBasketToken("Test Token", "TT");
        address tokenAddress = address(token);
        vm.label(tokenAddress, "Test token");

        solidStaking.addToken(tokenAddress);

        uint amountToStake = 100;
        uint amountToWithdraw = 50;
        token.mint(testAccount, amountToStake);

        vm.startPrank(testAccount);
        token.approve(address(solidStaking), amountToStake);
        solidStaking.stake(tokenAddress, amountToStake);

        vm.expectCall(
            address(rewardsController),
            abi.encodeCall(
                rewardsController.handleAction,
                (testAccount, amountToStake, amountToStake)
            )
        );
        vm.expectEmit(true, true, true, false, address(solidStaking));
        emit Withdraw(testAccount, tokenAddress, amountToWithdraw);
        solidStaking.withdraw(tokenAddress, amountToWithdraw);
        vm.stopPrank();

        assertEq(
            solidStaking.userStake(tokenAddress, testAccount),
            amountToStake - amountToWithdraw,
            "User stake should be updated"
        );

        assertEq(
            token.balanceOf(address(solidStaking)),
            amountToStake - amountToWithdraw,
            "SolidStaking contract balance should be updated"
        );
    }

    function testWithdrawFailsWhenNotEnoughStaked() public {
        CollateralizedBasketToken token = new CollateralizedBasketToken("Test Token", "TT");
        address tokenAddress = address(token);
        vm.label(tokenAddress, "Test token");

        solidStaking.addToken(tokenAddress);

        uint amountToStake = 100;
        uint amountToWithdraw = 150;
        token.mint(testAccount, amountToStake);

        vm.startPrank(testAccount);
        token.approve(address(solidStaking), amountToStake);
        solidStaking.stake(tokenAddress, amountToStake);

        vm.expectRevert(stdError.arithmeticError);
        solidStaking.withdraw(tokenAddress, amountToWithdraw);
        vm.stopPrank();
    }

    function testBalanceOf() public {
        CollateralizedBasketToken token = new CollateralizedBasketToken("Test Token", "TT");
        address tokenAddress = address(token);
        vm.label(tokenAddress, "Test token");

        solidStaking.addToken(tokenAddress);

        uint amountToStake = 100;
        token.mint(testAccount, amountToStake);

        vm.startPrank(testAccount);
        token.approve(address(solidStaking), amountToStake);
        solidStaking.stake(tokenAddress, amountToStake);
        vm.stopPrank();

        assertEq(
            solidStaking.balanceOf(tokenAddress, testAccount),
            amountToStake,
            "Balance should be equal to the staked amount"
        );
    }

    function testGetTokens() public {
        CollateralizedBasketToken token1 = new CollateralizedBasketToken("Test Token 1", "TT1");
        CollateralizedBasketToken token2 = new CollateralizedBasketToken("Test Token 2", "TT2");
        CollateralizedBasketToken token3 = new CollateralizedBasketToken("Test Token 3", "TT3");
        vm.label(address(token1), "Test token 1");
        vm.label(address(token2), "Test token 2");
        vm.label(address(token3), "Test token 3");

        solidStaking.addToken(address(token1));
        solidStaking.addToken(address(token2));
        solidStaking.addToken(address(token3));

        address[] memory tokens = solidStaking.getTokens();

        assertEq(tokens.length, 3, "Tokens array should have 3 elements");
        assertEq(tokens[0], address(token1), "Tokens array should have token 1");
        assertEq(tokens[1], address(token2), "Tokens array should have token 2");
        assertEq(tokens[2], address(token3), "Tokens array should have token 3");
    }
}