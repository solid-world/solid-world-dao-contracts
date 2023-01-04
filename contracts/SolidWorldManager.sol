// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "./ForwardContractBatchToken.sol";
import "./CollateralizedBasketToken.sol";
import "./libraries/SolidMath.sol";
import "./libraries/GPv2SafeERC20.sol";
import "./interfaces/manager/IWeeklyCarbonRewardsManager.sol";
import "./interfaces/manager/ISolidWorldManagerErrors.sol";
import "./libraries/DomainDataTypes.sol";
import "./libraries/manager/WeeklyCarbonRewards.sol";
import "./libraries/manager/CarbonDomainRepository.sol";
import "./libraries/manager/CollateralizationManager.sol";
import "./CollateralizedBasketTokenDeployer.sol";
import "./SolidWorldManagerStorage.sol";
import "./interfaces/manager/ICarbonDomainRepository.sol";
import "./interfaces/manager/ICollateralizationManager.sol";
import "./interfaces/manager/IDecollateralizationManager.sol";

contract SolidWorldManager is
    Initializable,
    OwnableUpgradeable,
    IERC1155ReceiverUpgradeable,
    ReentrancyGuardUpgradeable,
    IWeeklyCarbonRewardsManager,
    ICollateralizationManager,
    IDecollateralizationManager,
    ICarbonDomainRepository,
    ISolidWorldManagerErrors,
    SolidWorldManagerStorage
{
    using WeeklyCarbonRewards for SolidWorldManagerStorage.Storage;
    using CarbonDomainRepository for SolidWorldManagerStorage.Storage;
    using CollateralizationManager for SolidWorldManagerStorage.Storage;

    /// @notice Constant used as input for decollateralization simulation for ordering batches with the same category and vintage
    uint public constant DECOLLATERALIZATION_SIMULATION_INPUT = 1000e18;

    event TokensDecollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed tokensOwner
    );
    event CategoryRebalanced(
        uint indexed categoryId,
        uint indexed averageTA,
        uint indexed totalCollateralized
    );
    event FeeReceiverUpdated(address indexed feeReceiver);
    event DecollateralizationFeeUpdated(uint indexed decollateralizationFee);

    modifier validBatch(uint batchId) {
        if (!_storage.batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }
        _;
    }

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
        _setDecollateralizationFee(decollateralizationFee);
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
        uint16 maxDepreciationPerYear,
        uint24 maxDepreciation
    ) external {
        _storage.updateCategory(
            categoryId,
            volumeCoefficient,
            decayPerSecond,
            maxDepreciationPerYear,
            maxDepreciation
        );
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
    /// @inheritdoc IWeeklyCarbonRewardsManager
    function setWeeklyRewardsMinter(address weeklyRewardsMinter) external {
        _storage.setWeeklyRewardsMinter(weeklyRewardsMinter);
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function computeWeeklyCarbonRewards(uint[] calldata categoryIds)
        external
        view
        override
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
    ) external override {
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
    ) external nonReentrant {
        _storage.collateralizeBatch(batchId, amountIn, amountOutMin);
    }

    /// @inheritdoc IDecollateralizationManager
    function decollateralizeTokens(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external {
        _decollateralizeTokens(batchId, amountIn, amountOutMin);

        _rebalanceCategory(_storage.batchCategory[batchId]);
    }

    /// @inheritdoc IDecollateralizationManager
    function bulkDecollateralizeTokens(
        uint[] calldata batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external {
        if (batchIds.length != amountsIn.length || batchIds.length != amountsOutMin.length) {
            revert InvalidInput();
        }

        for (uint i = 1; i < batchIds.length; i++) {
            uint currentBatchCategoryId = _storage.batchCategory[batchIds[i]];
            uint previousBatchCategoryId = _storage.batchCategory[batchIds[i - 1]];

            if (currentBatchCategoryId != previousBatchCategoryId) {
                revert BatchesNotInSameCategory(currentBatchCategoryId, previousBatchCategoryId);
            }
        }

        for (uint i; i < batchIds.length; i++) {
            _decollateralizeTokens(batchIds[i], amountsIn[i], amountsOutMin[i]);
        }

        uint decollateralizedCategoryId = _storage.batchCategory[batchIds[0]];
        _rebalanceCategory(decollateralizedCategoryId);
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
            uint amountOut,
            uint minAmountIn,
            uint minCbtDaoCut
        )
    {
        (amountOut, minAmountIn, minCbtDaoCut) = _simulateDecollateralization(batchId, amountIn);
    }

    /// @inheritdoc IDecollateralizationManager
    function getBatchesDecollateralizationInfo(uint projectId, uint vintage)
        external
        view
        returns (DomainDataTypes.TokenDecollateralizationInfo[] memory result)
    {
        DomainDataTypes.TokenDecollateralizationInfo[]
            memory allInfos = new DomainDataTypes.TokenDecollateralizationInfo[](
                _storage.batchIds.length
            );
        uint infoCount;

        for (uint i; i < _storage.batchIds.length; i++) {
            uint batchId = _storage.batchIds[i];
            if (
                _storage.batches[batchId].vintage != vintage ||
                _storage.batches[batchId].projectId != projectId
            ) {
                continue;
            }

            uint availableCredits = _storage._forwardContractBatch.balanceOf(
                address(this),
                batchId
            );

            (uint amountOut, uint minAmountIn, uint minCbtDaoCut) = _simulateDecollateralization(
                batchId,
                DECOLLATERALIZATION_SIMULATION_INPUT
            );

            allInfos[infoCount] = DomainDataTypes.TokenDecollateralizationInfo(
                batchId,
                availableCredits,
                amountOut,
                minAmountIn,
                minCbtDaoCut
            );
            infoCount = infoCount + 1;
        }

        result = new DomainDataTypes.TokenDecollateralizationInfo[](infoCount);
        for (uint i; i < infoCount; i++) {
            result[i] = allInfos[i];
        }
    }

    // todo #121: add authorization
    /// @inheritdoc ICollateralizationManager
    function setCollateralizationFee(uint16 collateralizationFee) external {
        _storage.setCollateralizationFee(collateralizationFee);
    }

    // todo #121: add authorization
    /// @inheritdoc IDecollateralizationManager
    function setDecollateralizationFee(uint16 decollateralizationFee) external {
        _setDecollateralizationFee(decollateralizationFee);
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

    function _setDecollateralizationFee(uint16 decollateralizationFee) internal {
        _storage.decollateralizationFee = decollateralizationFee;

        emit DecollateralizationFeeUpdated(decollateralizationFee);
    }

    function _setFeeReceiver(address feeReceiver) internal {
        _storage.feeReceiver = feeReceiver;

        emit FeeReceiverUpdated(feeReceiver);
    }

    function _simulateDecollateralization(uint batchId, uint amountIn)
        internal
        view
        validBatch(batchId)
        returns (
            uint amountOut,
            uint minAmountIn,
            uint minCbtDaoCut
        )
    {
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (amountOut, , ) = SolidMath.computeDecollateralizationOutcome(
            _storage.batches[batchId].certificationDate,
            amountIn,
            _storage.batches[batchId].batchTA,
            _storage.decollateralizationFee,
            collateralizedToken.decimals()
        );

        (minAmountIn, minCbtDaoCut) = SolidMath.computeDecollateralizationMinAmountInAndDaoCut(
            _storage.batches[batchId].certificationDate,
            amountOut,
            _storage.batches[batchId].batchTA,
            _storage.decollateralizationFee,
            collateralizedToken.decimals()
        );
    }

    function _rebalanceCategory(uint categoryId) internal {
        uint totalQuantifiedForwardCredits;
        uint totalCollateralizedForwardCredits;

        uint[] storage projects = _storage.categoryProjects[categoryId];
        for (uint i; i < projects.length; i++) {
            uint projectId = projects[i];
            uint[] storage _batches = _storage.projectBatches[projectId];
            for (uint j; j < _batches.length; j++) {
                uint batchId = _batches[j];
                uint collateralizedForwardCredits = _storage._forwardContractBatch.balanceOf(
                    address(this),
                    batchId
                );
                if (collateralizedForwardCredits == 0 || _isBatchCertified(batchId)) {
                    continue;
                }

                totalQuantifiedForwardCredits +=
                    _storage.batches[batchId].batchTA *
                    collateralizedForwardCredits;
                totalCollateralizedForwardCredits += collateralizedForwardCredits;
            }
        }

        if (totalCollateralizedForwardCredits == 0) {
            _storage.categories[categoryId].totalCollateralized = 0;
            emit CategoryRebalanced(categoryId, _storage.categories[categoryId].averageTA, 0);
            return;
        }

        uint latestAverageTA = totalQuantifiedForwardCredits / totalCollateralizedForwardCredits;
        _storage.categories[categoryId].averageTA = uint24(latestAverageTA);
        _storage.categories[categoryId].totalCollateralized = totalCollateralizedForwardCredits;

        emit CategoryRebalanced(categoryId, latestAverageTA, totalCollateralizedForwardCredits);
    }

    /// @dev Decollateralizes `amountIn` of ERC20 tokens and sends `amountOut` ERC1155 tokens with id `batchId` to msg.sender
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend `amountIn` ERC20 tokens
    /// @dev nonReentrant, to avoid possible reentrancy after calling safeTransferFrom
    /// @param batchId id of the batch
    /// @param amountIn ERC20 tokens to decollateralize
    /// @param amountOutMin minimum output amount of ERC1155 tokens for transaction to succeed
    function _decollateralizeTokens(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) internal nonReentrant validBatch(batchId) {
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (uint amountOut, uint cbtDaoCut, uint cbtToBurn) = SolidMath
            .computeDecollateralizationOutcome(
                _storage.batches[batchId].certificationDate,
                amountIn,
                _storage.batches[batchId].batchTA,
                _storage.decollateralizationFee,
                collateralizedToken.decimals()
            );

        if (amountOut <= 0) {
            revert AmountOutTooLow(amountOut);
        }

        if (amountOut < amountOutMin) {
            revert AmountOutLessThanMinimum(amountOut, amountOutMin);
        }

        collateralizedToken.burnFrom(msg.sender, cbtToBurn);
        GPv2SafeERC20.safeTransferFrom(
            collateralizedToken,
            msg.sender,
            _storage.feeReceiver,
            cbtDaoCut
        );

        _storage._forwardContractBatch.safeTransferFrom(
            address(this),
            msg.sender,
            batchId,
            amountOut,
            ""
        );

        emit TokensDecollateralized(batchId, amountIn, amountOut, msg.sender);
    }

    function _getCollateralizedTokenForBatchId(uint batchId)
        internal
        view
        returns (CollateralizedBasketToken)
    {
        uint projectId = _storage.batches[batchId].projectId;
        uint categoryId = _storage.projectCategory[projectId];

        return _storage.categoryToken[categoryId];
    }

    function _isBatchCertified(uint batchId) internal view returns (bool) {
        return _storage.batches[batchId].certificationDate <= block.timestamp;
    }
}
