// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract CarbonCredit is Initializable, ERC1155Upgradeable, OwnableUpgradeable {
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(string memory uri_) public initializer {
        __ERC1155_init(uri_);
        __Ownable_init();
    }

    /**
     * @notice method for minting new token
     * @dev only owner
     * @param _to address of the owner of new token
     * @param _id id of new token
     * @param _amount amount of new token
     * @param _data external data
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public onlyOwner {
        _mint(_to, _id, _amount, _data);
    }

    /**
     * @notice method for burning existing token
     * @dev only owner
     * @param _account address of the owner of token what is burned
     * @param _id id of token what is burned
     * @param _amount amount of token what is burned
     */
    function burn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) public {
        _burn(_account, _id, _amount);
    }
}
