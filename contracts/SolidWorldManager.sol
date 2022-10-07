// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "./ForwardContractBatchToken.sol";
import "./CollateralizedBasketToken.sol";

contract SolidWorldManager is Initializable, OwnableUpgradeable, IERC1155ReceiverUpgradeable {
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

    function initialize(ForwardContractBatchToken _forwardContractBatch) public initializer {
        forwardContractBatch = _forwardContractBatch;
        __Ownable_init();
    }

    // todo: add authorization
    function addCategory(
        uint categoryId,
        string calldata tokenName,
        string calldata tokenSymbol
    ) external {
        require(!categoryIds[categoryId], "Add category: categoryId already exists.");

        categoryIds[categoryId] = true;
        categoryToken[categoryId] = new CollateralizedBasketToken(tokenName, tokenSymbol);
    }

    // todo: add authorization
    function addProject(uint categoryId, uint projectId) external {
        require(categoryIds[categoryId], "Add project: unknown categoryId.");
        require(!projectIds[projectId], "Add project: projectId already exists.");

        categoryProjects[categoryId].push(projectId);
        projectIds[projectId] = true;
    }

    // todo: add authorization
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
        forwardContractBatch.mint(batch.owner, batch.id, batch.totalAmount, new bytes(0));
    }

    // todo: add authorization
    function collateraliseBatch(uint batchId, uint amount) external {
        require(batchIds[batchId], "Collateralise batch: invalid batchId.");
        require(
            forwardContractBatch.balanceOf(msg.sender, batchId) >= amount,
            "Collateralise batch: insufficient Forward Contract Batch balance."
        );

        CollateralizedBasketToken collateralizedToken = _getCollateralizedTokenForBatchId(batchId);
        //        collateralizedToken.mint(msg.sender, amount);

        forwardContractBatch.safeTransferFrom(
            msg.sender,
            address(this),
            batchId,
            amount,
            new bytes(0)
        );
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

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaceId == 0xd9b67a26;
    }

    function _getCollateralizedTokenForBatchId(uint batchId)
        internal
        returns (CollateralizedBasketToken)
    {
        uint projectId = batches[batchId].projectId;
        uint categoryId = projectCategory[projectId];

        return categoryToken[categoryId];
    }

    function getProjectIdsByCategory(uint categoryId) public view returns (uint[] memory) {
        return categoryProjects[categoryId];
    }

    function getBatchIdsByProject(uint projectId) public view returns (uint[] memory) {
        return projectBatches[projectId];
    }
}
