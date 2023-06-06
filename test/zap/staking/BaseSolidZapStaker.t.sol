// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "../../BaseTest_0_8_18.sol";
import "../../../contracts/zap/staking/SolidZapStaker.sol";
import "../../../contracts/interfaces/staking/ISolidZapStaker.sol";
import "../../../contracts/interfaces/liquidity-deployer/IHypervisor_0_8_18.sol";
import "../../../contracts/interfaces/liquidity-deployer/IUniProxy_0_8_18.sol";
import "../../liquidity-deployer/TestToken.sol";
import "./MockRouter.sol";
import "./RouterBehaviour.sol";
import "./WMATIC.sol";

abstract contract BaseSolidZapStaker is BaseTest {
    uint public constant INITIAL_TOKEN_AMOUNT = 1000000;

    address public ROUTER;
    address public IUNIPROXY;
    address public SOLIDSTAKING;
    address public testAccount0;
    address public testAccount1;
    TestToken public inputToken;
    TestToken public hypervisor;
    TestToken public token0;
    TestToken public token1;
    WMATIC public weth;

    bytes public emptySwap1;
    bytes public emptySwap2;

    ISolidZapStaker public zapStaker;

    event ZapStake(
        address indexed recipient,
        address indexed inputToken,
        uint indexed inputAmount,
        uint shares
    );

    function setUp() public {
        emptySwap1 = _encodeSwap(RouterBehaviour.MINTS_TOKEN0, 0);
        emptySwap2 = _encodeSwap(RouterBehaviour.MINTS_TOKEN1, 0);

        IUNIPROXY = vm.addr(1);
        SOLIDSTAKING = vm.addr(2);
        testAccount0 = vm.addr(3);
        testAccount1 = vm.addr(4);
        inputToken = new TestToken("Input Token", "IT", 18);
        hypervisor = new TestToken("Hypervisor", "LP", 18);
        token0 = new TestToken("USDC", "USDC", 6);
        token1 = new TestToken("CRISP SCORED MANGROVES", "CRISP-M", 18);
        weth = new WMATIC();
        ROUTER = address(new MockRouter(address(token0), address(token1)));

        zapStaker = new SolidZapStaker(ROUTER, address(weth), IUNIPROXY, SOLIDSTAKING);

        _labelAccounts();
        _prepareZap();
    }

    function _expectEmit_ZapStake(
        address recipient,
        address _inputToken,
        uint inputAmount,
        uint shares
    ) internal {
        vm.expectEmit(true, true, true, true, address(zapStaker));
        emit ZapStake(recipient, _inputToken, inputAmount, shares);
    }

    function _expectCall_ERC20_transferFrom(address from, uint amount) internal {
        vm.expectCall(
            address(inputToken),
            abi.encodeCall(IERC20.transferFrom, (from, address(zapStaker), amount))
        );
    }

    function _expectCall_ERC20_approve_maxUint(address token, address spender) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.approve, (spender, type(uint256).max)));
    }

    function _doNotExpectCall_ERC20_approve_maxUint(address token, address spender) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.approve, (spender, type(uint256).max)), 0);
    }

    function _expectCall_swap(RouterBehaviour behaviour, uint acquiredAmount) internal {
        vm.expectCall(ROUTER, _encodeSwap(behaviour, acquiredAmount));
    }

    function _expectCall_deposit(
        uint deposit0,
        uint deposit1,
        address to,
        address pos,
        uint[4] memory minIn
    ) internal {
        vm.expectCall(
            IUNIPROXY,
            abi.encodeWithSelector(IUniProxy.deposit.selector, deposit0, deposit1, to, pos, minIn)
        );
    }

    function _doNotExpectCall_deposit() internal {
        vm.expectCall(IUNIPROXY, abi.encodeWithSelector(IUniProxy.deposit.selector), 0);
    }

    function _expectCall_getDepositAmount(
        address pos,
        address token,
        uint depositAmount
    ) internal {
        vm.expectCall(
            IUNIPROXY,
            abi.encodeWithSelector(IUniProxy.getDepositAmount.selector, pos, token, depositAmount)
        );
    }

    function _expectCall_stake(
        address token,
        uint amount,
        address recipient
    ) internal {
        vm.expectCall(
            SOLIDSTAKING,
            abi.encodeWithSignature("stake(address,uint256,address)", token, amount, recipient)
        );
    }

    function _expectRevert_GenericSwapError() internal {
        vm.expectRevert(abi.encodeWithSelector(ISolidZapStaker.GenericSwapError.selector));
    }

    function _expectRevert_AcquiredSharesLessThanMin(uint acquired, uint min) internal {
        vm.expectRevert(
            abi.encodeWithSelector(ISolidZapStaker.AcquiredSharesLessThanMin.selector, acquired, min)
        );
    }

    function _mockSolidStaking_stake() internal {
        vm.mockCall(SOLIDSTAKING, abi.encodeWithSignature("stake(address,uint256,address)"), abi.encode());
    }

    function _mockHypervisor_token0() internal {
        vm.mockCall(
            address(hypervisor),
            abi.encodeWithSelector(IHypervisor.token0.selector),
            abi.encode(address(token0))
        );
    }

    function _mockHypervisor_token1() internal {
        vm.mockCall(
            address(hypervisor),
            abi.encodeWithSelector(IHypervisor.token1.selector),
            abi.encode(address(token1))
        );
    }

    function _mockUniProxy_deposit(uint sharesMinted) internal {
        vm.mockCall(IUNIPROXY, abi.encodeWithSelector(IUniProxy.deposit.selector), abi.encode(sharesMinted));
    }

    function _mockUniProxy_getDepositAmount(uint amountOut) internal {
        vm.mockCall(
            IUNIPROXY,
            abi.encodeWithSelector(IUniProxy.getDepositAmount.selector),
            abi.encode(amountOut - 10, amountOut + 10) // +/- 10 to account for average
        );
    }

    function _setBalancesBeforeSwap(uint token0BalanceBeforeSwap, uint token1BalanceBeforeSwap) internal {
        token0.mint(address(zapStaker), token0BalanceBeforeSwap);
        token1.mint(address(zapStaker), token1BalanceBeforeSwap);
    }

    function _encodeSwap(RouterBehaviour behaviour, uint acquiredAmount)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSignature("swap(uint256,uint256)", uint(behaviour), acquiredAmount);
    }

    function _uniProxyMinIn() internal pure returns (uint[4] memory) {
        return [uint(0), uint(0), uint(0), uint(0)];
    }

    function _labelAccounts() private {
        vm.label(ROUTER, "Router");
        vm.label(address(weth), "WETH");
        vm.label(IUNIPROXY, "IUniProxy");
        vm.label(SOLIDSTAKING, "SolidStaking");
        vm.label(testAccount0, "TestAccount0");
        vm.label(testAccount1, "TestAccount1");
        vm.label(address(inputToken), "InputToken");
        vm.label(address(hypervisor), "Hypervisor");
        vm.label(address(token0), "Token0");
        vm.label(address(token1), "Token1");
        vm.label(address(zapStaker), "ZapStaker");
    }

    function _prepareZap() private {
        inputToken.mint(testAccount0, INITIAL_TOKEN_AMOUNT);
        hypervisor.mint(address(zapStaker), INITIAL_TOKEN_AMOUNT);

        vm.prank(testAccount0);
        inputToken.approve(address(zapStaker), INITIAL_TOKEN_AMOUNT);

        _mockHypervisor_token0();
        _mockHypervisor_token1();
        _mockUniProxy_deposit(0);
        _mockUniProxy_getDepositAmount(10);
        _mockSolidStaking_stake();
    }
}
