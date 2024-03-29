// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../BaseTest.sol";
import "../../contracts/SolidStaking.sol";
import "../../contracts/CollateralizedBasketToken.sol";
import "../../contracts/compliance/VerificationRegistry.sol";

abstract contract BaseSolidStakingTest is BaseTest {
    uint constant INITIAL_LP_TOKEN_BALANCE = 100000;
    address emissionManager;
    address rewardsController;
    address carbonRewardsManager;
    IVerificationRegistry verificationRegistry;
    SolidStaking solidStaking;

    address ownerAccount = address(this);
    address testAccount = vm.addr(1);
    address testAccount2 = vm.addr(2);
    address timelockController = vm.addr(13);

    event Stake(address indexed account, address indexed token, uint indexed amount);
    event Withdraw(address indexed account, address indexed token, uint indexed amount);
    event TokenAdded(address indexed token);
    event KYCRequiredSet(address indexed token, bool indexed kycRequired);

    function setUp() public {
        rewardsController = vm.addr(3);
        carbonRewardsManager = vm.addr(4);
        emissionManager = vm.addr(5);

        _initVerificationRegistry();

        solidStaking = new SolidStaking(address(verificationRegistry), timelockController);
        solidStaking.setup(IRewardsController(rewardsController), ownerAccount);

        _installMocks();
        _labelAccounts();
    }

    function _initVerificationRegistry() private {
        VerificationRegistry _verificationRegistry = new VerificationRegistry();
        _verificationRegistry.initialize(address(this));

        verificationRegistry = IVerificationRegistry(address(_verificationRegistry));
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
        vm.label(address(verificationRegistry), "Verification registry");
        vm.label(address(solidStaking), "Solid staking");
        vm.label(ownerAccount, "Owner account");
        vm.label(testAccount, "Test account");
        vm.label(testAccount2, "Test account 2");
        vm.label(timelockController, "Timelock controller");
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

    function _expectEmit_KYCRequiredSet(address _token, bool _kycRequired) internal {
        vm.expectEmit(true, true, true, false, address(solidStaking));
        emit KYCRequiredSet(_token, _kycRequired);
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

    function _expectRevert_NotRegulatoryCompliant(address token, address subject) internal {
        vm.expectRevert(
            abi.encodeWithSelector(ISolidStakingErrors.NotRegulatoryCompliant.selector, token, subject)
        );
    }

    function _expectRevert_Blacklisted(address subject) internal {
        vm.expectRevert(abi.encodeWithSelector(ISolidStakingErrors.Blacklisted.selector, subject));
    }

    function _expectRevert_NotTimelockController(address caller) internal {
        vm.expectRevert(abi.encodeWithSelector(ISolidStakingErrors.NotTimelockController.selector, caller));
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
        token = new CollateralizedBasketToken("Test Token", "TT", address(verificationRegistry));
        tokenAddress = address(token);
        vm.label(tokenAddress, "Test token");
    }

    function _configuredTestToken() internal returns (CollateralizedBasketToken token, address tokenAddress) {
        (token, tokenAddress) = _createTestToken();
        _configureTestToken(token, tokenAddress);
    }

    function _configureTestToken(CollateralizedBasketToken token, address tokenAddress) internal {
        token.mint(testAccount, INITIAL_LP_TOKEN_BALANCE);
        token.mint(testAccount2, INITIAL_LP_TOKEN_BALANCE);

        vm.prank(testAccount);
        token.approve(address(solidStaking), type(uint).max);
        vm.prank(testAccount2);
        token.approve(address(solidStaking), type(uint).max);

        solidStaking.addToken(tokenAddress);
    }
}
