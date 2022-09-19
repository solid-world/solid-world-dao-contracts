// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Erc20Deployer.sol";

contract SolidWorldManager is Initializable, OwnableUpgradeable {
    Erc20Deployer erc20Deployer;

    mapping(uint256 => address) public categoryToken;

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
        address tokenAddress = erc20Deployer.deploy(address(this), tokenName, tokenSymbol);
        categoryToken[categoryId] = tokenAddress;
    }
}
