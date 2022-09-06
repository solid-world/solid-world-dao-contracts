//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./SolidAccessControl.sol";
import "./NFT.sol";
import "./CarbonCredit.sol";

contract SolidMarketplace is Initializable, OwnableUpgradeable {
    uint256 public currentTokenID;

    /// @dev Required to manage ERC721
    NFT public nftContract;

    /// @dev Required to manage ERC1155
    CarbonCredit public carboncreditContract;

    /// @dev Required to govern who can call certain functions
    SolidAccessControl public accessControls;

    /// @notice Event emitted when token is created
    event Create(uint256 indexed id, address indexed ownerAddress, uint256 amount, address indexed insuranceAddress, uint256 amountToInsurance);

    function initialize(
        NFT _nftAddress,
        CarbonCredit _carbonCreditAddress,
        SolidAccessControl _accessControls
    ) public initializer {
        nftContract = _nftAddress;
        carboncreditContract = _carbonCreditAddress;
        currentTokenID = 0;
        accessControls = _accessControls;
        __Ownable_init();
    }

    /**
    @notice Method for updating the access controls contract used by the NFT
    @dev Only admin
    @param _accessControls Address of the new access controls contract
    */
    function updateAccessControls(SolidAccessControl _accessControls)
        public
        onlyOwner
    {
        accessControls = _accessControls;
    }

    /**
	@notice Method for creating project(ERC721) and carbon credits(ERC1155) for it
	@dev only minter, smart contract or admin role
	@param _projectOwnerAddress Address of the owner of the new token(ERC721 and ERC1155)
	@param _amount the amount of CarbonCredit to be minted to _projectOwnerAddress
    @param _insuranceAddress Address of the insurance company
    @param _amountToInsurance the amount of CarbonCredit to be minted to _insuranceAddress
	@param _data external data of new project
	 */
    function create(
        address _projectOwnerAddress,
        uint256 _amount,
        address _insuranceAddress,
        uint256 _amountToInsurance,
        bytes memory _data
    ) external returns (uint256) {
        require(
            accessControls.hasMinterRole(_msgSender()) ||
                accessControls.hasSmartContractRole(_msgSender()) ||
                accessControls.hasAdminRole(_msgSender()),
            "only minter,smartcontract role, or admin can perform this operation"
        );
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        nftContract.mint(_projectOwnerAddress, _id);
        carboncreditContract.mint(_projectOwnerAddress, _id, _amount, _data);
        carboncreditContract.mint(_insuranceAddress, _id, _amountToInsurance, _data);
        emit Create(_id, _projectOwnerAddress, _amount, _insuranceAddress, _amountToInsurance);
        return _id;
    }

    /**
	@notice Method for minting CarbonCredit
	@dev only minter, smart contract or admin role
	@param _projectOwnerAddress Address to recieve CarbonCredit tokens
	@param _id token Id of the CarbonCredit what is minted
	@param _amount the amount of CarbonCredit
	@param _data external data of new project
	 */
    function mintCarbonCredit(
        address _projectOwnerAddress,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external returns (uint256) {
        require(
            accessControls.hasMinterRole(_msgSender()) ||
                accessControls.hasSmartContractRole(_msgSender()) ||
                accessControls.hasAdminRole(_msgSender()),
            "only minter,smartcontract role, or admin can perform this operation"
        );
        carboncreditContract.mint(_projectOwnerAddress, _id, _amount, _data);
        return _id;
    }

    /**
	@notice Method for burning CarbonCredit
	@dev only admin role
	@param _projectOwnerAddress Address of the owner of the CarbonCredit token what is burned
	@param _id token Id of the CarbonCredit what is burned
	@param _amount amount of the CarbonCredit what is burned
	 */
    function burnCarbonCredit(
        address _projectOwnerAddress,
        uint256 _id,
        uint256 _amount
    ) external returns (uint256) {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "only admin can perform this operation"
        );
        carboncreditContract.burn(_projectOwnerAddress, _id, _amount);
        return _id;
    }

    /**
	@notice Method for transferring NFT and CarbonCredit of it
	@dev only admin role
	@param _sellerAddress Address of the seller
	@param _buyerAddress Address of the buyer
	@param _id token Id of the CarbonCredit what is transferred
	@param _data external data for transferring NFT
	 */
    function transferNFT(
        address _sellerAddress,
        address _buyerAddress,
        uint256 _id,
        bytes memory _data
    ) external {
        nftContract.safeTransferFrom(_sellerAddress, _buyerAddress, _id, _data);
    }

    /**
	@notice Method for transferring CarbonCredit
	@dev only admin role
	@param _sellerAddress Address of the seller
	@param _buyerAddress Address of the buyer
	@param _id token Id of the CarbonCredit what is transferred
	@param _data external data for transferring NFT
	 */
    function transferCarbonCredit(
        address _sellerAddress,
        address _buyerAddress,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external {
        carboncreditContract.safeTransferFrom(
            _sellerAddress,
            _buyerAddress,
            _id,
            _amount,
            _data
        );
    }

    /// @dev set baseMetadataURI for ERC721 token
    function setBaseMetadataURI(string memory _newBaseMetadataURI) public {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "only admin can perform this operation"
        );
        nftContract.setBaseMetadataURI(_newBaseMetadataURI);
    }

    /// @dev get next token id to use
    function _getNextTokenID() private view returns (uint256) {
        return currentTokenID + 1;
    }

    /// @dev increase token id
    function _incrementTokenTypeId() private {
        currentTokenID++;
    }
}
