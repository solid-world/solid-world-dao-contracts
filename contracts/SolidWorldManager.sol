// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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
     * @param id ID of the batch in the database
     * @param projectId Project ID this batch belongs to
     * @param totalAmount Amount of carbon tons in the batch, this amount will be minted as forward contract batch tokens (ERC-1155)
     * @notice Structure that holds necessary information for minting forward commodity tokens (ERC-20).
     * @param owner Address who receives forward contract batch tokens (ERC-1155)
     * @param expectedDueDate When the batch is about to be delivered; affects on how many forward commodity tokens (ERC-20) may be minted
     * @param status Status for the batch (ex. CAN_BE_DEPOSITED | IS_ACCUMULATING | READY_FOR_DELIVERY etc.)
     * @param discountRate Coefficient that affects on how many forward commodity tokens (ERC-20) may be minted / ton
     */
    struct Batch {
        uint id;
        uint projectId;
        uint totalAmount;
        address owner;
        uint32 expectedDueDate;
        uint8 status;
        uint8 discountRate;
    }

    /**
     * @notice Contract that operates forward contract batch tokens (ERC-1155). Allows this contract to mint tokens.
     */
    ForwardContractBatchToken public forwardContractBatch;

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
    mapping(uint => bool) public batchIds;

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
    mapping(uint => uint[]) internal categoryProjects;

    /**
     * @notice Mapping determines what category a project belongs to
     * @dev ProjectId => CategoryId
     */
    mapping(uint => uint) internal projectCategory;

    /**
     * @notice Mapping determines what batches a project has
     * @dev ProjectId => BatchId[]
     */
    mapping(uint => uint[]) internal projectBatches;

    uint public timeAppreciation;
    uint public collateralizationFee;

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

    function initialize(
        ForwardContractBatchToken _forwardContractBatch,
        uint _collateralizationFee,
        uint _timeAppreciation
    ) public initializer {
        __Ownable_init();

        forwardContractBatch = _forwardContractBatch;
        collateralizationFee = _collateralizationFee;
        timeAppreciation = _timeAppreciation;
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
    }

    // todo #121: add authorization
    function addProject(uint categoryId, uint projectId) external {
        require(categoryIds[categoryId], "Add project: unknown categoryId.");
        require(!projectIds[projectId], "Add project: projectId already exists.");

        categoryProjects[categoryId].push(projectId);
        projectCategory[projectId] = categoryId;
        projectIds[projectId] = true;
    }

    // todo #121: add authorization
    function addBatch(Batch calldata batch) external {
        require(projectIds[batch.projectId], "Add batch: This batch belongs to unknown project.");
        require(!batchIds[batch.id], "Add batch: This batch has already been created.");
        require(batch.owner != address(0), "Add batch: Batch owner not defined.");
        require(
            batch.expectedDueDate > block.timestamp,
            "Add batch: Batch expected due date must be in the future."
        );

        batchIds[batch.id] = true;
        batches[batch.id] = batch;
        projectBatches[batch.projectId].push(batch.id);
        forwardContractBatch.mint(batch.owner, batch.id, batch.totalAmount, "");
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
    ) external nonReentrant {
        require(batchIds[batchId], "Collateralize batch: invalid batchId.");

        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);

        (uint cbtUserCut, uint cbtDaoCut) = SolidMath.computeCollateralizationOutcome(
            batches[batchId].expectedDueDate,
            amountIn,
            timeAppreciation,
            collateralizationFee,
            collateralizedToken.decimals()
        );
        require(cbtUserCut >= amountOutMin, "Collateralize batch: amountOut < amountOutMin.");

        collateralizedToken.mint(msg.sender, cbtUserCut);
        // todo: mint `cbtDaoCut` to DAO

        forwardContractBatch.safeTransferFrom(msg.sender, address(this), batchId, amountIn, "");

        emit BatchCollateralized(batchId, amountIn, cbtUserCut, msg.sender);
    }

    /**
     * @dev Decollateralizes `amountIn` of ERC20 tokens and sends `amountOut` ERC1155 tokens with id `batchId` for msg.sender
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
    ) external nonReentrant {
        require(batchIds[batchId], "Decollateralize batch: invalid batchId.");

        uint amountOut = amountIn; // todo #122: implement function to compute ERC20=>ERC1155 output amount
        require(amountOut >= amountOutMin, "Decollateralize batch: amountOut < amountOutMin.");

        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);
        collateralizedToken.burnFrom(msg.sender, amountIn);

        forwardContractBatch.safeTransferFrom(
            address(this),
            msg.sender,
            batchId,
            amountOut,
            new bytes(0)
        );

        emit TokensDecollateralized(batchId, amountIn, amountOut, msg.sender);
    }

    // todo #121: add authorization
    function setCollateralizationFee(uint _collateralizationFee) public {
        collateralizationFee = _collateralizationFee;
    }

    // todo #121: add authorization
    function setTimeAppreciation(uint _timeAppreciation) public {
        timeAppreciation = _timeAppreciation;
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
