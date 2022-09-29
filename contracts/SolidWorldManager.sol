// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Erc20Deployer.sol";
import "./CarbonCredit.sol";

contract SolidWorldManager is Initializable, OwnableUpgradeable {
    /**
     * @notice Structure that holds necessary information for minting carbon tokens (ERC-20).
     * @param id ID of the batch in the database
     * @param status todo: ask Rez about logic behind it, currently is not being used
     * @param projectId Project ID that has this batch
     * @param totalAmount Amount of carbon tons in the batch, this amount will be minted as forward contract batch tokens (ERC-1155)
     * @param expectedDueDate When the batch is about to be delivered; affects on how many carbon tokens (ERC-20) may be minted
     * @param discountRate Coefficient that affects on how many carbon tokens (ERC-20) may be minted
     * @param owner Address who receives forward contract batch tokens (ERC-1155)
     */
    struct Batch {
        uint256 id;
        uint8 status;
        uint256 projectId;
        uint256 totalAmount;
        uint32 expectedDueDate;
        uint8 discountRate;
        address owner;
    }

    /**
     * @notice Contract that deploys new arbitrary ERC-20 contract. Allows this contract to mint tokens.
     */
    Erc20Deployer erc20Deployer;

    /**
     * @notice Contract that operates forward contract batch tokens (ERC-1155). Allows this contract to mint tokens.
     */
    CarbonCredit public forwardContractBatch;

    /**
     * @notice Mapping is used for checking if Category ID is already added
     * @dev CategoryId => isAdded
     */
    mapping(uint256 => bool) public categoryIds;

    /**
     * @notice Property is used for checking if Project ID is already added
     * @dev ProjectId => isAdded
     */
    mapping(uint256 => bool) public projectIds;

    /**
     * @notice Property is used for checking if Batch ID is already added
     * @dev BatchId => isAdded
     */
    mapping(uint256 => bool) public batchIds;

    /**
     * @notice Property stores info about a batch
     * @dev BatchId => Batch
     */
    mapping(uint256 => Batch) public batches;

    /**
     * @notice Mapping determines a respective carbon token address (ERC-20) of a category
     * @dev CategoryId => CarbonTokenAddress (ERC-20)
     */
    mapping(uint256 => address) public categoryToken;

    /**
     * @notice Mapping determines what projects a category has
     * @dev CategoryId => ProjectId[]
     */
    mapping(uint256 => uint256[]) internal categoryProjects;

    /**
     * @notice Mapping determines what category a project belongs to
     * @dev ProjectId => CategoryId
     */
    mapping(uint256 => uint256) internal projectCategory;

    /**
     * @notice Mapping determines what batches a project has
     * @dev ProjectId => BatchId[]
     */
    mapping(uint256 => uint256[]) internal projectBatches;

    function initialize(Erc20Deployer _erc20Deployer, CarbonCredit _forwardContractBatch)
        public
        initializer
    {
        erc20Deployer = _erc20Deployer;
        forwardContractBatch = _forwardContractBatch;
        __Ownable_init();
    }

    // todo: add authorization
    function addCategory(
        uint256 categoryId,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        // todo: add sanity check, like categoryId value, overriding, etc
        categoryIds[categoryId] = true;

        address tokenAddress = erc20Deployer.deploy(address(this), tokenName, tokenSymbol);
        categoryToken[categoryId] = tokenAddress;
    }

    // todo: add authorization
    function addProject(uint256 categoryId, uint256 projectId) public {
        require(categoryIds[categoryId]);
        require(!projectIds[projectId]);

        categoryProjects[categoryId].push(projectId);
        projectIds[projectId] = true;
    }

    // todo: add authorization
    function addBatch(Batch calldata batch) public {
        require(projectIds[batch.projectId]);
        require(!batchIds[batch.id]);
        require(batch.owner != address(0));
        require(batch.expectedDueDate > block.timestamp);

        batchIds[batch.id] = true;
        batches[batch.id] = batch;
        projectBatches[batch.projectId].push(batch.id);

        forwardContractBatch.mint(batch.owner, batch.id, batch.totalAmount, new bytes(0));
    }

    function getProjectIdsByCategory(uint256 categoryId) public view returns (uint256[] memory) {
        return categoryProjects[categoryId];
    }

    function getBatchIdsByProject(uint256 projectId) public view returns (uint256[] memory) {
        return projectBatches[projectId];
    }
}
