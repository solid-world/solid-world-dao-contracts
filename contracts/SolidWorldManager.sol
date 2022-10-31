// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "./ForwardContractBatchToken.sol";
import "./CollateralizedBasketToken.sol";
import "./lib/SolidMath.sol";

contract SolidWorldManager is
    Initializable,
    OwnableUpgradeable,
    IERC1155ReceiverUpgradeable,
    ReentrancyGuard
{
    /**
     * @notice Structure that holds necessary information for minting collateralized basket tokens (ERC-20).
     * @param id ID of the batch in the database
     * @param projectId Project ID this batch belongs to
     * @param totalAmount Amount of carbon tons in the batch, this amount will be minted as forward contract batch tokens (ERC-1155)
     * @param owner Address who receives forward contract batch tokens (ERC-1155)
     * @param expectedDueDate When the batch is about to be delivered; affects on how many collateralized basket tokens (ERC-20) may be minted
     * @param vintage The year an emission reduction occurred or the offset was issued. The older the vintage, the cheaper the price per credit.
     * @param status Status for the batch (ex. CAN_BE_DEPOSITED | IS_ACCUMULATING | READY_FOR_DELIVERY etc.)
     * @param discountRate Coefficient that affects on how many collateralized basket tokens (ERC-20) may be minted / ton. Forward is worth less than spot.
     */
    struct Batch {
        uint id;
        uint projectId;
        uint totalAmount;
        address owner;
        uint32 expectedDueDate;
        uint16 vintage;
        uint8 status;
        uint24 discountRate;
    }

    /**
     * @notice Structure that holds necessary information for decollateralizing ERC20 tokens to ERC1155 tokens with id `batchId`
     * @param batchId id of the batch
     * @param availableCredits Amount of ERC1155 tokens with id `batchId` that are available to be redeemed
     * @param amountOut ERC1155 tokens with id `batchId` to be received by msg.sender
     * @param minAmountIn minimum amount of ERC20 tokens to decollateralize `amountOut` ERC1155 tokens with id `batchId`
     */
    struct TokenDecollateralizationInfo {
        uint batchId;
        uint availableCredits;
        uint amountOut;
        uint minAmountIn;
    }

    /**
     * @notice Mapping is used for checking if Category ID is already added
     * @dev CategoryId => isAdded
     */
    mapping(uint => bool) public categoryIds;

    /**
     * @notice Property is used for checking if Project ID is already added
     * @dev ProjectId => isAdded
     */
    mapping(uint => bool) public projectIds;

    /**
     * @notice Property is used for checking if Batch ID is already added
     * @dev BatchId => isAdded
     */
    mapping(uint => bool) public batchCreated;

    /**
     * @notice Stores all batch ids ever created
     */
    uint[] public batchIds;

    /**
     * @notice Property stores info about a batch
     * @dev BatchId => Batch
     */
    mapping(uint => Batch) public batches;

    /**
     * @notice Mapping determines a respective CollateralizedBasketToken (ERC-20) of a category
     * @dev CategoryId => CollateralizedBasketToken address (ERC-20)
     */
    mapping(uint => CollateralizedBasketToken) public categoryToken;

    /**
     * @notice Mapping determines what projects a category has
     * @dev CategoryId => ProjectId[]
     */
    mapping(uint => uint[]) public categoryProjects;

    /**
     * @notice Mapping determines what category a project belongs to
     * @dev ProjectId => CategoryId
     */
    mapping(uint => uint) public projectCategory;

    /**
     * @notice Mapping determines what batches a project has
     * @dev ProjectId => BatchId[]
     */
    mapping(uint => uint[]) public projectBatches;

    /**
     * @notice Contract that operates forward contract batch tokens (ERC-1155). Allows this contract to mint tokens.
     */
    ForwardContractBatchToken public forwardContractBatch;

    /**
     * @notice The account where all protocol fees are captured.
     */
    address public feeReceiver;

    /**
     * @notice Fee charged by DAO when collateralizing forward contract batch tokens.
     */
    uint16 public collateralizationFee;

    /**
     * @notice Fee charged by DAO when decollateralizing collateralized basket tokens.
     */
    uint16 public decollateralizationFee;

    event BatchCollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed batchOwner
    );
    event TokensDecollateralized(
        uint indexed batchId,
        uint amountIn,
        uint amountOut,
        address indexed tokensOwner
    );
    event CategoryCreated(uint indexed categoryId);
    event ProjectCreated(uint indexed projectId);
    event BatchCreated(uint indexed batchId);

    modifier validBatch(uint batchId) {
        require(batchCreated[batchId], "Invalid batchId.");
        _;
    }

    function initialize(
        ForwardContractBatchToken _forwardContractBatch,
        uint16 _collateralizationFee,
        uint16 _decollateralizationFee,
        address _feeReceiver
    ) public initializer {
        __Ownable_init();

        forwardContractBatch = _forwardContractBatch;
        collateralizationFee = _collateralizationFee;
        decollateralizationFee = _decollateralizationFee;
        feeReceiver = _feeReceiver;
    }

    // todo #121: add authorization
    function addCategory(
        uint categoryId,
        string calldata tokenName,
        string calldata tokenSymbol
    ) external {
        require(!categoryIds[categoryId], "Add category: categoryId already exists.");

        categoryIds[categoryId] = true;
        categoryToken[categoryId] = new CollateralizedBasketToken(tokenName, tokenSymbol);

        emit CategoryCreated(categoryId);
    }

    // todo #121: add authorization
    function addProject(uint categoryId, uint projectId) external {
        require(categoryIds[categoryId], "Add project: unknown categoryId.");
        require(!projectIds[projectId], "Add project: projectId already exists.");

        categoryProjects[categoryId].push(projectId);
        projectCategory[projectId] = categoryId;
        projectIds[projectId] = true;

        emit ProjectCreated(projectId);
    }

    // todo #121: add authorization
    function addBatch(Batch calldata batch) external {
        require(projectIds[batch.projectId], "Add batch: This batch belongs to unknown project.");
        require(!batchCreated[batch.id], "Add batch: This batch has already been created.");
        require(batch.owner != address(0), "Add batch: Batch owner not defined.");
        require(
            batch.expectedDueDate > block.timestamp,
            "Add batch: Batch expected due date must be in the future."
        );

        batchCreated[batch.id] = true;
        batches[batch.id] = batch;
        batchIds.push(batch.id);
        projectBatches[batch.projectId].push(batch.id);
        forwardContractBatch.mint(batch.owner, batch.id, batch.totalAmount, "");

        emit BatchCreated(batch.id);
    }

    /**
     * @dev Collateralizes `amountIn` of ERC1155 tokens with id `batchId` for msg.sender
     * @dev prior to calling, msg.sender must approve SolidWorldManager to spend its ERC1155 tokens with id `batchId`
     * @dev nonReentrant, to avoid possible reentrancy after calling safeTransferFrom
     * @param batchId id of the batch
     * @param amountIn ERC1155 tokens to collateralize
     * @param amountOutMin minimum output amount of ERC20 tokens for transaction to succeed
     */
    function collateralizeBatch(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) external nonReentrant validBatch(batchId) {
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (uint cbtUserCut, uint cbtDaoCut, ) = SolidMath.computeCollateralizationOutcome(
            batches[batchId].expectedDueDate,
            amountIn,
            batches[batchId].discountRate,
            collateralizationFee,
            collateralizedToken.decimals()
        );
        require(cbtUserCut >= amountOutMin, "Collateralize batch: amountOut < amountOutMin.");

        collateralizedToken.mint(msg.sender, cbtUserCut);
        collateralizedToken.mint(feeReceiver, cbtDaoCut);

        forwardContractBatch.safeTransferFrom(msg.sender, address(this), batchId, amountIn, "");

        emit BatchCollateralized(batchId, amountIn, cbtUserCut, msg.sender);
    }

    /**
     * @dev Decollateralizes `amountIn` of ERC20 tokens and sends `amountOut` ERC1155 tokens with id `batchId` to msg.sender
     * @dev prior to calling, msg.sender must approve SolidWorldManager to spend `amountIn` ERC20 tokens
     * @dev nonReentrant, to avoid possible reentrancy after calling safeTransferFrom
     * @param batchId id of the batch
     * @param amountIn ERC20 tokens to decollateralize
     * @param amountOutMin minimum output amount of ERC1155 tokens for transaction to succeed
     */
    function decollateralizeTokens(
        uint batchId,
        uint amountIn,
        uint amountOutMin
    ) public nonReentrant validBatch(batchId) {
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (uint amountOut, uint cbtDaoCut, uint cbtToBurn) = SolidMath
            .computeDecollateralizationOutcome(
                batches[batchId].expectedDueDate,
                amountIn,
                batches[batchId].discountRate,
                decollateralizationFee,
                collateralizedToken.decimals()
            );

        require(amountOut > 0, "Decollateralize batch: input amount too low.");
        require(amountOut >= amountOutMin, "Decollateralize batch: amountOut < amountOutMin.");

        collateralizedToken.burnFrom(msg.sender, cbtToBurn);
        collateralizedToken.transferFrom(msg.sender, feeReceiver, cbtDaoCut);

        forwardContractBatch.safeTransferFrom(address(this), msg.sender, batchId, amountOut, "");

        emit TokensDecollateralized(batchId, amountIn, amountOut, msg.sender);
    }

    /**
     * @dev Bulk-decollateralizes ERC20 tokens into multiple ERC1155 tokens with specified amounts
     * @dev prior to calling, msg.sender must approve SolidWorldManager to spend `sum(amountsIn)` ERC20 tokens
     * @param batchIds ids of the batches
     * @param amountsIn ERC20 tokens to decollateralize
     * @param amountsOutMin minimum output amounts of ERC1155 tokens for transaction to succeed
     */
    function decollateralizeTokensBulk(
        uint[] calldata batchIds,
        uint[] calldata amountsIn,
        uint[] calldata amountsOutMin
    ) external {
        require(batchIds.length == amountsIn.length, "Decollateralize batch: invalid input.");
        require(batchIds.length == amountsOutMin.length, "Decollateralize batch: invalid input.");

        for (uint i = 0; i < batchIds.length; i++) {
            decollateralizeTokens(batchIds[i], amountsIn[i], amountsOutMin[i]);
        }
    }

    /**
     * @dev Simulates collateralization of `amountIn` ERC1155 tokens with id `batchId` for msg.sender
     * @param batchId id of the batch
     * @param amountIn ERC1155 tokens to collateralize
     * @return cbtUserCut ERC20 tokens to be received by msg.sender
     * @return cbtDaoCut ERC20 tokens to be received by feeReceiver
     * @return cbtForfeited ERC20 tokens forfeited for collateralizing the ERC1155 tokens
     */
    function simulateBatchCollateralization(uint batchId, uint amountIn)
        external
        view
        validBatch(batchId)
        returns (
            uint cbtUserCut,
            uint cbtDaoCut,
            uint cbtForfeited
        )
    {
        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (cbtUserCut, cbtDaoCut, cbtForfeited) = SolidMath.computeCollateralizationOutcome(
            batches[batchId].expectedDueDate,
            amountIn,
            batches[batchId].discountRate,
            collateralizationFee,
            collateralizedToken.decimals()
        );
    }

    /**
     * @dev Simulates decollateralization of `amountIn` ERC20 tokens for ERC1155 tokens with id `batchId`
     * @param batchId id of the batch
     * @param amountIn ERC20 tokens to decollateralize
     * @return amountOut ERC1155 tokens to be received by msg.sender
     * @return minAmountIn minimum amount of ERC20 tokens to decollateralize `amountOut` ERC1155 tokens with id `batchId`
     * @return minCbtDaoCut ERC20 tokens to be received by feeReceiver for decollateralizing minAmountIn ERC20 tokens
     */
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
            batches[batchId].expectedDueDate,
            amountIn,
            batches[batchId].discountRate,
            decollateralizationFee,
            collateralizedToken.decimals()
        );

        (minAmountIn, minCbtDaoCut) = SolidMath.computeDecollateralizationMinAmountInAndDaoCut(
            batches[batchId].expectedDueDate,
            amountOut,
            batches[batchId].discountRate,
            decollateralizationFee,
            collateralizedToken.decimals()
        );
    }

    /**
     * @dev Computes relevant info for the decollateralization process involving batches that match the specified `categoryId` and `vintage`
     * @param categoryId id of the category the batch belongs to
     * @param vintage vintage of the batch
     * @return result array of relevant info about matching batches
     */
    function getBatchesDecollateralizationInfo(uint categoryId, uint vintage)
        external
        view
        returns (TokenDecollateralizationInfo[] memory result)
    {
        for (uint i = 0; i < batchIds.length; i++) {
            uint batchId = batchIds[i];
            if (
                batches[batchId].vintage != vintage ||
                projectCategory[batches[batchId].projectId] != categoryId
            ) {
                continue;
            }

            uint availableCredits = forwardContractBatch.balanceOf(address(this), batchId);
            (uint amountOut, uint minAmountIn, ) = simulateDecollateralization(batchId, 1000);

            result[i] = TokenDecollateralizationInfo(
                batchId,
                availableCredits,
                amountOut,
                minAmountIn
            );
        }

        return result;
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
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0xd9b67a26;
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
}
