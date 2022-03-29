// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISCTCarbonTreasury {

    enum STATUS {
        RESERVETOKEN,
        RESERVEMANAGER
    }

    struct Order {
        STATUS managing;
        address toPermit;
        uint256 timelockEnd;
        bool nullify;
        bool executed;
    }

    struct CarbonProject {
        address token;
        uint256 tokenId;
        uint256 tons;
        bool isActive;
    }

    struct CarbonProjectInfo {
        address token;
        uint256 tokenId;
        uint256 flatRate;
        uint256 sdgPremium;
        uint256 daysToRealization;
        uint256 closenessPremium;
        bool isCertified;
        bool isRedeemed;
    }

    function initialize() external;
    function deposit(address _token, uint256 _tokenId, uint256 _amount,address _owner) external returns(bool);
    function sell(address _token, uint256 _tokenId, uint256 _amount, uint256 _totalValue, address _buyer) external returns(bool);
    function setCarbonProjectInfo(CarbonProjectInfo memory _carbonProjectInfo) external returns(bool)
    function enable(STATUS _status, address _address) external returns(bool);
    function disable(STATUS _status, address _address) external returns(bool);
    function indexInRegistry(address _address, STATUS _status) external view returns (bool, uint256);
    function orderTimelock(STATUS _status, address _address) external;
    function execute(uint256 _index) external returns(bool);
    function nullify(uint256 _index) external returns(bool);
    function disableTimelock() external;
    function baseSupply() external view returns (uint256);
    
}