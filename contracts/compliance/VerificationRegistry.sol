// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./KYCRegistry.sol";
import "./Blacklist.sol";
import "../interfaces/compliance/IVerificationRegistry.sol";

/// @author Solid World
contract VerificationRegistry is
    Initializable,
    OwnableUpgradeable,
    IVerificationRegistry,
    Blacklist,
    KYCRegistry
{
    function initialize(address owner) public initializer {
        __Ownable_init();
        transferOwnership(owner);
    }
}
