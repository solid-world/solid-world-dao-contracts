// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/ISolidDaoManagement.sol";

/**
 * @title Solid Dao Managed
 * @author Solid World DAO
 * @notice Abstract contratc to implement Solid Dao Management and access control modifiers
 */
abstract contract SolidDaoManaged {

    /**
    * @dev Emitted on setAuthority()
    * @param authority Address of Solid Dao Management smart contract
    **/
    event AuthorityUpdated(ISolidDaoManagement indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED";

    ISolidDaoManagement public authority;

    constructor(ISolidDaoManagement _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /**
    * @notice Function modifier that can be used in other smart contracts
    * @dev Only governor address can call functions marked by this modifier
    **/
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    /**
    * @notice Function modifier that can be used in other smart contracts
    * @dev Only guardian address can call functions marked by this modifier
    **/
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    /**
    * @notice Function modifier that can be used in other smart contracts
    * @dev Only policy address can call functions marked by this modifier
    **/
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    /**
    * @notice Function modifier that can be used in other smart contracts
    * @dev Only vault address can call functions marked by this modifier
    **/
    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /**
    * @notice Function to set and update Solid Dao Management smart contract address
    * @dev Emit AuthorityUpdated event
    * @param _newAuthority Address of the new Solid Dao Management smart contract
    */
    function setAuthority(ISolidDaoManagement _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}
