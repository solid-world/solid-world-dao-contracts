// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "./Pausable.sol";
import "./ForwardContractBatchToken.sol";
import "./CollateralizedBasketTokenDeployer.sol";
import "./SolidWorldManagerStorage.sol";
import "./interfaces/manager/IWeeklyCarbonRewardsManager.sol";
import "./interfaces/manager/ICarbonDomainRepository.sol";
import "./interfaces/manager/ICollateralizationManager.sol";
import "./interfaces/manager/IDecollateralizationManager.sol";
import "./libraries/DomainDataTypes.sol";
import "./libraries/manager/WeeklyCarbonRewards.sol";
import "./libraries/manager/CarbonDomainRepository.sol";
import "./libraries/manager/CollateralizationManager.sol";
import "./libraries/manager/DecollateralizationManager.sol";

contract SolidWorldManager is
    Initializable,
    OwnableUpgradeable,
    IERC1155ReceiverUpgradeable,
    ReentrancyGuardUpgradeable,
    Pausable,
    IWeeklyCarbonRewardsManager,
    ICollateralizationManager,
    IDecollateralizationManager,
    ICarbonDomainRepository,
    SolidWorldManagerStorage
{
    using WeeklyCarbonRewards for SolidWorldManagerStorage.Storage;
    using CarbonDomainRepository for SolidWorldManagerStorage.Storage;
    using CollateralizationManager for SolidWorldManagerStorage.Storage;
    using DecollateralizationManager for SolidWorldManagerStorage.Storage;

    event FeeReceiverUpdated(address indexed feeReceiver);

    function initialize(
        CollateralizedBasketTokenDeployer collateralizedBasketTokenDeployer,
        ForwardContractBatchToken forwardContractBatch,
        uint16 collateralizationFee,
        uint16 decollateralizationFee,
        uint16 rewardsFee,
        address feeReceiver,
        address weeklyRewardsMinter
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        _storage._collateralizedBasketTokenDeployer = collateralizedBasketTokenDeployer;
        _storage._forwardContractBatch = forwardContractBatch;

        _storage.setCollateralizationFee(collateralizationFee);
        _storage.setDecollateralizationFee(decollateralizationFee);
        _storage.setRewardsFee(rewardsFee);
        _setFeeReceiver(feeReceiver);
        _storage.setWeeklyRewardsMinter(weeklyRewardsMinter);
    }

    // todo #121: add authorization
    /// @inheritdoc ICarbonDomainRepository
    function addCategory(
        uint categoryId,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint24 initialTA
    ) external {
        _storage.addCategory(categoryId, tokenName, tokenSymbol, initialTA);
    }

    // todo #121: add authorization
    /// @inheritdoc ICarbonDomainRepository
    function updateCategory(
        uint categoryId,
        uint volumeCoefficient,
        uint40 decayPerSecond,
        uint16 maxDepreciation
    ) external {
        _storage.updateCategory(categoryId, volumeCoefficient, decayPerSecond, maxDepreciation);
    }

    // todo #121: add authorization
    /// @inheritdoc ICarbonDomainRepository
    function addProject(uint categoryId, uint projectId) external {
        _storage.addProject(categoryId, projectId);
    }

    // todo #121: add authorization
    /// @inheritdoc ICarbonDomainRepository
    function addBatch(DomainDataTypes.Batch calldata batch, uint mintableAmount) external {
        _storage.addBatch(batch, mintableAmount);
    }

    // todo #121: add authorization
    /// @inheritdoc ICarbonDomainRepository
    function setBatchAccumulating(uint batchId, bool isAccumulating) external {
        _storage.setBatchAccumulating(batchId, isAccumulating);
    }

    // todo #121: add authorization
    /// @inheritdoc ICarbonDomainRepository
    function setBatchCertificationDate(uint batchId, uint32 certificationDate) external {
        _storage.setBatchCertificationDate(batchId, certificationDate);
    }

    // todo #121: add authorization
    /// @inheritdoc IWeeklyCarbonRewardsManager
    function setWeeklyRewardsMinter(address weeklyRewardsMinter) external {
        _storage.setWeeklyRewardsMinter(weeklyRewardsMinter);
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function computeWeeklyCarbonRewards(uint[] calldata categoryIds)
        external
        view
        returns (
            address[] memory,
            uint[] memory,
            uint[] memory
        )
    {
        return _storage.computeWeeklyCarbonRewards(categoryIds);
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function mintWeeklyCarbonRewards(
        uint[] calldata categoryIds,
        address[] calldata carbonRewards,
        uint[] calldata rewardAmounts,
        uint[] calldata rewardFees,
        address rewardsVault
    ) external whenNotPaused {
        _storage.mintWeeklyCarbonRewards(
            categoryIds,
            carbonRewards,
            rewardAmounts,
            rewardFees,
            rewardsVault
        );
    }

    /// @inheritdoc ICollateralizationManager
    function collateralizeBatch(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external nonReentrant whenNotPaused {
        _storage.collateralizeBatch(batchId, amountIn, amountOutMin);
    }

    /// @inheritdoc IDecollateralizationManager
    function decollateralizeTokens(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external nonReentrant whenNotPaused {
        _storage.decollateralizeTokens(batchId, amountIn, amountOutMin);
    }

    /// @inheritdoc IDecollateralizationManager
    function bulkDecollateralizeTokens(
        uint[] calldata batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external nonReentrant whenNotPaused {
        _storage.bulkDecollateralizeTokens(batchIds, amountsIn, amountsOutMin);
    }

    /// @inheritdoc ICollateralizationManager
    function simulateBatchCollateralization(uint batchId, uint amountIn)
        external
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return _storage.simulateBatchCollateralization(batchId, amountIn);
    }

    /// @inheritdoc IDecollateralizationManager
    function simulateDecollateralization(uint batchId, uint amountIn)
        external
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return _storage.simulateDecollateralization(batchId, amountIn);
    }

    /// @inheritdoc IDecollateralizationManager
    function getBatchesDecollateralizationInfo(uint projectId, uint vintage)
        external
        view
        returns (DomainDataTypes.TokenDecollateralizationInfo[] memory)
    {
        return _storage.getBatchesDecollateralizationInfo(projectId, vintage);
    }

    // todo #121: add authorization
    /// @inheritdoc Pausable
    function pause() public override {
        super.pause();
    }

    // todo #121: add authorization
    /// @inheritdoc Pausable
    function unpause() public override {
        super.unpause();
    }

    // todo #121: add authorization
    /// @inheritdoc ICollateralizationManager
    function setCollateralizationFee(uint16 collateralizationFee) external {
        _storage.setCollateralizationFee(collateralizationFee);
    }

    // todo #121: add authorization
    /// @inheritdoc IDecollateralizationManager
    function setDecollateralizationFee(uint16 decollateralizationFee) external {
        _storage.setDecollateralizationFee(decollateralizationFee);
    }

    // todo #121: add authorization
    /// @inheritdoc IWeeklyCarbonRewardsManager
    function setRewardsFee(uint16 rewardsFee) external {
        _storage.setRewardsFee(rewardsFee);
    }

    // todo #121: add authorization
    function setFeeReceiver(address feeReceiver) external {
        _setFeeReceiver(feeReceiver);
    }

    function onERC1155Received(
        address,
        address,
        uint,
        uint,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint[] memory,
        uint[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // ERC165 && ERC1155TokenReceiver support
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x4e2312e0;
    }

    function _setFeeReceiver(address feeReceiver) internal {
        _storage.feeReceiver = feeReceiver;

        emit FeeReceiverUpdated(feeReceiver);
    }
}
