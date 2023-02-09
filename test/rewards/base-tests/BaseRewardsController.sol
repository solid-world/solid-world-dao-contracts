// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../BaseTest.sol";
import "../../../contracts/interfaces/rewards/IRewardsController.sol";
import "../../../contracts/rewards/RewardsController.sol";

abstract contract BaseRewardsControllerTest is BaseTest {
    event AssetConfigUpdated(
        address indexed asset,
        address indexed reward,
        uint oldEmission,
        uint newEmission,
        uint oldDistributionEnd,
        uint newDistributionEnd,
        uint assetIndex
    );
    event RewardOracleUpdated(address indexed reward, address indexed rewardOracle);
    event ClaimerSet(address indexed user, address indexed claimer);
    event RewardsVaultUpdated(address indexed rewardsVault);
    event SolidStakingUpdated(address indexed solidStaking);

    uint32 constant CURRENT_DATE = 1666016743;

    RewardsDataTypes.DistributionConfig[2] testConfig;
    IRewardsController rewardsController;
    address solidStakingViewActions;
    address rewardsVault;
    address emissionManager;
    address arbitraryAccount;

    function setUp() public {
        vm.warp(CURRENT_DATE);

        solidStakingViewActions = vm.addr(1);
        rewardsVault = vm.addr(2);
        emissionManager = vm.addr(3);
        arbitraryAccount = vm.addr(777);
        rewardsController = new RewardsController();

        vm.expectEmit(true, false, false, false, address(rewardsController));
        emit SolidStakingUpdated(solidStakingViewActions);
        vm.expectEmit(true, false, false, false, address(rewardsController));
        emit RewardsVaultUpdated(rewardsVault);
        RewardsController(address(rewardsController)).setup(
            solidStakingViewActions,
            rewardsVault,
            emissionManager
        );

        _createTestDistributionConfig();
        _mockDistributionConfigOrdinaryCalls();
        _labelAccounts();
    }

    function _labelAccounts() private {
        vm.label(address(rewardsController), "RewardsController");
        vm.label(rewardsVault, "RewardsVault");
        vm.label(emissionManager, "EmissionManager");
        vm.label(solidStakingViewActions, "SolidStakingViewActions");
        vm.label(arbitraryAccount, "ArbitraryAccount");
    }

    function _expectEmitAssetConfigUpdated(address asset, address reward) internal {
        vm.expectEmit(true, true, false, false, address(rewardsController));
        emit AssetConfigUpdated(asset, reward, 0, 0, 0, 0, 0);
    }

    function _expectEmitRewardOracleUpdated(address reward, IEACAggregatorProxy rewardOracle) internal {
        vm.expectEmit(true, true, false, false, address(rewardsController));
        emit RewardOracleUpdated(reward, address(rewardOracle));
    }

    function _expectEmit_ClaimerSet(address user, address claimer) internal {
        vm.expectEmit(true, true, false, false, address(rewardsController));
        emit ClaimerSet(user, claimer);
    }

    function _expectEmit_RewardsVaultUpdated(address _rewardsVault) internal {
        vm.expectEmit(true, false, false, false, address(rewardsController));
        emit RewardsVaultUpdated(_rewardsVault);
    }

    function _expectEmit_SolidStakingUpdated(address _solidStaking) internal {
        vm.expectEmit(true, false, false, false, address(rewardsController));
        emit SolidStakingUpdated(_solidStaking);
    }

    function _expectRevert_InvalidRewardOracle(address reward, IEACAggregatorProxy rewardOracle) internal {
        vm.expectRevert(
            abi.encodeWithSelector(
                IRewardsController.InvalidRewardOracle.selector,
                reward,
                address(rewardOracle)
            )
        );
    }

    function _expectRevert_NotEmissionManager(address sender) internal {
        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.NotEmissionManager.selector, sender));
    }

    function _expectRevert_InvalidAssetDecimals(address asset) internal {
        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidAssetDecimals.selector, asset));
    }

    function _expectRevert_NotSolidStaking(address sender) internal {
        vm.expectRevert(abi.encodeWithSelector(IRewardsController.NotSolidStaking.selector, sender));
    }

    function _expectRevert_InvalidInput() internal {
        vm.expectRevert(abi.encodeWithSelector(IRewardsDistributor.InvalidInput.selector));
    }

    function _expectRevert_UnauthorizedClaimer(address claimer, address user) internal {
        vm.expectRevert(
            abi.encodeWithSelector(IRewardsController.UnauthorizedClaimer.selector, claimer, user)
        );
    }

    function _createTestDistributionConfig() private {
        testConfig[0].reward = vm.addr(4);
        testConfig[0].asset = vm.addr(5);
        testConfig[0].emissionPerSecond = 100;
        testConfig[0].distributionEnd = CURRENT_DATE;
        testConfig[0].rewardOracle = IEACAggregatorProxy(vm.addr(6));

        testConfig[1].reward = vm.addr(7);
        testConfig[1].asset = vm.addr(8);
        testConfig[1].emissionPerSecond = 200;
        testConfig[1].distributionEnd = CURRENT_DATE;
        testConfig[1].rewardOracle = IEACAggregatorProxy(vm.addr(9));
    }

    function _mockInvalidAssetDecimals() internal {
        uint8 invalidDecimals = 0;
        vm.mockCall(
            testConfig[1].asset,
            abi.encodeWithSelector(IERC20Metadata.decimals.selector),
            abi.encode(invalidDecimals)
        );
    }

    function _mockValidAssetDecimals() internal {
        vm.mockCall(
            testConfig[1].asset,
            abi.encodeWithSelector(IERC20Metadata.decimals.selector),
            abi.encode(PRESET_DECIMALS)
        );
    }

    function _mockDistributionConfigOrdinaryCalls() private {
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, testConfig[0].asset),
            abi.encode(1000)
        );
        vm.mockCall(
            solidStakingViewActions,
            abi.encodeWithSelector(ISolidStakingViewActions.totalStaked.selector, testConfig[1].asset),
            abi.encode(2000)
        );
        vm.mockCall(
            address(testConfig[0].rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(15)
        );
        vm.mockCall(
            address(testConfig[1].rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(15)
        );
        vm.mockCall(
            testConfig[0].asset,
            abi.encodeWithSelector(IERC20Metadata.decimals.selector),
            abi.encode(PRESET_DECIMALS)
        );
    }

    function _makeInvalidOracle() internal returns (IEACAggregatorProxy rewardOracle) {
        rewardOracle = IEACAggregatorProxy(vm.addr(5));

        vm.mockCall(
            address(rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(0)
        );
    }

    function _makeValidOracle() internal returns (IEACAggregatorProxy rewardOracle) {
        rewardOracle = IEACAggregatorProxy(vm.addr(5));

        vm.mockCall(
            address(rewardOracle),
            abi.encodeWithSelector(IEACAggregatorProxy.latestAnswer.selector),
            abi.encode(1)
        );
    }
}
