// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/SolidStaking.sol";
import "../../contracts/CollateralizedBasketToken.sol";

abstract contract BaseSolidStakingTest is BaseTest {
    address emissionManager;
    address rewardsController;
    address carbonRewardsManager;
    SolidStaking solidStaking;

    address ownerAccount = address(this);
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
        solidStaking.setup(IRewardsController(rewardsController), ownerAccount);

        _installMocks();
        _labelAccounts();
    }

    function _installMocks() private {
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
    }

    function _labelAccounts() private {
        vm.label(emissionManager, "Emission manager");
        vm.label(rewardsController, "Rewards controller");
        vm.label(carbonRewardsManager, "Carbon rewards manager");
        vm.label(address(solidStaking), "Solid staking");
        vm.label(ownerAccount, "Owner account");
        vm.label(testAccount, "Test account");
        vm.label(testAccount2, "Test account 2");
    }

    function _expectEmit_tokenAdded(address tokenAddress) internal {
        vm.expectEmit(true, false, false, false, address(solidStaking));
        emit TokenAdded(tokenAddress);
    }

    function _expectEmit_Stake(
        address account,
        address tokenAddress,
        uint amount
    ) internal {
        vm.expectEmit(true, true, true, false, address(solidStaking));
        emit Stake(account, tokenAddress, amount);
    }

    function _expectEmit_Withdraw(
        address account,
        address tokenAddress,
        uint amount
    ) internal {
        vm.expectEmit(true, true, true, false, address(solidStaking));
        emit Withdraw(account, tokenAddress, amount);
    }

    function _expectRevert_AlreadyInitialized() internal {
        vm.expectRevert(abi.encodeWithSelector(PostConstruct.AlreadyInitialized.selector));
    }

    function _expectRevert_TokenAlreadyAdded(address tokenAddress) internal {
        vm.expectRevert(abi.encodeWithSelector(ISolidStakingErrors.TokenAlreadyAdded.selector, tokenAddress));
    }

    function _expectRevert_InvalidTokenAddress(address tokenAddress) internal {
        vm.expectRevert(
            abi.encodeWithSelector(ISolidStakingErrors.InvalidTokenAddress.selector, tokenAddress)
        );
    }

    function _expectCall_RewardsController_handleUserStakeChanged(address tokenAddress) internal {
        uint oldUserStake = 0;
        uint oldTotalStaked = 0;
        _expectCall_RewardsController_handleUserStakeChanged(tokenAddress, oldUserStake, oldTotalStaked);
    }

    function _expectCall_RewardsController_handleUserStakeChanged(
        address tokenAddress,
        uint oldUserStake,
        uint oldTotalStaked
    ) internal {
        vm.expectCall(
            rewardsController,
            abi.encodeCall(
                IRewardsController.handleUserStakeChanged,
                (tokenAddress, testAccount, oldUserStake, oldTotalStaked)
            )
        );
    }

    function _expectCall_RewardsController_claimAllRewardsOnBehalf(address[] memory assets) internal {
        vm.expectCall(
            rewardsController,
            abi.encodeCall(IRewardsController.claimAllRewardsOnBehalf, (assets, testAccount, testAccount))
        );
    }

    function _createTestToken() internal returns (CollateralizedBasketToken token, address tokenAddress) {
        token = new CollateralizedBasketToken("Test Token", "TT");
        tokenAddress = address(token);
        vm.label(tokenAddress, "Test token");
    }

    function _configuredTestToken() internal returns (CollateralizedBasketToken token, address tokenAddress) {
        (token, tokenAddress) = _createTestToken();
        _configureTestToken(token, tokenAddress);
    }

    function _configureTestToken(CollateralizedBasketToken token, address tokenAddress) internal {
        token.mint(testAccount, 100000);
        token.mint(testAccount2, 100000);

        vm.prank(testAccount);
        token.approve(address(solidStaking), type(uint).max);
        vm.prank(testAccount2);
        token.approve(address(solidStaking), type(uint).max);

        solidStaking.addToken(tokenAddress);
    }
}
