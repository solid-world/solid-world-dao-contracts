// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICarbonTreasury {

    struct CarbonProject {
        address token;
        uint256 tokenId;
        uint256 tons;
        uint256 flatRate;
        uint256 sdgPremium;
        uint256 daysToRealization;
        uint256 closenessPremium;
        bool isCertified;
        bool isRedeemed;
        bool isActive;
        bool isWithdrawed;
        address owner;
    }

    function initialize() external;
    function deposit(CarbonProject _carbonProject) external returns(uint256);
    function withdraw(address _token, uint256 _tokenId, address _toAddress) external returns(uint256);
    function enable(STATUS _status, address _address) external returns(bool);
    function disable(STATUS _status, address _address) external returns(bool);
    function indexInRegistry(address _address, STATUS _status) external view returns (bool, uint256);
    function orderTimelock(STATUS _status, address _address) external;
    function execute(uint256 _index) external returns(bool);
    function nullify(uint256 _index) external returns(bool);
    function disableTimelock() external;
    function baseSupply() external view returns (uint256);
    
}