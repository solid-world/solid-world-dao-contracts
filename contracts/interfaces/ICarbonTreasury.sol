// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICarbonTreasury {

    enum ISTATUS {
        RESERVETOKEN,
        RESERVEDEPOSITOR,
        RESERVESPENDER
    }

    struct ICarbonProject {
        address token;
        uint256 tokenId;
        uint256 tons;
        bool isActive;
        bool isWithdrawed;

        //TODO: Confirm if these variables are unique for each project
        //uint256 flatRate;
        //uint256 sdgPremium;
        //uint256 daysToRealization;
        //uint256 closenessPremium;

        //TODO: confirm if certified and redeemed variables are used in this contract
        // bool isCertified;
        // uint256 dateOfCertification;
        // bool isRedeemed;

        //TODO: confirm if owner address is used in this contract
        //address owner;
    }

    //event Deposit(address indexed token, uint256 indexed tokenId, address fromAddress, uint256 amount);
    //event Withdrawal(address indexed token, uint256 indexed tokenId, address toAddress, uint256 amount);
    //event PermissionOrder(ISTATUS indexed status, address ordered);
    //event Permissioned(ISTATUS indexed status, address addr, bool result);
    
    function initialize() external;
    function deposit(address _token, bool _erc1155, ICarbonProject memory _carbonProject) external returns(uint256);
    function withdraw(address _token, bool _erc1155, uint256 _tokenId, address _toAddress) external returns(uint256);
    function enable(ISTATUS _status, address _address) external returns(bool);
    function disable(ISTATUS _status, address _address) external returns(bool);
    function indexInRegistry(address _address, ISTATUS _status) external view returns (bool, uint256);
    //function queueTimelock(STATUS _status, address _address) external;
    //function execute(uint256 _index) external;
    //function nullify(uint256 _index) external;
    function disableTimelock() external;
    //function carbonProject(address _token, address _tokenId) external view returns (CarbonProject);
    //function tokenValue(address _token, address _tokenId, uint256 _amount) external view returns (uint256);
    //function baseSupply() external view returns (uint256);
    
}