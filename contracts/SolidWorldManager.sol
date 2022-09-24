// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Erc20Deployer.sol";

contract SolidWorldManager is Initializable, OwnableUpgradeable {
    Erc20Deployer erc20Deployer;

    mapping(uint256 => bool) public categoryIds;

    mapping(uint256 => bool) public projectIds;

    mapping(uint256 => address) public categoryToken;

    mapping(uint256 => uint256[]) internal categoryProjects;

    mapping(uint256 => uint256) internal projectCategory;

    function initialize(Erc20Deployer _erc20Deployer) public initializer {
        erc20Deployer = _erc20Deployer;
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

    function getProjectIdsByCategory(uint256 categoryId) public view returns (uint256[] memory) {
        return categoryProjects[categoryId];
    }
}
