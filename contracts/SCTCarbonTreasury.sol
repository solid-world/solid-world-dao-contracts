// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./lib/SolidDaoManaged.sol";
import "./lib/ERC1155Receiver.sol";
import "./interfaces/ISCT.sol";
import "./interfaces/IERC1155.sol";

/**
 * @title SCT Carbon Treasury
 * @author Solid World DAO
 * @notice SCT Carbon Credits Treasury
 */
contract SCTCarbonTreasury is SolidDaoManaged, ERC1155Receiver {

    event Deposited(address indexed token, uint256 indexed tokenId, address indexed owner, uint256 amount);
    event ApprovedSell(address indexed token, uint256 indexed tokenId, address owner, uint256 amount, uint256 totalValue);
    event Sold(address indexed token, uint256 indexed tokenId, address indexed owner, address buyer, uint256 amount, uint256 totalValue));
    event UpdatedInfo(address indexed token, uint256 indexed tokenId, bool isActive);
    event Permissioned(STATUS indexed status, address token, bool result);
    event PermissionOrdered(STATUS indexed status, address token);

    struct CarbonProject {
        address token;
        uint256 tokenId;
        uint256 tons;
        uint256 flatRate;
        uint256 sdgPremium;
        uint256 daysToRealization;
        uint256 closenessPremium;
        bool isActive;
        bool isCertified;
        bool isRedeemed;
    }

    struct SaleApproval {
        uint256 amount;
        uint256 totalValue;
    }

    ISCT public immutable SCT;
    
    uint256 public totalReserves;

    mapping(address => mapping(uint256 => mapping(address => uint256))) public carbonProjectBalances;
    mapping(address => mapping(uint256 => mapping(address => SaleApproval))) public saleApprovals;
    mapping(address => mapping(uint256 => CarbonProject)) public carbonProjects; 

    /**
     * @title STATUS
     * @notice enum of permisions types
     * @dev 0 RESERVETOKEN
     * @dev 1 RESERVEMANAGER
     */

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
        uint256 _timelock
    ) SolidDaoManaged(ISolidDaoManagement(_authority)) {
        require(_sct != address(0), "SCT Treasury: invalid SCT address");
        SCT = ISCT(_sct);
        timelockEnabled = false;
        initialized = false;
        blocksNeededForOrder = _timelock;
    }

    /**
     * @notice enables timelocks after initilization
     */
    function initialize() external onlyGovernor {
        require(!initialized, "SCT Treasury: already initialized");
        timelockEnabled = true;
        initialized = true;
    }

    /**
     * @notice depositReserveToken
     * @notice function to deposit reserve token in treasury and mint SCT to _owner
     * @dev this function update _owner carbonProjectBalances
     * @dev require: only permitted reserve tokens are accepted
     * @dev require: only active carbon projects are accepted
     * @dev require: owner ERC1155 (_token, _tokenId) balance needs to be more or equal than _amount
     * @dev require: owner_ need to allow this contract spend ERC1155 first
     * @param _token address
     * @param _tokenId unint256
     * @param _amount unint256
     * @param _owner address
     * @return true
     */
    function depositReserveToken(
        address _token,
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external returns (bool) {
        require(permissions[STATUS.RESERVETOKEN][_token], "SCT Treasury: reserve token not permitted");
        require(carbonProjects[_token][_tokenId].isActive, "SCT Treasury: carbon project not active");
        require((IERC1155(_token).balanceOf(_owner, _tokenId)) >= _amount, "SCT Treasury: owner insuficient ERC1155 balance");
        require((IERC1155(_token).isApprovedForAll(_owner, address(this))) , "SCT Treasury: owner not approved this contract spend ERC1155");

        IERC1155(_token).safeTransferFrom(
            _owner, 
            address(this), 
            _tokenId, 
            _amount, 
            "data"
        );

        SCT.mint(_owner, _amount);

        carbonProjectBalances[_token][_tokenId][_owner] += _amount;
        totalReserves += _amount;

        emit Deposited(_token, _tokenId, _owner, _amount);
        return true;
    }

    /**
     * @notice approveReserveTokenSell
     * @notice function to approve a sale of some _amount of deposited Carbon Credits
     * @dev to remove previous or unused sale approval the owner need call this function again and set _amount to zero
     * @dev require: only active carbon projects are accepted
     * @dev require: msg.sender/owner deposited Carbon Credits balance needs to be equal or less than _amount
     * @dev require: SCT _totalValue needs to be equal or more than Carbon Credits _amount
     * @param _token address
     * @param _tokenId unint256
     * @param _amount unint256: amount of msg.sender Carbon Credits deposited in contract for sale
     * @param _totalValue unint256: amount of SCT to be paid by buyer
     * @return true
     */
    function approveReserveTokenSell(
        address _token,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _totalValue
    ) external returns (bool) {
        require(carbonProjects[_token][_tokenId].isActive, "SCT Treasury: carbon project not active");
        require(carbonProjectBalances[_token][_tokenId][msg.sender]  >= _amount, "SCT Treasury: msg.sender ERC1155 deposited balance insuficient");
        require(_totalValue >= _amount, "SCT Treasury: SCT total value needs to be more or equal than ERC1155 amount");

        saleApprovals[_token][_tokenId][msg.sender] = SaleApproval(_amount, _totalValue);

        emit ApprovedSell(_token, _tokenId, _owner, _amount, _totalValue);
        return true;
    }

    /**
     * @notice buyReserveToken
     * @notice function to buy with SCT approved amount of Carbon Credits
     * @dev for security reasons, it is necessary the _owner/seller approve same _amount and _totalValue of the sale at approveReserveTokenSell function
     * @dev this function burn the same _amount of SCT from msg.sender/buyer, set _owner sale approve amount and total value to zero and update _owner carbonProjectBalances
     * @dev require: only active carbon projects are accepted
     * @dev require: only approved token sale can be executed by this function
     * @dev require: _owner deposited Carbon Credits balance needs to be equal or less than _amount
     * @dev require: msg.sender/buyer need to approve this smart contract spend sct first
     * @param _token address
     * @param _tokenId unint256
     * @param _owner address
     * @param _amount unint256: amount of _owner Carbon Credits deposited in contract to sell
     * @param _totalValue unint256: amount of SCT to be paid by _buyer
     * @return true     
     */
    function buyReserveToken(
        address _token,
        uint256 _tokenId,
        address _owner,
        uint256 _amount,
        uint256 _totalValue
    ) external returns (bool) {
        require(carbonProjects[_token][_tokenId].isActive, "SCT Treasury: carbon project not active");
        require(saleApprovals[_token][_tokenId][_owner].amount  == _amount, "SCT Treasury: incorrect ERC1155 amount sale approved");
        require(saleApprovals[_token][_tokenId][_owner].totalValue  == _totalValue, "SCT Treasury: incorrect SCT total value sale approved");
        require(carbonProjectBalances[_token][_tokenId][_owner]  >= _amount, "SCT Treasury: owner ERC1155 deposited balance insuficient");
        require((SCT.allowance(msg.sender, address(this))) >= _totalValue, "SCT Treasury: msg.sender not allowed this contract spend SCT");

        carbonProjectBalances[_token][_tokenId][_owner] -= _amount;
        saleApprovals[_token][_tokenId][_owner].amount = 0;
        saleApprovals[_token][_tokenId][_owner].totalValue = 0;
        totalReserves -= _amount;

        SCT.burnFrom(msg.sender, _amount);

        if(_totalValue - _amount > 0) {
            SCT.transferFrom(msg.sender, _owner, _totalValue - _amount);
        }
        
        IERC1155(_token).safeTransferFrom( 
            address(this), 
            msg.sender,
            _tokenId, 
            _amount, 
            "data"
        );

        emit Sold(_token, _tokenId, _owner, msg.sender, _amount, _totalValue);
        return true;
    }

    /**
     * @notice createOrUpdateCarbonProject
     * @notice function to create or update carbon project
     * @dev require: only permitted reserve manager can call this function
     * @dev require: only permitted reserve tokens are accepted
     * @param _carbonProject CarbonProject
     * @return true
     */
    function createOrUpdateCarbonProject(CarbonProject memory _carbonProject) external returns (bool) {
        require(permissions[STATUS.RESERVEMANAGER][msg.sender], "SCT Treasury: reserve manager not permitted");
        require(permissions[STATUS.RESERVETOKEN][_carbonProject.token], "SCT Treasury: reserve token not permitted");

        carbonProjects[_carbonProject.token][_carbonProject.tokenId] = _carbonProject;

        emit UpdatedInfo(_carbonProject.token, _carbonProject.tokenId, _carbonProject.isActive);
        return true;
    }

    /**
     * @notice enable
     * @notice function to enable permission
     * @dev only governor can call this function
     * @dev timelock needs to be disabled
     * @dev if timelock is enable use orderTimelock function
     * @param _status STATUS
     * @param _address address
     */
    function enable(
        STATUS _status,
        address _address
    ) external onlyGovernor returns(bool) {
        require(!timelockEnabled, "SCT Treasury: timelock enabled");

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
        require(_address != address(0), "SCT Treasury: invalid address");
        require(timelockEnabled, "SCT Treasury: timelock is disabled, use enable");

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
        require(timelockEnabled, "SCT Treasury: timelock is disabled, use enable");

        Order memory info = permissionOrder[_index];

        require(!info.nullify, "SCT Treasury: order has been nullified");
        require(!info.executed, "SCT Treasury: order has already been executed");
        require(block.number >= info.timelockEnd, "SCT Treasury: timelock not complete");

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
        require(timelockEnabled, "SCT Treasury: timelock already disabled");
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