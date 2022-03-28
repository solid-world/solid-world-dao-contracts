// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./lib/SolidDaoManaged.sol";
import "./lib/ERC1155Receiver.sol";
import "./interfaces/ISCT.sol";
import "./interfaces/IERC1155.sol";

/**
 * @title SCT Carbon Treasury
 * @author Solid World DAO
 * @notice Carbon Project Treasury
 */
contract SCTCarbonTreasury is SolidDaoManaged, ERC1155Receiver {

    event Deposited(address indexed token, uint256 indexed tokenId, address fromAddress, uint256 amount);
    event Selled(address indexed token, uint256 indexed tokenId, address toAddress, uint256 amount);
    event Permissioned(STATUS indexed status, address addr, bool result);
    event PermissionOrdered(STATUS indexed status, address ordered);

    /**
     * @title STATUS
     * @notice enum of permisions types
     * @dev 0 RESERVETOKEN,
     */

    enum STATUS {
        RESERVETOKEN
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

    //NOTE: other struct to store info?
    // struct CarbonProjectInfo {
    //     address token;
    //     uint256 tokenId;
    //     uint256 flatRate;
    //     uint256 sdgPremium;
    //     uint256 daysToRealization;
    //     uint256 closenessPremium;
    //     bool isCertified;
    // }

    ISCT public immutable SCT;
    
    uint256 public totalReserves;
    mapping(address => mapping(uint256 => mapping(address => uint256))) public carbonProjectBalances;
    mapping(address => mapping(uint256 => CarbonProject)) public carbonProjects; 
    //mapping(address => mapping(uint256 => CarbonProjectInfo)) public carbonProjectInfos; 

    mapping(STATUS => address[]) public registry;
    mapping(STATUS => mapping(address => bool)) public permissions;
    Order[] public permissionOrder;
    uint256 public immutable blocksNeededForOrder;

    bool public timelockEnabled;
    bool public initialized;
    
    uint256 public onChainGovernanceTimelock;

    constructor(
        address _authority,
        address _sct,
        uint256 _timelock,
    ) SolidDaoManaged(ISolidDaoManagement(_authority)) {
        require(_sct != address(0), "SCT Carbon Treasury: invalid SCT address");
        SCT = ISCT(_sct);
        timelockEnabled = false;
        initialized = false;
        blocksNeededForOrder = _timelock;
    }

    /**
     * @notice enables timelocks after initilization
     */
    function initialize() external onlyGovernor {
        require(!initialized, "SCT Carbon Treasury: already initialized");
        timelockEnabled = true;
        initialized = true;
    }

    /**
     * @notice deposit
     * @notice function to deposit an asset for SCT
     * @dev only reserve tokens are accepted
     * @dev depositor/owner need to allow this contract spend ERC1155 first
     * @param _token address
     * @param _tokenId unint256
     * @param _amount unint256
     * @param _owner address
     * @return true
     */
    function deposit(
        address _token,
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external returns (bool) {
        require(permissions[STATUS.RESERVETOKEN][_carbonProject.token], "SCT Carbon Treasury: reserve token not permitted");
        require(IERC1155(_token).isApprovedForAll(_owner, address(this)) , "SCT Carbon Treasury: owner not allowed this contract spend ERC1155 tokens");

        IERC1155(_token).safeTransferFrom(
            _owner, 
            address(this), 
            _tokenId, 
            _amount, 
            "data"
        );

        SCT.mint(_owner, _amount);

        totalReserves += _amount;
        carbonProjectBalances[_token][_tokenId][_owner] += _amount;

        carbonProjects[_token][_tokenId].token = _token;
        carbonProjects[_token][_tokenId].tokenId = _tokenId;
        carbonProjects[_token][_tokenId].tons += _amount;
        carbonProjects[_token][_tokenId].isActive = true;

        emit Deposited(_token, _tokenId, _owner, _amount);
        return true;
    }

    /**
     * @notice sell
     * @notice function to sell msg.sender deposited Carbon Credits to _buyer
     * @dev only owner can call this function
     * @dev _buyer need to approve this smart contract spend sct first
     * @dev deposited Carbon Credits balance of the msg.sender needs to be equal or less than _amount
     * @dev SCT _totalValue needs to be equal or more than Carbon Credits _amount
     * @param _token address
     * @param _tokenId unint256
     * @param _amount unint256: amount of msg.sender Carbon Credits deposited in contract to sell
     * @param _totalValue unint256: amount of SCT to be paid by _buyer
     * @param _buyer address
     */
    function sell(
        address _token,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _totalValue,
        address _buyer
    ) external returns (uint256) {
        require(permissions[STATUS.RESERVETOKEN][_token], "SCT Carbon Treasury: reserve token not permitted");
        require(carbonProjectBalances[_token][_tokenId][msg.sender] >= _amount, "SCT Carbon Treasury: seller ERC1155 balance insuficient");
        require((SCT.allowance(msg.sender, address(this))) >= _totalValue), "SCT Carbon Treasury: buyer not allowed this contract spend SCT");
        require(_totalValue >= _amount, "Carbon Trasury: SCT total value needs to be more or equal of ERC1155 amount")

        carbonProjectBalances[_token][_tokenId][_owner] -= _amount;
        totalReserves -= _amount;
        carbonProjects[_token][_tokenId].tons -= _amount;

        if(carbonProjects[_token][_tokenId].tons == 0) {
            carbonProjects[_token][_tokenId].isActive = false;
        }

        SCT.burnFrom(_buyer, _amount);

        SCT.safeTransferFrom(_buyer, msg.sender, _totalValue - _amount);
        
        IERC1155(_token).safeTransferFrom( 
            address(this), 
            _buyer,
            _tokenId, 
            _amount, 
            "data"
        );

        emit Selled(_token, _tokenId, _buyer, _amount);
        return(_amount);
    }

    /**
     * @notice enable
     * @notice function to enable permission
     * @dev only governor can call this function
     * @param _status STATUS
     * @param _address address
     */
    function enable(
        STATUS _status,
        address _address
    ) external onlyGovernor returns(bool) {
        require(timelockEnabled == false, "SCT Carbon Treasury: use orderTimelock");

        permissions[_status][_address] = true;
        (bool registered, ) = indexInRegistry(_address, _status);
        if (!registered) {
            registry[_status].push(_address);
        }

        emit Permissioned(_status, _address, true);
        return true;
    }

    /**
     * @notice disable
     * @notice function to disable permission
     * @dev only governor can call this function
     * @param _status STATUS
     * @param _address address
     */
    function disable(
        STATUS _status, 
        address _address
    ) external onlyGovernor returns(bool) {

        permissions[_status][_address] = false;

        emit Permissioned(_status, _address, false);
        return true;
    }

    /**
     * @notice indexInRegistry
     * @notice view function to check if registry contains address
     * @return (bool, uint256)
     */
    function indexInRegistry(address _address, STATUS _status) public view returns (bool, uint256) {
        address[] memory entries = registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @notice orderTimelock
     * @notice function to create order for address receive permission
     * @dev only governor can call this function
     * @param _status STATUS
     * @param _address address
     */
    function orderTimelock(
        STATUS _status,
        address _address
    ) external onlyGovernor returns(bool) {
        require(_address != address(0), "SCT Carbon Treasury: invalid address");
        require(timelockEnabled, "SCT Carbon Treasury: timelock is disabled, use enable");

        uint256 timelock = block.number + blocksNeededForOrder;
        permissionOrder.push(
            Order({
                managing: _status, 
                toPermit: _address, 
                timelockEnd: timelock, 
                nullify: false, 
                executed: false
            })
        );

        emit PermissionOrdered(_status, _address);
        return true;
    }

    /**
     * @notice execute
     * @notice function to enable ordered permission
     * @dev only governor can call this function
     * @param _index uint256
     */
    function execute(uint256 _index) external onlyGovernor returns(bool) {
        require(timelockEnabled, "SCT Carbon Treasury: timelock is disabled, use enable");

        Order memory info = permissionOrder[_index];

        require(!info.nullify, "SCT Carbon Treasury: order has been nullified");
        require(!info.executed, "SCT Carbon Treasury: order has already been executed");
        require(block.number >= info.timelockEnd, "SCT Carbon Treasury: timelock not complete");

        permissions[info.managing][info.toPermit] = true;
        (bool registered, ) = indexInRegistry(info.toPermit, info.managing);
        if (!registered) {
            registry[info.managing].push(info.toPermit);
        }
        permissionOrder[_index].executed = true;

        emit Permissioned(info.managing, info.toPermit, true);
        return true;
    }

    /**
     * @notice nullify
     * @notice function to cancel timelocked order
     * @dev only governor can call this function
     * @param _index uint256
     */
    function nullify(uint256 _index) external onlyGovernor returns(bool) {
        permissionOrder[_index].nullify = true;
        return true;
    }

    /**
     * @notice disableTimelock
     * @notice function to disable timelocke
     * @dev only governor can call this function
     */
    function disableTimelock() external onlyGovernor {
        require(timelockEnabled, "SCT Carbon Treasury: timelock already disabled");
        if (onChainGovernanceTimelock != 0 && onChainGovernanceTimelock <= block.number) {
            timelockEnabled = false;
        } else {
            onChainGovernanceTimelock = block.number + (blocksNeededForOrder * 7);
        }
    }

    /**
     * @notice baseSupply
     * @notice view function that returns SCT total supply
     * @return uint256
     */
    function baseSupply() external view returns (uint256) {
        return SCT.totalSupply();
    }

    /**
     * @notice onERC1155Received
     * @notice virtual function to allow contract accept ERC1155 tokens
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @notice onERC1155BatchReceived
     * @notice virtual function to allow contract accept ERC1155 tokens
     */
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}