// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "./ForwardContractBatchToken.sol";
import "./CollateralizedBasketToken.sol";
import "./libraries/SolidMath.sol";
import "./libraries/ReactiveTimeAppreciationMath.sol";
import "./libraries/GPv2SafeERC20.sol";
import "./interfaces/manager/IWeeklyCarbonRewardsManager.sol";
import "./interfaces/manager/ISolidWorldManagerErrors.sol";
import "./libraries/DomainDataTypes.sol";
import "./libraries/manager/WeeklyCarbonRewards.sol";
import "./CollateralizedBasketTokenDeployer.sol";
import "./SolidWorldManagerStorage.sol";
import "./interfaces/manager/ICarbonDomainRepository.sol";

contract SolidWorldManager is
    Initializable,
    OwnableUpgradeable,
    IERC1155ReceiverUpgradeable,
    ReentrancyGuardUpgradeable,
    IWeeklyCarbonRewardsManager,
    ICarbonDomainRepository,
    ISolidWorldManagerErrors,
    SolidWorldManagerStorage
{
    using WeeklyCarbonRewards for SolidWorldManagerStorage.Storage;

    /// @notice Constant used as input for decollateralization simulation for ordering batches with the same category and vintage
    uint public constant DECOLLATERALIZATION_SIMULATION_INPUT = 1000e18;

    event BatchCollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed batchSupplier
    );
    event TokensDecollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed tokensOwner
    );
    event CategoryCreated(uint indexed categoryId);
    event CategoryUpdated(
        uint indexed categoryId,
        uint indexed volumeCoefficient,
        uint indexed decayPerSecond,
        uint maxDepreciation
    );
    event CategoryRebalanced(
        uint indexed categoryId,
        uint indexed averageTA,
        uint indexed totalCollateralized
    );
    event ProjectCreated(uint indexed projectId);
    event BatchCreated(uint indexed batchId);
    event FeeReceiverUpdated(address indexed feeReceiver);
    event CollateralizationFeeUpdated(uint indexed collateralizationFee);
    event DecollateralizationFeeUpdated(uint indexed decollateralizationFee);

    modifier validBatch(uint batchId) {
        if (!_storage.batchCreated[batchId]) {
            revert InvalidBatchId(batchId);
        }
        _;
    }

    modifier batchUnderway(uint batchId) {
        if (_isBatchCertified(batchId)) {
            revert BatchCertified(batchId);
        }
        _;
    }

    function initialize(
        CollateralizedBasketTokenDeployer collateralizedBasketTokenDeployer,
        ForwardContractBatchToken forwardContractBatch,
        uint16 _collateralizationFee,
        uint16 _decollateralizationFee,
        uint16 _rewardsFee,
        address _feeReceiver,
        address _weeklyRewardsMinter
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        _storage._collateralizedBasketTokenDeployer = collateralizedBasketTokenDeployer;
        _storage._forwardContractBatch = forwardContractBatch;

        _setCollateralizationFee(_collateralizationFee);
        _setDecollateralizationFee(_decollateralizationFee);
        _storage.setRewardsFee(_rewardsFee);
        _setFeeReceiver(_feeReceiver);
        _storage.setWeeklyRewardsMinter(_weeklyRewardsMinter);
    }

    // todo #121: add authorization
    /// @inheritdoc ICarbonDomainRepository
    function addCategory(
        uint categoryId,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint24 initialTA
    ) external {
        if (_storage.categoryCreated[categoryId]) {
            revert CategoryAlreadyExists(categoryId);
        }

        _storage.categoryCreated[categoryId] = true;
        _storage.categoryToken[categoryId] = _storage._collateralizedBasketTokenDeployer.deploy(
            tokenName,
            tokenSymbol
        );

        _storage.categories[categoryId].averageTA = initialTA;

        emit CategoryCreated(categoryId);
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
        if (!_storage.categoryCreated[categoryId]) {
            revert InvalidCategoryId(categoryId);
        }

        if (volumeCoefficient == 0 || decayPerSecond == 0) {
            revert InvalidInput();
        }

        DomainDataTypes.Category storage category = _storage.categories[categoryId];
        category.lastCollateralizationMomentum = ReactiveTimeAppreciationMath.inferMomentum(
            category,
            volumeCoefficient,
            maxDepreciationPerYear
        );
        category.volumeCoefficient = volumeCoefficient;
        category.decayPerSecond = decayPerSecond;
        category.maxDepreciationPerYear = maxDepreciationPerYear;
        category.maxDepreciation = maxDepreciation;
        category.lastCollateralizationTimestamp = uint32(block.timestamp);

        emit CategoryUpdated(categoryId, volumeCoefficient, decayPerSecond, maxDepreciation);
    }

    // todo #121: add authorization
    /// @inheritdoc ICarbonDomainRepository
    function addProject(uint categoryId, uint projectId) external {
        if (!_storage.categoryCreated[categoryId]) {
            revert InvalidCategoryId(categoryId);
        }

        if (_storage.projectCreated[projectId]) {
            revert ProjectAlreadyExists(projectId);
        }

        _storage.categoryProjects[categoryId].push(projectId);
        _storage.projectCategory[projectId] = categoryId;
        _storage.projectCreated[projectId] = true;

        emit ProjectCreated(projectId);
    }

    // todo #121: add authorization
    /// @inheritdoc ICarbonDomainRepository
    function addBatch(DomainDataTypes.Batch calldata batch, uint mintableAmount) external {
        if (!_storage.projectCreated[batch.projectId]) {
            revert InvalidProjectId(batch.projectId);
        }

        if (_storage.batchCreated[batch.id]) {
            revert BatchAlreadyExists(batch.id);
        }

        if (batch.supplier == address(0)) {
            revert InvalidBatchSupplier();
        }

        if (batch.certificationDate <= block.timestamp) {
            revert BatchCertificationDateInThePast(batch.certificationDate);
        }

        _storage.batchCreated[batch.id] = true;
        _storage.batches[batch.id] = batch;
        _storage.batchIds.push(batch.id);
        _storage.projectBatches[batch.projectId].push(batch.id);
        _storage.batchCategory[batch.id] = _storage.projectCategory[batch.projectId];
        _storage._forwardContractBatch.mint(batch.supplier, batch.id, mintableAmount, "");

        emit BatchCreated(batch.id);
    }

    // todo #121: add authorization
    /// @inheritdoc IWeeklyCarbonRewardsManager
    function setWeeklyRewardsMinter(address _weeklyRewardsMinter) external {
        _storage.setWeeklyRewardsMinter(_weeklyRewardsMinter);
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function computeWeeklyCarbonRewards(uint[] calldata _categoryIds)
        external
        view
        override
        returns (
            address[] memory carbonRewards,
            uint[] memory rewardAmounts,
            uint[] memory rewardFees
        )
    {
        (carbonRewards, rewardAmounts, rewardFees) = _storage.computeWeeklyCarbonRewards(
            _categoryIds
        );
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function mintWeeklyCarbonRewards(
        uint[] calldata _categoryIds,
        address[] calldata carbonRewards,
        uint[] calldata rewardAmounts,
        uint[] calldata rewardFees,
        address rewardsVault
    ) external override {
        _storage.mintWeeklyCarbonRewards(
            _categoryIds,
            carbonRewards,
            rewardAmounts,
            rewardFees,
            rewardsVault
        );
    }

    /// @dev Collateralizes `amountIn` of ERC1155 tokens with id `batchId` for msg.sender
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend its ERC1155 tokens with id `batchId`
    /// @dev nonReentrant, to avoid possible reentrancy after calling safeTransferFrom
    /// @param batchId id of the batch
    /// @param amountIn ERC1155 tokens to collateralize
    /// @param amountOutMin minimum output amount of ERC20 tokens for transaction to succeed
    function collateralizeBatch(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external nonReentrant validBatch(batchId) batchUnderway(batchId) {
        if (amountIn == 0) {
            revert InvalidInput();
        }

        (uint decayingMomentum, uint reactiveTA) = ReactiveTimeAppreciationMath.computeReactiveTA(
            _storage.categories[_storage.batchCategory[batchId]],
            amountIn
        );

        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (uint cbtUserCut, uint cbtDaoCut, ) = SolidMath.computeCollateralizationOutcome(
            _storage.batches[batchId].certificationDate,
            amountIn,
            reactiveTA,
            _storage.collateralizationFee,
            collateralizedToken.decimals()
        );

        if (cbtUserCut < amountOutMin) {
            revert AmountOutLessThanMinimum(cbtUserCut, amountOutMin);
        }

        _updateBatchTA(
            batchId,
            reactiveTA,
            amountIn,
            cbtUserCut + cbtDaoCut,
            collateralizedToken.decimals()
        );
        _rebalanceCategory(_storage.batchCategory[batchId], reactiveTA, amountIn, decayingMomentum);

        collateralizedToken.mint(msg.sender, cbtUserCut);
        collateralizedToken.mint(_storage.feeReceiver, cbtDaoCut);

        _storage._forwardContractBatch.safeTransferFrom(
            msg.sender,
            address(this),
            batchId,
            amountIn,
            ""
        );

        emit BatchCollateralized(batchId, amountIn, cbtUserCut, msg.sender);
    }

    /// @dev Decollateralizes `amountIn` of ERC20 tokens and sends `amountOut` ERC1155 tokens with id `batchId` to msg.sender
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend `amountIn` ERC20 tokens
    /// @dev nonReentrant (_decollateralizeTokens), to avoid possible reentrancy after calling safeTransferFrom
    /// @dev will trigger a rebalance of the Category
    /// @param batchId id of the batch
    /// @param amountIn ERC20 tokens to decollateralize
    /// @param amountOutMin minimum output amount of ERC1155 tokens for transaction to succeed
    function decollateralizeTokens(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external {
        _decollateralizeTokens(batchId, amountIn, amountOutMin);

        _rebalanceCategory(_storage.batchCategory[batchId]);
    }

    /// @dev Bulk-decollateralizes ERC20 tokens into multiple ERC1155 tokens with specified amounts
    /// @dev prior to calling, msg.sender must approve SolidWorldManager to spend `sum(amountsIn)` ERC20 tokens
    /// @dev nonReentrant (_decollateralizeTokens), to avoid possible reentrancy after calling safeTransferFrom
    /// @dev _batchIds must belong to the same Category
    /// @dev will trigger a rebalance of the Category
    /// @param _batchIds ids of the batches
    /// @param amountsIn ERC20 tokens to decollateralize
    /// @param amountsOutMin minimum output amounts of ERC1155 tokens for transaction to succeed
    function bulkDecollateralizeTokens(
        uint[] calldata _batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external {
        if (_batchIds.length != amountsIn.length || _batchIds.length != amountsOutMin.length) {
            revert InvalidInput();
        }

        for (uint i = 1; i < _batchIds.length; i++) {
            uint currentBatchCategoryId = _storage.batchCategory[_batchIds[i]];
            uint previousBatchCategoryId = _storage.batchCategory[_batchIds[i - 1]];

            if (currentBatchCategoryId != previousBatchCategoryId) {
                revert BatchesNotInSameCategory(currentBatchCategoryId, previousBatchCategoryId);
            }
        }

        for (uint i; i < _batchIds.length; i++) {
            _decollateralizeTokens(_batchIds[i], amountsIn[i], amountsOutMin[i]);
        }

        uint decollateralizedCategoryId = _storage.batchCategory[_batchIds[0]];
        _rebalanceCategory(decollateralizedCategoryId);
    }

    /// @dev Simulates collateralization of `amountIn` ERC1155 tokens with id `batchId` for msg.sender
    /// @param batchId id of the batch
    /// @param amountIn ERC1155 tokens to collateralize
    /// @return cbtUserCut ERC20 tokens to be received by msg.sender
    /// @return cbtDaoCut ERC20 tokens to be received by feeReceiver
    /// @return cbtForfeited ERC20 tokens forfeited for collateralizing the ERC1155 tokens
    function simulateBatchCollateralization(uint batchId, uint amountIn)
        external
        view
        validBatch(batchId)
        batchUnderway(batchId)
        returns (
            uint cbtUserCut,
            uint cbtDaoCut,
            uint cbtForfeited
        )
    {
        if (amountIn == 0) {
            revert InvalidInput();
        }

        DomainDataTypes.Category storage category = _storage.categories[
            _storage.batchCategory[batchId]
        ];
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (, uint reactiveTA) = ReactiveTimeAppreciationMath.computeReactiveTA(category, amountIn);

        (cbtUserCut, cbtDaoCut, cbtForfeited) = SolidMath.computeCollateralizationOutcome(
            _storage.batches[batchId].certificationDate,
            amountIn,
            reactiveTA,
            _storage.collateralizationFee,
            collateralizedToken.decimals()
        );
    }

    /// @dev Simulates decollateralization of `amountIn` ERC20 tokens for ERC1155 tokens with id `batchId`
    /// @param batchId id of the batch
    /// @param amountIn ERC20 tokens to decollateralize
    /// @return amountOut ERC1155 tokens to be received by msg.sender
    /// @return minAmountIn minimum amount of ERC20 tokens to decollateralize `amountOut` ERC1155 tokens with id `batchId`
    /// @return minCbtDaoCut ERC20 tokens to be received by feeReceiver for decollateralizing minAmountIn ERC20 tokens
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

    /// @dev Computes relevant info for the decollateralization process involving batches
    /// that match the specified `projectId` and `vintage`
    /// @param projectId id of the project the batch belongs to
    /// @param vintage vintage of the batch
    /// @return result array of relevant info about matching batches
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
    function setCollateralizationFee(uint16 _collateralizationFee) external {
        _setCollateralizationFee(_collateralizationFee);
    }

    // todo #121: add authorization
    function setDecollateralizationFee(uint16 _decollateralizationFee) external {
        _setDecollateralizationFee(_decollateralizationFee);
    }

    // todo #121: add authorization
    /// @inheritdoc IWeeklyCarbonRewardsManager
    function setRewardsFee(uint16 _rewardsFee) external {
        _storage.setRewardsFee(_rewardsFee);
    }

    // todo #121: add authorization
    function setFeeReceiver(address _feeReceiver) external {
        _setFeeReceiver(_feeReceiver);
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

    function _setCollateralizationFee(uint16 _collateralizationFee) internal {
        _storage.collateralizationFee = _collateralizationFee;

        emit CollateralizationFeeUpdated(_collateralizationFee);
    }

    function _setDecollateralizationFee(uint16 _decollateralizationFee) internal {
        _storage.decollateralizationFee = _decollateralizationFee;

        emit DecollateralizationFeeUpdated(_decollateralizationFee);
    }

    function _setFeeReceiver(address _feeReceiver) internal {
        _storage.feeReceiver = _feeReceiver;

        emit FeeReceiverUpdated(_feeReceiver);
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

    function _updateBatchTA(
        uint batchId,
        uint reactiveTA,
        uint toBeCollateralizedForwardCredits,
        uint toBeMintedCBT,
        uint cbtDecimals
    ) internal {
        DomainDataTypes.Batch storage batch = _storage.batches[batchId];
        uint collateralizedForwardCredits = _storage._forwardContractBatch.balanceOf(
            address(this),
            batch.id
        );
        if (collateralizedForwardCredits == 0) {
            batch.batchTA = uint24(reactiveTA);
            return;
        }

        (uint circulatingCBT, , ) = SolidMath.computeCollateralizationOutcome(
            batch.certificationDate,
            collateralizedForwardCredits,
            batch.batchTA,
            0, // compute without fee
            cbtDecimals
        );

        batch.batchTA = uint24(
            ReactiveTimeAppreciationMath.inferBatchTA(
                circulatingCBT + toBeMintedCBT,
                collateralizedForwardCredits + toBeCollateralizedForwardCredits,
                batch.certificationDate,
                cbtDecimals
            )
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

    function _rebalanceCategory(
        uint categoryId,
        uint reactiveTA,
        uint currentCollateralizedAmount,
        uint decayingMomentum
    ) internal {
        DomainDataTypes.Category storage category = _storage.categories[categoryId];

        uint latestAverageTA = (category.averageTA *
            category.totalCollateralized +
            reactiveTA *
            currentCollateralizedAmount) /
            (category.totalCollateralized + currentCollateralizedAmount);

        category.averageTA = uint24(latestAverageTA);
        category.totalCollateralized += currentCollateralizedAmount;
        category.lastCollateralizationMomentum = decayingMomentum + currentCollateralizedAmount;
        category.lastCollateralizationTimestamp = uint32(block.timestamp);

        emit CategoryRebalanced(categoryId, latestAverageTA, category.totalCollateralized);
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
