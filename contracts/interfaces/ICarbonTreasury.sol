// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICarbonTreasury {

    function initialize() external;
    function deposit( address _token, uint256 _tokenId, uint256 _amount, address _owner) external returns(uint256);
    function withdraw(address _token, uint256 _tokenId, address _toAddress) external returns(uint256);
    function enable(ISTATUS _status, address _address) external returns(bool);
    function disable(ISTATUS _status, address _address) external returns(bool);
    function indexInRegistry(address _address, ISTATUS _status) external view returns (bool, uint256);
    function orderTimelock(STATUS _status, address _address) external;
    function execute(uint256 _index) external returns(bool);
    function nullify(uint256 _index) external returns(bool);
    function disableTimelock() external;
    function baseSupply() external view returns (uint256);
    
}