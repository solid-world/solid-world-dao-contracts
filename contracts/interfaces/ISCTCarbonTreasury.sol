// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISCTCarbonTreasury {

    enum STATUS {
        RESERVETOKEN,
        RESERVEMANAGER
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

    struct SaleApproval {
        uint256 amount;
        uint256 totalValue;
    }

    event Deposited(address indexed token, uint256 indexed tokenId, address indexed owner, uint256 amount);
    event ApprovedSell(address indexed token, uint256 indexed tokenId, address owner, uint256 amount, uint256 totalValue);
    event Sold(address indexed token, uint256 indexed tokenId, address indexed owner, address buyer, uint256 amount, uint256 totalValue);
    event UpdatedInfo(address indexed token, uint256 indexed tokenId, bool isActive);
    event Permissioned(STATUS indexed status, address token, bool result);
    event PermissionOrdered(STATUS indexed status, address token);

    function initialize() external;
    function depositReserveToken(address _token, uint256 _tokenId, uint256 _amount,address _owner) external returns(bool);
    function approveReserveTokenSell(address _token, uint256 _tokenId, uint256 _amount, uint256 _totalValue) external returns(bool);
    function buyReserveToken(address _token, uint256 _tokenId, address _owner, uint256 _amount, uint256 _totalValue) external returns(bool);
    function createOrUpdateCarbonProject(CarbonProject memory _carbonProject) external returns(bool)
    function enable(STATUS _status, address _address) external returns(bool);
    function disable(STATUS _status, address _address) external returns(bool);
    function indexInRegistry(address _address, STATUS _status) external view returns (bool, uint256);
    function orderTimelock(STATUS _status, address _address) external;
    function execute(uint256 _index) external returns(bool);
    function nullify(uint256 _index) external returns(bool);
    function disableTimelock() external;
    function baseSupply() external view returns (uint256);
    
}