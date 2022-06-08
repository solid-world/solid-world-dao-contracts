// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Permit.sol";
import "./lib/ERC20Permit.sol";

/**
 * @title CT ERC-20 Token Template
 * @author Solid World DAO
 * @notice CT Token ERC-20 Template
 */
contract CTERC20TokenTemplate is ERC20Permit, ISCT {

    constructor(address _treasury, string memory _name, string memory _symbol) {
        ERC20("CT", "CT", 18);
        ERC20Permit("CT");
    }    

    function mint(address account_, uint256 amount_) external override onlyVault {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external override {
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
