// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./lib/SolidDaoManaged.sol";
import "./lib/ERC1155Receiver.sol";
import "./interfaces/ISCT.sol";
import "./interfaces/IERC1155.sol";

/**
 * @title Carbon Treasury
 * @author Solid World DAO
 * @notice Carbon Project Treasury
 */
contract CarbonTreasury is SolidDaoManaged, ERC1155Receiver {

    event Deposit(address indexed token, uint256 indexed tokenId, address fromAddress, uint256 amount);
    event Withdrawal(address indexed token, uint256 indexed tokenId, address toAddress, uint256 amount);
    event PermissionOrdered(STATUS indexed status, address ordered);
    event Permissioned(STATUS indexed status, address addr, bool result);

    /**
     * @title STATUS
     * @notice enum of permisions types
     * @dev 0 RESERVETOKEN,
            1 RESERVEDEPOSITOR,
            2 RESERVESPENDER
     */

    enum STATUS {
        RESERVETOKEN,
        RESERVEDEPOSITOR,
        RESERVESPENDER
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
        bool isWithdrawed;
        address owner;

        //TODO: Confirm if these variables are unique for each project and need to be here or in carbon queue
        //uint256 flatRate;
        //uint256 sdgPremium;
        //uint256 daysToRealization;
        //uint256 closenessPremium;

        //TODO: confirm if certified and redeemed variables are used in this contract
        // bool isCertified;
        // bool isRedeemed;
    }

    ISCT public immutable SCT;
    
    uint256 public totalReserves;

    mapping(address => mapping(uint256 => CarbonProject)) public carbonProjects; 

    mapping(STATUS => address[]) public registry;
    mapping(STATUS => mapping(address => bool)) public permissions;
    Order[] public permissionOrder;
    uint256 public immutable blocksNeededForOrder;

    bool public timelockEnabled;
    bool public initialized;
    
    uint256 public onChainGovernanceTimelock;

    constructor(
        address _sct,
        uint256 _timelock,
        address _authority
    ) SolidDaoManaged(ISolidDaoManagement(_authority)) {
        require(_sct != address(0), "Carbon Treasury: invalid SCT address");
        SCT = ISCT(_sct);
        timelockEnabled = false;
        initialized = false;
        blocksNeededForOrder = _timelock;
    }

    /**
     * @notice enables timelocks after initilization
     */
    function initialize() external onlyGovernor {
        require(!initialized, "Carbon Treasury: already initialized");
        timelockEnabled = true;
        initialized = true;
    }

    /**
     * @notice deposit
     * @notice function to allow approved address to deposit an asset for SCT
     * @dev only reserve depositor can call this function
     * @param _token address
     * @param _amount uint256
     * @param _owner address
     * @return _amount uint256
     */
    function deposit(
        address _token,
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external returns (uint256) {
        require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], "Carbon Treasury: reserve depositor not approved");
        require(permissions[STATUS.RESERVETOKEN][_token], "Carbon Treasury: reserve token not approved");
        require(!carbonProjects[_token][_tokenId].isActive, "Carbon Treasury: invalid carbon project");

        IERC1155(_token).safeTransferFrom(
            _owner, 
            address(this), 
            _tokenId, 
            _amount, 
            "data"
        );

        SCT.mint(_owner, _amount);

        totalReserves += _amount;
        carbonProjects[_token][_tokenId] = CarbonProject(_token, _tokenId, _amount, true, false, _owner);

        emit Deposit(_token, _tokenId, _owner, _amount);
        return(_amount);
    }

    /**
     * @notice withdraw
     * @notice function to allow approved address to withdraw Carbon Project tokens
     * @dev only reserve spender can call this function
     * @param _token address
     * @param _tokenId unint256
     * @param _toAddress address
     */
    function withdraw(
        address _token,
        uint256 _tokenId,
        address _toAddress
    ) external returns (uint256) {
        require(permissions[STATUS.RESERVESPENDER][msg.sender], "Carbon Treasury: reserve spender not approved");
        require(permissions[STATUS.RESERVETOKEN][_token], "Carbon Treasury: reserve token not approved");
        require(carbonProjects[_token][_tokenId].isActive, "Carbon Treasury: invalid carbon project");
        require(!carbonProjects[_token][_tokenId].isWithdrawed, "Carbon Treasury: carbon project withdrawed");

        uint256 withdrawAmount = carbonProjects[_token][_tokenId].tons;
        totalReserves -= withdrawAmount;
        carbonProjects[_token][_tokenId].isWithdrawed = true;
        
        IERC1155(_token).safeTransferFrom( 
            address(this), 
            _toAddress,
            _tokenId, 
            withdrawAmount, 
            "data"
        );

        emit Withdrawal(_token, _tokenId, _toAddress, withdrawAmount);
        return(withdrawAmount);
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
        require(timelockEnabled == false, "Carbon Treasury: use orderTimelock");

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
        require(_address != address(0), "Carbon Treasury: invalid address");
        require(timelockEnabled, "Carbon Treasury: timelock is disabled, use enable");

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
        require(timelockEnabled, "Carbon Treasury: timelock is disabled, use enable");

        Order memory info = permissionOrder[_index];

        require(!info.nullify, "Carbon Treasury: order has been nullified");
        require(!info.executed, "Carbon Treasury: order has already been executed");
        require(block.number >= info.timelockEnd, "Carbon Treasury: timelock not complete");

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
        require(timelockEnabled, "Carbon Treasury: timelock already disabled");
        if (onChainGovernanceTimelock != 0 && onChainGovernanceTimelock <= block.number) {
            timelockEnabled = false;
        } else {
            onChainGovernanceTimelock = block.number + (blocksNeededForOrder * 7);
        }
    }

    //NOTE: mint or burn SCT in this contract?

    //NOTE: Are there other management functions? manage tokens, edit projects, etc

    //NOTE: implement token value in this contract?
    //function tokenValue(address _token, address _tokenId, uint256 _amount) external view returns (uint256);

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