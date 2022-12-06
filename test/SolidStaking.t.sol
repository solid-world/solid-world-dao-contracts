pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../contracts/SolidStaking.sol";
import "../contracts/CollateralizedBasketToken.sol";

contract SolidStakingTest is Test {
    address emissionManager;
    address rewardsController;
    address carbonRewardsManager;
    SolidStaking solidStaking;

    address root = address(this);
    address testAccount = vm.addr(1);
    address testAccount2 = vm.addr(2);

    event Stake(address indexed account, address indexed token, uint indexed amount);
    event Withdraw(address indexed account, address indexed token, uint indexed amount);
    event TokenAdded(address indexed token);

    function setUp() public {
        rewardsController = vm.addr(3);
        carbonRewardsManager = vm.addr(4);
        emissionManager = vm.addr(5);

        solidStaking = new SolidStaking();
        solidStaking.setup(IRewardsController(rewardsController), root);

        vm.mockCall(
            rewardsController,
            abi.encodeWithSelector(IRewardsController.handleUserStakeChanged.selector),
            abi.encode()
        );

        vm.mockCall(
            rewardsController,
            abi.encodeWithSelector(IRewardsController.claimAllRewardsOnBehalf.selector),
            abi.encode(new address[](0), new uint[](0))
        );

        vm.label(root, "Root account");
        vm.label(testAccount, "Test account");
        vm.label(testAccount2, "Test account 2");
    }

    function testSetupFailsWhenAlreadyInitialized() public {
        vm.expectRevert(abi.encodeWithSelector(PostConstruct.AlreadyInitialized.selector));
        solidStaking.setup(IRewardsController(rewardsController), root);
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

        vm.expectRevert(
            abi.encodeWithSelector(ISolidStakingErrors.TokenAlreadyAdded.selector, tokenAddress)
        );
        solidStaking.addToken(tokenAddress);
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
            rewardsController,
            abi.encodeCall(
                IRewardsController.handleUserStakeChanged,
                (tokenAddress, testAccount, 0, 0)
            )
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

    function testStake_failsForInvalidTokenAddress() public {
        address invalidTokenAddress = vm.addr(777);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISolidStakingErrors.InvalidTokenAddress.selector,
                invalidTokenAddress
            )
        );
        solidStaking.stake(invalidTokenAddress, 100);
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
            rewardsController,
            abi.encodeCall(
                IRewardsController.handleUserStakeChanged,
                (tokenAddress, testAccount, amountToStake, amountToStake)
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

    function testWithdraw_failsForInvalidTokenAddress() public {
        address invalidTokenAddress = vm.addr(777);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISolidStakingErrors.InvalidTokenAddress.selector,
                invalidTokenAddress
            )
        );
        solidStaking.withdraw(invalidTokenAddress, 100);
    }

    function testWithdrawStakeAndClaimRewards() public {
        CollateralizedBasketToken token = new CollateralizedBasketToken("Test Token", "TT");
        address tokenAddress = address(token);
        vm.label(tokenAddress, "Test token");

        address[] memory assets = new address[](1);
        assets[0] = tokenAddress;

        solidStaking.addToken(tokenAddress);

        uint amountToStake = 100;
        uint amountToWithdraw = 50;
        token.mint(testAccount, amountToStake);

        vm.startPrank(testAccount);
        token.approve(address(solidStaking), amountToStake);
        solidStaking.stake(tokenAddress, amountToStake);

        vm.expectCall(
            rewardsController,
            abi.encodeCall(
                IRewardsController.handleUserStakeChanged,
                (tokenAddress, testAccount, amountToStake, amountToStake)
            )
        );
        vm.expectCall(
            rewardsController,
            abi.encodeCall(
                IRewardsController.claimAllRewardsOnBehalf,
                (assets, testAccount, testAccount)
            )
        );
        vm.expectEmit(true, true, true, false, address(solidStaking));
        emit Withdraw(testAccount, tokenAddress, amountToWithdraw);
        solidStaking.withdrawStakeAndClaimRewards(tokenAddress, amountToWithdraw);
        vm.stopPrank();

        assertEq(
            solidStaking.userStake(tokenAddress, testAccount),
            amountToStake - amountToWithdraw,
            "User stake should be updated"
        );
    }

    function testWithdrawStakeAndClaimRewards_failsForInvalidTokenAddress() public {
        address invalidTokenAddress = vm.addr(777);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISolidStakingErrors.InvalidTokenAddress.selector,
                invalidTokenAddress
            )
        );
        solidStaking.withdrawStakeAndClaimRewards(invalidTokenAddress, 100);
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

    function testTotalStaked() public {
        CollateralizedBasketToken token = new CollateralizedBasketToken("Test Token", "TT");
        CollateralizedBasketToken token2 = new CollateralizedBasketToken("Test Token 2", "TT2");

        address tokenAddress = address(token);
        address tokenAddress2 = address(token2);

        vm.label(tokenAddress, "Test token");
        vm.label(tokenAddress2, "Test token 2");

        solidStaking.addToken(tokenAddress);
        solidStaking.addToken(tokenAddress2);

        uint amountToStake = 100;
        token.mint(testAccount, amountToStake);
        token.mint(testAccount2, amountToStake);

        uint amountToStake2 = 55;
        token2.mint(testAccount, amountToStake2);
        token2.mint(testAccount2, amountToStake2);

        vm.startPrank(testAccount);
        token.approve(address(solidStaking), amountToStake);
        token2.approve(address(solidStaking), amountToStake2);
        solidStaking.stake(tokenAddress, amountToStake);
        solidStaking.stake(tokenAddress2, amountToStake2);
        vm.stopPrank();

        vm.startPrank(testAccount2);
        token.approve(address(solidStaking), amountToStake);
        token2.approve(address(solidStaking), amountToStake2);
        solidStaking.stake(tokenAddress, amountToStake);
        solidStaking.stake(tokenAddress2, amountToStake2);
        vm.stopPrank();

        assertEq(
            solidStaking.totalStaked(tokenAddress),
            amountToStake * 2,
            "Total staked should be equal to the staked amount"
        );

        assertEq(
            solidStaking.totalStaked(tokenAddress2),
            amountToStake2 * 2,
            "Total staked should be equal to the staked amount"
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
