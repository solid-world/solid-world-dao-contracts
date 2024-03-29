// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

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
import "./interfaces/manager/IRegulatoryComplianceManager.sol";
import "./libraries/DomainDataTypes.sol";
import "./libraries/manager/WeeklyCarbonRewards.sol";
import "./libraries/manager/CarbonDomainRepository.sol";
import "./libraries/manager/CollateralizationManager.sol";
import "./libraries/manager/DecollateralizationManager.sol";
import "./libraries/manager/RegulatoryComplianceManager.sol";

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
    IRegulatoryComplianceManager,
    SolidWorldManagerStorage
{
    using WeeklyCarbonRewards for SolidWorldManagerStorage.Storage;
    using CarbonDomainRepository for SolidWorldManagerStorage.Storage;
    using CollateralizationManager for SolidWorldManagerStorage.Storage;
    using DecollateralizationManager for SolidWorldManagerStorage.Storage;
    using RegulatoryComplianceManager for SolidWorldManagerStorage.Storage;

    event FeeReceiverUpdated(address indexed feeReceiver);
    error NotTimelockController(address caller);

    modifier onlyTimelockController() {
        if (msg.sender != _storage.timelockController) {
            revert NotTimelockController(msg.sender);
        }
        _;
    }

    function initialize(
        CollateralizedBasketTokenDeployer collateralizedBasketTokenDeployer,
        ForwardContractBatchToken forwardContractBatch,
        uint16 collateralizationFee,
        uint16 decollateralizationFee,
        uint16 boostedDecollateralizationFee,
        uint16 rewardsFee,
        address feeReceiver,
        address weeklyRewardsMinter,
        address owner,
        address timelockController
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        transferOwnership(owner);

        _storage._collateralizedBasketTokenDeployer = collateralizedBasketTokenDeployer;
        _storage._forwardContractBatch = forwardContractBatch;

        _storage.setCollateralizationFee(collateralizationFee);
        _storage.setDecollateralizationFee(decollateralizationFee);
        _storage.setBoostedDecollateralizationFee(boostedDecollateralizationFee);
        _storage.setRewardsFee(rewardsFee);
        _setFeeReceiver(feeReceiver);
        _setTimelockController(timelockController);
        _storage.setWeeklyRewardsMinter(weeklyRewardsMinter);
    }

    /// @inheritdoc ICarbonDomainRepository
    function addCategory(
        uint categoryId,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint24 initialTA
    ) external onlyOwner {
        _storage.addCategory(categoryId, tokenName, tokenSymbol, initialTA);
    }

    /// @inheritdoc ICarbonDomainRepository
    function updateCategory(
        uint categoryId,
        uint volumeCoefficient,
        uint40 decayPerSecond,
        uint16 maxDepreciation
    ) external onlyTimelockController {
        _storage.updateCategory(categoryId, volumeCoefficient, decayPerSecond, maxDepreciation);
    }

    /// @inheritdoc ICarbonDomainRepository
    function addProject(uint categoryId, uint projectId) external onlyOwner {
        _storage.addProject(categoryId, projectId);
    }

    /// @inheritdoc ICarbonDomainRepository
    function addBatch(DomainDataTypes.Batch calldata batch, uint mintableAmount)
        external
        nonReentrant
        onlyOwner
    {
        _storage.addBatch(batch, mintableAmount);
    }

    /// @inheritdoc ICarbonDomainRepository
    function setBatchAccumulating(uint batchId, bool isAccumulating) external onlyOwner {
        _storage.setBatchAccumulating(batchId, isAccumulating);
    }

    /// @inheritdoc ICarbonDomainRepository
    function setBatchCertificationDate(uint batchId, uint32 certificationDate) external onlyOwner {
        _storage.setBatchCertificationDate(batchId, certificationDate);
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function setWeeklyRewardsMinter(address weeklyRewardsMinter) external onlyOwner {
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
        _storage.mintWeeklyCarbonRewards(categoryIds, carbonRewards, rewardAmounts, rewardFees, rewardsVault);
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
    function simulateReverseDecollateralization(uint batchId, uint forwardCreditsAmount)
        external
        view
        returns (uint minCbt, uint minCbtDaoCut)
    {
        return _storage.simulateReverseDecollateralization(batchId, forwardCreditsAmount);
    }

    /// @inheritdoc IDecollateralizationManager
    function getBatchesDecollateralizationInfo(uint projectId, uint vintage)
        external
        view
        returns (DomainDataTypes.TokenDecollateralizationInfo[] memory)
    {
        return _storage.getBatchesDecollateralizationInfo(projectId, vintage);
    }

    /// @inheritdoc IDecollateralizationManager
    function getBatchesDecollateralizationInfoWithCertificationDate(uint projectId, uint certificationDate)
        external
        view
        returns (DomainDataTypes.TokenDecollateralizationInfo[] memory)
    {
        return _storage.getBatchesDecollateralizationInfoWithCertificationDate(projectId, certificationDate);
    }

    /// @inheritdoc ICollateralizationManager
    function getReactiveTA(uint categoryId, uint forwardCreditsAmount) external view returns (uint) {
        return _storage.getReactiveTA(categoryId, forwardCreditsAmount);
    }

    /// @inheritdoc Pausable
    function pause() public override onlyOwner {
        super.pause();
    }

    /// @inheritdoc Pausable
    function unpause() public override onlyOwner {
        super.unpause();
    }

    /// @inheritdoc ICollateralizationManager
    function setCollateralizationFee(uint16 collateralizationFee) external onlyTimelockController {
        _storage.setCollateralizationFee(collateralizationFee);
    }

    /// @inheritdoc IDecollateralizationManager
    function setDecollateralizationFee(uint16 decollateralizationFee) external onlyTimelockController {
        _storage.setDecollateralizationFee(decollateralizationFee);
    }

    /// @inheritdoc IDecollateralizationManager
    function setBoostedDecollateralizationFee(uint16 boostedDecollateralizationFee)
        external
        onlyTimelockController
    {
        _storage.setBoostedDecollateralizationFee(boostedDecollateralizationFee);
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function setRewardsFee(uint16 rewardsFee) external onlyTimelockController {
        _storage.setRewardsFee(rewardsFee);
    }

    function setFeeReceiver(address feeReceiver) external onlyOwner {
        _setFeeReceiver(feeReceiver);
    }

    function setCategoryKYCRequired(uint categoryId, bool isKYCRequired) external onlyTimelockController {
        _storage.setCategoryKYCRequired(categoryId, isKYCRequired);
    }

    function setBatchKYCRequired(uint batchId, bool isKYCRequired) external onlyTimelockController {
        _storage.setBatchKYCRequired(batchId, isKYCRequired);
    }

    function setCategoryVerificationRegistry(uint categoryId, address verificationRegistry)
        external
        onlyOwner
    {
        _storage.setCategoryVerificationRegistry(categoryId, verificationRegistry);
    }

    function setForwardsVerificationRegistry(address verificationRegistry) external onlyOwner {
        _storage.setForwardsVerificationRegistry(verificationRegistry);
    }

    function setCollateralizedBasketTokenDeployerVerificationRegistry(address verificationRegistry)
        external
        onlyOwner
    {
        _storage.setCollateralizedBasketTokenDeployerVerificationRegistry(verificationRegistry);
    }

    /// @dev accept transfers from this contract only
    function onERC1155Received(
        address operator,
        address,
        uint,
        uint,
        bytes memory
    ) public virtual returns (bytes4) {
        if (operator != address(this)) {
            return bytes4(0);
        }

        return this.onERC1155Received.selector;
    }

    /// @dev accept transfers from this contract only
    function onERC1155BatchReceived(
        address operator,
        address,
        uint[] memory,
        uint[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        if (operator != address(this)) {
            return bytes4(0);
        }

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

    function _setTimelockController(address timelockController) internal {
        _storage.timelockController = timelockController;
    }
}
