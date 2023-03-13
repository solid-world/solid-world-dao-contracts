// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "./TestToken.sol";
import "./TestDataTypes.sol";
import "../../contracts/LiquidityDeployer.sol";

abstract contract BaseLiquidityDeployerTest is BaseTest {
    uint constant INITIAL_TOKEN_BALANCE = 1_000_000e18;
    uint constant MINTED_LP_TOKENS = 1_000_000e18;

    address token0;
    address token1;
    address uniProxy = vm.addr(4);
    uint conversionRate;
    uint8 conversionRateDecimals;

    ILiquidityDeployer liquidityDeployer;

    address testAccount0;
    address testAccount1 = vm.addr(6);
    address testAccount2 = vm.addr(7);

    TestToken lpToken;

    event TokenDeposited(address indexed token, address indexed depositor, uint indexed amount);
    event TokenWithdrawn(address indexed token, address indexed withdrawer, uint indexed amount);
    event LpTokenWithdrawn(address indexed withdrawer, uint indexed amount);

    function setUp() public virtual {
        lpToken = new TestToken("Gamma LP Token", "MCBT-USDC", 18);
        testAccount0 = address(this);

        address defaultToken0 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        address defaultToken1 = address(new TestToken("USD Coin", "USDC", 6));
        uint defaultConversionRate = 255;
        uint8 defaultConversionRateDecimals = 1;

        _init(defaultToken0, defaultToken1, defaultConversionRate, defaultConversionRateDecimals);
    }

    function _init(
        address token0_,
        address token1_,
        uint conversionRate_,
        uint8 conversionRateDecimals_
    ) internal {
        token0 = token0_;
        token1 = token1_;
        conversionRate = conversionRate_;
        conversionRateDecimals = conversionRateDecimals_;

        liquidityDeployer = new LiquidityDeployer(
            token0,
            token1,
            address(lpToken),
            uniProxy,
            conversionRate,
            conversionRateDecimals
        );

        _labelAccounts();
        _mintTokens();
        _approveSpending();

        _mockUniProxy_deposit();
    }

    function _labelAccounts() private {
        vm.label(token0, TestToken(token0).symbol());
        vm.label(token1, TestToken(token1).symbol());
        vm.label(address(lpToken), "LP Token");
        vm.label(uniProxy, "UniProxy");
        vm.label(address(liquidityDeployer), "Liquidity Deployer");
        vm.label(testAccount0, "Test Account 0");
        vm.label(testAccount1, "Test Account 1");
        vm.label(testAccount2, "Test Account 2");
    }

    function _mintTokens() private {
        TestToken(token0).mint(address(testAccount0), INITIAL_TOKEN_BALANCE);
        TestToken(token1).mint(address(testAccount0), INITIAL_TOKEN_BALANCE);

        TestToken(token0).mint(address(testAccount1), INITIAL_TOKEN_BALANCE);
        TestToken(token1).mint(address(testAccount1), INITIAL_TOKEN_BALANCE);

        lpToken.mint(address(liquidityDeployer), INITIAL_TOKEN_BALANCE);
    }

    function _approveSpending() private {
        vm.startPrank(testAccount0);
        IERC20(token0).approve(address(liquidityDeployer), type(uint).max);
        IERC20(token1).approve(address(liquidityDeployer), type(uint).max);
        vm.stopPrank();

        vm.startPrank(testAccount1);
        IERC20(token0).approve(address(liquidityDeployer), type(uint).max);
        IERC20(token1).approve(address(liquidityDeployer), type(uint).max);
        vm.stopPrank();
    }

    function _doDeposits(
        uint account0Token0Deposit,
        uint account0Token1Deposit,
        uint account1Token0Deposit,
        uint account1Token1Deposit
    ) internal {
        if (account0Token0Deposit > 0) {
            liquidityDeployer.depositToken0(account0Token0Deposit);
        }
        if (account0Token1Deposit > 0) {
            liquidityDeployer.depositToken1(account0Token1Deposit);
        }

        vm.startPrank(testAccount1);
        if (account1Token0Deposit > 0) {
            liquidityDeployer.depositToken0(account1Token0Deposit);
        }
        if (account1Token1Deposit > 0) {
            liquidityDeployer.depositToken1(account1Token1Deposit);
        }
        vm.stopPrank();
    }

    function _doDeposits(TestDataTypes.TestScenario storage testScenario) internal {
        _doDeposits(
            testScenario.account0Token0Deposit,
            testScenario.account0Token1Deposit,
            testScenario.account1Token0Deposit,
            testScenario.account1Token1Deposit
        );
    }

    function _mockUniProxy_deposit() internal {
        vm.mockCall(
            uniProxy,
            abi.encodeWithSelector(IUniProxy.deposit.selector),
            abi.encode(MINTED_LP_TOKENS)
        );
    }

    function _expectDepositIsCalledOnUniProxy(
        uint deposit0,
        uint deposit1,
        address to,
        address pos
    ) internal {
        uint[4] memory minIn = [uint(0), uint(0), uint(0), uint(0)];
        vm.expectCall(uniProxy, abi.encodeCall(IUniProxy.deposit, (deposit0, deposit1, to, pos, minIn)));
    }

    function _expectRevert_InvalidInput() internal {
        vm.expectRevert(abi.encodeWithSelector(ILiquidityDeployer.InvalidInput.selector));
    }

    function _expectRevert_InsufficientTokenBalance(
        address token,
        address account,
        uint balance,
        uint withdrawAmount
    ) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                ILiquidityDeployer.InsufficientTokenBalance.selector,
                token,
                account,
                balance,
                withdrawAmount
            )
        );
    }

    function _expectRevert_NotEnoughAvailableLiquidity(uint token0Liquidity, uint token1Liquidity) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                ILiquidityDeployer.NotEnoughAvailableLiquidity.selector,
                token0Liquidity,
                token1Liquidity
            )
        );
    }

    function _expectRevert_InsufficientLpTokenBalance(
        address account,
        uint balance,
        uint withdrawAmount
    ) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                ILiquidityDeployer.InsufficientLpTokenBalance.selector,
                account,
                balance,
                withdrawAmount
            )
        );
    }

    function _expectEmit_TokenDeposited(
        address token,
        address depositor,
        uint amount
    ) internal {
        vm.expectEmit(true, true, true, true, address(liquidityDeployer));
        emit TokenDeposited(token, depositor, amount);
    }

    function _expectEmit_TokenWithdrawn(
        address token,
        address withdrawer,
        uint amount
    ) internal {
        vm.expectEmit(true, true, true, true, address(liquidityDeployer));
        emit TokenWithdrawn(token, withdrawer, amount);
    }

    function _expectEmit_LpTokenWithdrawn(address withdrawer, uint amount) internal {
        vm.expectEmit(true, true, true, false, address(liquidityDeployer));
        emit LpTokenWithdrawn(withdrawer, amount);
    }
}
