// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Permit.sol";
import "./lib/ERC20Permit.sol";

/**
 * @title CT ERC-20 Token Template
 * @author Solid World DAO
 * @notice CT Token ERC-20 Template
 */
contract CTERC20TokenTemplate is ERC20Permit {

    // Treasury that manages this Token
    address public treasury;

    // Contract deployer
    address public deployer;

    // Is the Treasury initalized
    bool public isInitialized;

    // @notice: This modifier allows only the Treasury of the token perform the operation
    modifier onlyTreasury() {
        require(isInitialized, "Token needs to be initialized");
        require(msg.sender == treasury, "Only Treasury can perform this operation");
        _;
    }

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, 18) ERC20Permit(_name) {
        deployer = msg.sender;
    }    


    // @notice: After Token and Tresury have been deployed the Deployer need to initialize the Token informing 
    // which Treasury is going to manage him.
    function initialize(address _treasury) external {
        require(deployer == msg.sender, "Only Deployer must initialize the token");
        require(!isInitialized, "Token already has been initialized");
        treasury = _treasury;
        isInitialized = true;
    }

    function mint(address account_, uint256 amount_) external onlyTreasury {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 senderAllowance = allowance(account_, msg.sender);
        require(senderAllowance - amount_ >= 0, "ERC20: burn amount exceeds allowance");
        senderAllowance -= amount_;
        _approve(account_, msg.sender, senderAllowance);
        _burn(account_, amount_);
    }
}
