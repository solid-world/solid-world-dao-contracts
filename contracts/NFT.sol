// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/Strings.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract NFT is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    // URI's default URI prefix
    string internal baseMetadataURI;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(string memory name_, string memory symbol_)
        public
        initializer
    {
        __ERC721_init(name_, symbol_);
        __Ownable_init();
    }

    /**
     * @notice Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI)
        public
        onlyOwner
    {
        baseMetadataURI = _newBaseMetadataURI;
    }

    /**
     * @notice Will return token's URI
     * @dev only owner
     * @param _id token Id
     */
    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        return Strings.strConcat(baseMetadataURI, Strings.uint2str(_id));
    }

    /**
     * @notice method for minting token
     * @dev only owner
     * @param _to address of new owner of given token Id
     * @param _tokenId id of new token
     */
    function mint(address _to, uint256 _tokenId) public onlyOwner {
        _mint(_to, _tokenId);
    }
}
