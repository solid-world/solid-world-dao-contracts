// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/LiquidityDeployer.sol";
import "./TestToken.sol";

abstract contract BaseLiquidityDeployerTest is BaseTest {
    uint constant INITIAL_TOKEN_BALANCE = 10_000;
    address token0;
    address token1;
    address gammaVault = vm.addr(3);
    address uniProxy = vm.addr(4);
    uint conversionRate = 255;
    uint8 conversionRateDecimals = 1;

    ILiquidityDeployer liquidityDeployer;

    address testAccount0;
    address testAccount1 = vm.addr(6);

    event Token0Deposited(address indexed depositor, uint indexed amount);
    event Token1Deposited(address indexed depositor, uint indexed amount);
    event Token0Withdrawn(address indexed withdrawer, uint indexed amount);
    event Token1Withdrawn(address indexed withdrawer, uint indexed amount);

    function setUp() public {
        token0 = address(new TestToken("Mangrove Collateralized Basket Token", "MCBT", 18));
        token1 = address(new TestToken("USD Coin", "USDC", 6));
        testAccount0 = address(this);

        liquidityDeployer = new LiquidityDeployer(
            token0,
            token1,
            gammaVault,
            uniProxy,
            conversionRate,
            conversionRateDecimals
        );

        _labelAccounts();
        _mintTokens();
        _approveSpending();
    }

    function _labelAccounts() private {
        vm.label(token0, "MCBT");
        vm.label(token1, "USDC");
        vm.label(gammaVault, "Gamma Vault");
        vm.label(uniProxy, "UniProxy");
        vm.label(address(liquidityDeployer), "Liquidity Deployer");
        vm.label(testAccount0, "Test Account 0");
        vm.label(testAccount1, "Test Account 1");
    }

    function _mintTokens() private {
        TestToken(token0).mint(address(testAccount0), INITIAL_TOKEN_BALANCE);
        TestToken(token1).mint(address(testAccount0), INITIAL_TOKEN_BALANCE);

        TestToken(token0).mint(address(testAccount1), INITIAL_TOKEN_BALANCE);
        TestToken(token1).mint(address(testAccount1), INITIAL_TOKEN_BALANCE);
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

    function _expectRevert_InvalidInput() internal {
        vm.expectRevert(abi.encodeWithSelector(ILiquidityDeployer.InvalidInput.selector));
    }

    function _expectRevert_Token0AmountTooSmall(uint amount) internal {
        vm.expectRevert(abi.encodeWithSelector(ILiquidityDeployer.Token0AmountTooSmall.selector, amount));
    }

    function _expectRevert_InsufficientToken0Balance(
        address account,
        uint balance,
        uint withdrawAmount
    ) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                ILiquidityDeployer.InsufficientToken0Balance.selector,
                account,
                balance,
                withdrawAmount
            )
        );
    }

    function _expectRevert_InsufficientToken1Balance(
        address account,
        uint balance,
        uint withdrawAmount
    ) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                ILiquidityDeployer.InsufficientToken1Balance.selector,
                account,
                balance,
                withdrawAmount
            )
        );
    }

    function _expectEmit_Token0Deposited(address depositor, uint amount) internal {
        vm.expectEmit(true, true, true, false, address(liquidityDeployer));
        emit Token0Deposited(depositor, amount);
    }

    function _expectEmit_Token1Deposited(address depositor, uint amount) internal {
        vm.expectEmit(true, true, true, false, address(liquidityDeployer));
        emit Token1Deposited(depositor, amount);
    }

    function _expectEmit_Token0Withdrawn(address withdrawer, uint amount) internal {
        vm.expectEmit(true, true, true, false, address(liquidityDeployer));
        emit Token0Withdrawn(withdrawer, amount);
    }

    function _expectEmit_Token1Withdrawn(address withdrawer, uint amount) internal {
        vm.expectEmit(true, true, true, false, address(liquidityDeployer));
        emit Token1Withdrawn(withdrawer, amount);
    }
}
