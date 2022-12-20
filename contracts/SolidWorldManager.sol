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

contract SolidWorldManager is
    Initializable,
    OwnableUpgradeable,
    IERC1155ReceiverUpgradeable,
    ReentrancyGuardUpgradeable,
    IWeeklyCarbonRewardsManager,
    ISolidWorldManagerErrors
{
    /// @notice Constant used as input for decollateralization simulation for ordering batches with the same category and vintage
    uint public constant DECOLLATERALIZATION_SIMULATION_INPUT = 1000e18;

    /// @notice Mapping is used for checking if Category ID is already added
    /// @dev CategoryId => isAdded
    mapping(uint => bool) public categoryIds;

    /// @notice Stores the state of categories
    /// @dev CategoryId => DomainDataTypes.Category
    mapping(uint => DomainDataTypes.Category) public categories;

    /// @notice Property is used for checking if Project ID is already added
    /// @dev ProjectId => isAdded
    mapping(uint => bool) public projectIds;

    /// @notice Property is used for checking if Batch ID is already added
    /// @dev BatchId => isAdded
    mapping(uint => bool) public batchCreated;

    /// @notice Stores all batch ids ever created
    uint[] public batchIds;

    /// @notice Property stores info about a batch
    /// @dev BatchId => DomainDataTypes.Batch
    mapping(uint => DomainDataTypes.Batch) public batches;

    /// @notice Mapping determines a respective CollateralizedBasketToken (ERC-20) of a category
    /// @dev CategoryId => CollateralizedBasketToken address (ERC-20)
    mapping(uint => CollateralizedBasketToken) public categoryToken;

    /// @notice Mapping determines what projects a category has
    /// @dev CategoryId => ProjectId[]
    mapping(uint => uint[]) public categoryProjects;

    /// @notice Mapping determines what category a project belongs to
    /// @dev ProjectId => CategoryId
    mapping(uint => uint) public projectCategory;

    /// @notice Mapping determines what category a batch belongs to
    /// @dev BatchId => CategoryId
    mapping(uint => uint) public batchCategory;

    /// @notice Mapping determines what batches a project has
    /// @dev ProjectId => BatchId[]
    mapping(uint => uint[]) public projectBatches;

    /// @notice Contract that operates forward contract batch tokens (ERC-1155). Allows this contract to mint tokens.
    ForwardContractBatchToken public forwardContractBatch;

    /// @notice The account where all protocol fees are captured.
    address public feeReceiver;

    /// @notice The only account that is allowed to mint weekly carbon rewards
    address public weeklyRewardsMinter;

    /// @notice Fee charged by DAO when collateralizing forward contract batch tokens.
    uint16 public collateralizationFee;

    /// @notice Fee charged by DAO when decollateralizing collateralized basket tokens.
    uint16 public decollateralizationFee;

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

    modifier validBatch(uint batchId) {
        if (!batchCreated[batchId]) {
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
        ForwardContractBatchToken _forwardContractBatch,
        uint16 _collateralizationFee,
        uint16 _decollateralizationFee,
        address _feeReceiver,
        address _weeklyRewardsMinter
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        forwardContractBatch = _forwardContractBatch;
        collateralizationFee = _collateralizationFee;
        decollateralizationFee = _decollateralizationFee;
        feeReceiver = _feeReceiver;
        weeklyRewardsMinter = _weeklyRewardsMinter;
    }

    // todo #121: add authorization
    function addCategory(
        uint categoryId,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint24 initialTA
    ) external {
        if (categoryIds[categoryId]) {
            revert CategoryAlreadyExists(categoryId);
        }

        categoryIds[categoryId] = true;
        categoryToken[categoryId] = new CollateralizedBasketToken(tokenName, tokenSymbol);

        categories[categoryId].averageTA = initialTA;

        emit CategoryCreated(categoryId);
    }

    // todo #121: add authorization
    function updateCategory(
        uint categoryId,
        uint volumeCoefficient,
        uint40 decayPerSecond,
        uint24 maxDepreciation
    ) external {
        if (!categoryIds[categoryId]) {
            revert InvalidCategoryId(categoryId);
        }

        categories[categoryId].volumeCoefficient = volumeCoefficient;
        categories[categoryId].decayPerSecond = decayPerSecond;
        categories[categoryId].maxDepreciation = maxDepreciation;

        // todo #204: implement logic for updating the other fields of the category based on the new values

        emit CategoryUpdated(categoryId, volumeCoefficient, decayPerSecond, maxDepreciation);
    }

    // todo #121: add authorization
    function addProject(uint categoryId, uint projectId) external {
        if (!categoryIds[categoryId]) {
            revert InvalidCategoryId(categoryId);
        }

        if (projectIds[projectId]) {
            revert ProjectAlreadyExists(projectId);
        }

        categoryProjects[categoryId].push(projectId);
        projectCategory[projectId] = categoryId;
        projectIds[projectId] = true;

        emit ProjectCreated(projectId);
    }

    // todo #121: add authorization
    function addBatch(DomainDataTypes.Batch calldata batch, uint mintableAmount) external {
        if (!projectIds[batch.projectId]) {
            revert InvalidProjectId(batch.projectId);
        }

        if (batchCreated[batch.id]) {
            revert BatchAlreadyExists(batch.id);
        }

        if (batch.supplier == address(0)) {
            revert InvalidBatchSupplier();
        }

        if (batch.certificationDate <= block.timestamp) {
            revert BatchCertificationDateInThePast(batch.certificationDate);
        }

        batchCreated[batch.id] = true;
        batches[batch.id] = batch;
        batchIds.push(batch.id);
        projectBatches[batch.projectId].push(batch.id);
        batchCategory[batch.id] = projectCategory[batch.projectId];
        forwardContractBatch.mint(batch.supplier, batch.id, mintableAmount, "");

        emit BatchCreated(batch.id);
    }

    // todo #121: add authorization
    /// @inheritdoc IWeeklyCarbonRewardsManager
    function setWeeklyRewardsMinter(address _weeklyRewardsMinter) external {
        weeklyRewardsMinter = _weeklyRewardsMinter;
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function computeWeeklyCarbonRewards(address[] calldata assets, uint[] calldata _categoryIds)
        external
        view
        override
        returns (address[] memory carbonRewards, uint[] memory rewardAmounts)
    {
        if (assets.length != _categoryIds.length) {
            revert InvalidInput();
        }

        carbonRewards = new address[](assets.length);
        rewardAmounts = new uint[](assets.length);

        for (uint i; i < assets.length; i++) {
            uint categoryId = _categoryIds[i];
            if (!categoryIds[categoryId]) {
                revert InvalidCategoryId(categoryId);
            }

            CollateralizedBasketToken rewardToken = categoryToken[categoryId];
            uint rewardAmount = _computeWeeklyCategoryReward(categoryId, rewardToken.decimals());

            carbonRewards[i] = address(rewardToken);
            rewardAmounts[i] = rewardAmount;
        }
    }

    /// @inheritdoc IWeeklyCarbonRewardsManager
    function mintWeeklyCarbonRewards(
        uint[] calldata _categoryIds,
        address[] calldata carbonRewards,
        uint[] calldata rewardAmounts,
        address rewardsVault
    ) external override {
        if (
            _categoryIds.length != carbonRewards.length ||
            carbonRewards.length != rewardAmounts.length
        ) {
            revert InvalidInput();
        }

        if (msg.sender != weeklyRewardsMinter) {
            revert UnauthorizedRewardMinting(msg.sender);
        }

        for (uint i; i < carbonRewards.length; i++) {
            address carbonReward = carbonRewards[i];
            CollateralizedBasketToken rewardToken = CollateralizedBasketToken(carbonReward);
            uint rewardAmount = rewardAmounts[i];

            rewardToken.mint(rewardsVault, rewardAmount);
            emit WeeklyRewardMinted(carbonReward, rewardAmount);

            _rebalanceCategory(_categoryIds[i]);
        }
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
            categories[batchCategory[batchId]],
            amountIn
        );

        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (uint cbtUserCut, uint cbtDaoCut, ) = SolidMath.computeCollateralizationOutcome(
            batches[batchId].certificationDate,
            amountIn,
            reactiveTA,
            collateralizationFee,
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
        _rebalanceCategory(batchCategory[batchId], reactiveTA, amountIn, decayingMomentum);

        collateralizedToken.mint(msg.sender, cbtUserCut);
        collateralizedToken.mint(feeReceiver, cbtDaoCut);

        forwardContractBatch.safeTransferFrom(msg.sender, address(this), batchId, amountIn, "");

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

        _rebalanceCategory(batchCategory[batchId]);
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
            uint currentBatchCategoryId = batchCategory[_batchIds[i]];
            uint previousBatchCategoryId = batchCategory[_batchIds[i - 1]];

            if (currentBatchCategoryId != previousBatchCategoryId) {
                revert BatchesNotInSameCategory(currentBatchCategoryId, previousBatchCategoryId);
            }
        }

        for (uint i; i < _batchIds.length; i++) {
            _decollateralizeTokens(_batchIds[i], amountsIn[i], amountsOutMin[i]);
        }

        uint decollateralizedCategoryId = batchCategory[_batchIds[0]];
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

        DomainDataTypes.Category storage category = categories[batchCategory[batchId]];
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (, uint reactiveTA) = ReactiveTimeAppreciationMath.computeReactiveTA(category, amountIn);

        (cbtUserCut, cbtDaoCut, cbtForfeited) = SolidMath.computeCollateralizationOutcome(
            batches[batchId].certificationDate,
            amountIn,
            reactiveTA,
            collateralizationFee,
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
        public
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
            batches[batchId].certificationDate,
            amountIn,
            batches[batchId].batchTA,
            decollateralizationFee,
            collateralizedToken.decimals()
        );

        (minAmountIn, minCbtDaoCut) = SolidMath.computeDecollateralizationMinAmountInAndDaoCut(
            batches[batchId].certificationDate,
            amountOut,
            batches[batchId].batchTA,
            decollateralizationFee,
            collateralizedToken.decimals()
        );
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
            memory allInfos = new DomainDataTypes.TokenDecollateralizationInfo[](batchIds.length);
        uint infoCount;

        for (uint i; i < batchIds.length; i++) {
            uint batchId = batchIds[i];
            if (batches[batchId].vintage != vintage || batches[batchId].projectId != projectId) {
                continue;
            }

            uint availableCredits = forwardContractBatch.balanceOf(address(this), batchId);

            (uint amountOut, uint minAmountIn, uint minCbtDaoCut) = simulateDecollateralization(
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
    function setCollateralizationFee(uint16 _collateralizationFee) public {
        collateralizationFee = _collateralizationFee;
    }

    // todo #121: add authorization
    function setDecollateralizationFee(uint16 _decollateralizationFee) public {
        decollateralizationFee = _decollateralizationFee;
    }

    // todo #121: add authorization
    function setFeeReceiver(address _feeReceiver) public {
        feeReceiver = _feeReceiver;
    }

    function getProjectIdsByCategory(uint categoryId) public view returns (uint[] memory) {
        return categoryProjects[categoryId];
    }

    function getBatchIdsByProject(uint projectId) public view returns (uint[] memory) {
        return projectBatches[projectId];
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
        return interfaceId == 0xd9b67a26; // The ERC-165 identifier for ERC-1155
    }

    /// @dev Computes the amount of ERC20 tokens to be rewarded over the next 7 days
    /// @param categoryId The source category for the ERC20 rewards
    function _computeWeeklyCategoryReward(uint categoryId, uint rewardDecimals)
        internal
        view
        returns (uint)
    {
        uint rewardAmount;

        uint[] storage projects = categoryProjects[categoryId];
        for (uint i; i < projects.length; i++) {
            uint projectId = projects[i];
            uint[] storage _batches = projectBatches[projectId];
            for (uint j; j < _batches.length; j++) {
                uint batchId = _batches[j];
                uint availableCredits = forwardContractBatch.balanceOf(address(this), batchId);
                if (availableCredits == 0 || _isBatchCertified(batchId)) {
                    continue;
                }

                DomainDataTypes.Batch storage batch = batches[batchId];
                rewardAmount += SolidMath.computeWeeklyBatchReward(
                    batch.certificationDate,
                    availableCredits,
                    batch.batchTA,
                    rewardDecimals
                );
            }
        }

        return rewardAmount;
    }

    function _updateBatchTA(
        uint batchId,
        uint reactiveTA,
        uint toBeCollateralizedForwardCredits,
        uint toBeMintedCBT,
        uint cbtDecimals
    ) internal {
        DomainDataTypes.Batch storage batch = batches[batchId];
        uint collateralizedForwardCredits = forwardContractBatch.balanceOf(address(this), batch.id);
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

        uint[] storage projects = categoryProjects[categoryId];
        for (uint i; i < projects.length; i++) {
            uint projectId = projects[i];
            uint[] storage _batches = projectBatches[projectId];
            for (uint j; j < _batches.length; j++) {
                uint batchId = _batches[j];
                uint collateralizedForwardCredits = forwardContractBatch.balanceOf(
                    address(this),
                    batchId
                );
                if (collateralizedForwardCredits == 0 || _isBatchCertified(batchId)) {
                    continue;
                }

                totalQuantifiedForwardCredits +=
                    batches[batchId].batchTA *
                    collateralizedForwardCredits;
                totalCollateralizedForwardCredits += collateralizedForwardCredits;
            }
        }

        if (totalCollateralizedForwardCredits == 0) {
            categories[categoryId].totalCollateralized = 0;
            emit CategoryRebalanced(categoryId, categories[categoryId].averageTA, 0);
            return;
        }

        uint latestAverageTA = totalQuantifiedForwardCredits / totalCollateralizedForwardCredits;
        categories[categoryId].averageTA = uint24(latestAverageTA);
        categories[categoryId].totalCollateralized = totalCollateralizedForwardCredits;

        emit CategoryRebalanced(categoryId, latestAverageTA, totalCollateralizedForwardCredits);
    }

    function _rebalanceCategory(
        uint categoryId,
        uint reactiveTA,
        uint currentCollateralizedAmount,
        uint decayingMomentum
    ) internal {
        DomainDataTypes.Category storage category = categories[categoryId];

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
                batches[batchId].certificationDate,
                amountIn,
                batches[batchId].batchTA,
                decollateralizationFee,
                collateralizedToken.decimals()
            );

        if (amountOut <= 0) {
            revert AmountOutTooLow(amountOut);
        }

        if (amountOut < amountOutMin) {
            revert AmountOutLessThanMinimum(amountOut, amountOutMin);
        }

        collateralizedToken.burnFrom(msg.sender, cbtToBurn);
        GPv2SafeERC20.safeTransferFrom(collateralizedToken, msg.sender, feeReceiver, cbtDaoCut);

        forwardContractBatch.safeTransferFrom(address(this), msg.sender, batchId, amountOut, "");

        emit TokensDecollateralized(batchId, amountIn, amountOut, msg.sender);
    }

    function _getCollateralizedTokenForBatchId(uint batchId)
        internal
        view
        returns (CollateralizedBasketToken)
    {
        uint projectId = batches[batchId].projectId;
        uint categoryId = projectCategory[projectId];

        return categoryToken[categoryId];
    }

    function _isBatchCertified(uint batchId) internal view returns (bool) {
        return batches[batchId].certificationDate <= block.timestamp;
    }
}
