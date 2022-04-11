// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISCTCarbonTreasury {

    enum STATUS {
        RESERVETOKEN,
        RESERVEMANAGER
    }

    enum StatusOffer {
        OPEN,
        EXECUTED,
        CANCELED
    }

    struct CarbonProject {
        address token;
        uint256 tokenId;
        uint256 tons;
        uint256 flatRate;
        uint256 sdgPremium;
        uint256 daysToRealization;
        uint256 closenessPremium;
        bool isActive;
        bool isCertified;
        bool isRedeemed;
    }

    struct Offer {
        address token;
        uint256 tokenId;
        address buyer;
        uint256 amount;
        uint256 totalValue;
        StatusOffer statusOffer;
    }


    event Deposited(address indexed token, uint256 indexed tokenId, address indexed owner, uint256 amount);
    event CreatedOffer(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 totalValue);
    event CanceledOffer(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 totalValue);
    event Sold(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed owner, address buyer, uint256 amount, uint256 totalValue);
    event UpdatedInfo(address indexed token, uint256 indexed tokenId, bool isActive);
    event ChangedTimelock(bool timelock);
    event SetOnChainGovernanceTimelock(uint256 blockNumber);
    event Permissioned(STATUS indexed status, address token, bool result);
    event PermissionOrdered(STATUS indexed status, address token);

    function initialize() external;
    function depositReserveToken(address _token, uint256 _tokenId, uint256 _amount,address _owner) external returns(bool);
    function createOffer(Offer memory _offer) external returns(uint256);
    function cancelOffer(uint256 _offerId) external returns(bool);
    function acceptOffer(uint256 _offerId) external returns(bool);
    function createOrUpdateCarbonProject(CarbonProject memory _carbonProject) external returns(bool);
    function enable(STATUS _status, address _address) external returns(bool);
    function disable(STATUS _status, address _address) external returns(bool);
    function indexInRegistry(address _address, STATUS _status) external view returns (bool, uint256);
    function orderTimelock(STATUS _status, address _address) external;
    function execute(uint256 _index) external returns(bool);
    function nullify(uint256 _index) external returns(bool);
    function enableTimelock() external;
    function disableTimelock() external;
    function baseSupply() external view returns (uint256);

}
