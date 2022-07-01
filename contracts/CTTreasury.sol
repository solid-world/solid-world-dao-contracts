// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./lib/SolidDaoManaged.sol";
import "./lib/ERC1155Receiver.sol";
import "./lib/SolidMath.sol";
import "./interfaces/ICT.sol";
import "./interfaces/IERC1155.sol";

/**
 * @title Carbon Token Treasury (CTTTreasury) Template
 * @author Solid World DAO
 * @notice CT Treasury Template
 */
contract CTTreasury is SolidDaoManaged, ERC1155Receiver, SolidMath {

    /**
     * @notice CarbonProject
     * @dev struct to store carbon project details
     * @param token: ERC1155 smart contract address 
     * @param tokenId: ERC1155 carbon project token id
     * @param tons: total amount of carbon project tokens
     * @param contractExpectedDueDate: the carbon credit contract expected due date to be informed in seconds
     * @param projectDiscountRate: fee that will be charged from the investor when commodify the project
     * @param isActive: boolean status of carbon project in this smart contract
     * @param isCertified: boolean verra status of carbon project certificate
     * @param isRedeemed: boolean status of carbon project redeem
     */
    struct CarbonProject {
        address token;
        uint256 tokenId;
        uint256 tons;
        uint256 contractExpectedDueDate;
        uint256 projectDiscountRate;
        bool isActive;
        bool isCertified;
        bool isRedeemed;
    }

    /**
     * @notice Order
     * @dev struct to store orders created on the timelock
     * @param managing: STATUS enum to be enabled
     * @param toPermit: address to recieve permision
     * @param timelockEnd: due date of the order in blocks
     * @param nullify: boolean to verify if the order is null
     * @param executed: boolean to verify if the order is executed
     */
    struct Order {
        STATUS managing;
        address toPermit;
        uint256 timelockEnd;
        bool nullify;
        bool executed;
    }   

    /**
     * @notice STATUS
     * @dev enum of permisions types
     * @dev 0 RESERVETOKEN
     * @dev 1 RESERVEMANAGER
     */
    enum STATUS {
        RESERVETOKEN,
        RESERVEMANAGER
    }
    
    event Deposited(address indexed token, uint256 indexed tokenId, address indexed owner, uint256 amount);
    event Sold(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed owner, address buyer, uint256 amount, uint256 totalValue);
    event UpdatedInfo(address indexed token, uint256 indexed tokenId, bool isActive);
    event ChangedTimelock(bool timelock);
    event SetOnChainGovernanceTimelock(uint256 blockNumber);
    event Permissioned(STATUS indexed status, address token, bool result);
    event PermissionOrdered(STATUS indexed status, address token, uint256 index);


    /**
     * @notice ERC-20 Carbon Token address 
     * @dev immutable variable to store CT ERC20 token address
     * @return address
     */
    ICT public immutable CT;

    /**
     * @notice category of the Carbon Project this treasury manages
     * @dev variable to store the name of the category this contract manages. This is for info purposes.
     * @return string
    */
    string public category;
    
    /**
     * @notice totalReserves
     * @dev variable to store SCT ERC20 token address
     * @return uint256
     */
    uint256 public totalReserves;

    /**
     * @notice carbonProjects
     * @dev mapping with token and tokenId as keys to store CarbonProjects
     * @dev return CarbonProject
     */
    mapping(address => mapping(uint256 => CarbonProject)) public carbonProjects; 

    /**
     * @notice carbonProjectTons
     * @dev mapping with token and tokenId as keys to store total amount of ERC1155 carbon project deposited in this contract
     * @return uint256
     */
    mapping(address => mapping(uint256 => uint256)) public carbonProjectTons;

    /**
     * @notice carbonProjectBalances
     * @dev mapping with token, tokenId and owner address as keys to store the amount of each ERC1155 carbon project owner deposited
     * @return uint256
     */
    mapping(address => mapping(uint256 => mapping(address => uint256))) public carbonProjectBalances;

    /**
     * @notice registry
     * @dev mapping with STATUS as key to store an array of addresses
     * @return array of addresses
     */
    mapping(STATUS => address[]) public registry;

    /**
     * @notice permissions
     * @dev mapping with STATUS and address as keys to store status of permisions
     * @return bool
     */
    mapping(STATUS => mapping(address => bool)) public permissions;

    /**
     * @notice permissionOrder
     * @dev array of Orders
     * @dev return Order[]
     */
    Order[] public permissionOrder;
    
    /**
     * @notice blocksNeededForOrder
     * @dev immutable variable set in constructor to store number of blocks that order needed to stay in queue to be executed 
     * @return uint256
     */
    uint256 public immutable blocksNeededForOrder;

    /**
     * @notice timelockEnabled
     * @dev variable to store if smart contract timelock is enabled
     * @return boolean
     */
    bool public timelockEnabled;

    /**
     * @notice initialized
     * @dev variable to store if smart contract is initialized
     * @return boolean
     */
    bool public initialized;
    
    /**
     * @notice onChainGovernanceTimelock
     * @dev variable to store the block number that disableTimelock function can change timelockEnabled to true
     * @return uint256
     */
    uint256 public onChainGovernanceTimelock;

    /**
     * @notice DAO Treasury Address where the profits of the operations must be sent to 
     * @dev immutable address to store DAO contract address
     * @return address
     */
    address public DAOTreasury;

    /**
     * @notice daoLiquidityFee
     * @dev variable to store the DAO Liquidity Fee
     * @return uint256
     */
    uint256 public daoLiquidityFee;

    /**
     * @notice constructor
     * @dev this is executed when this contract is deployed
     * @dev set timelockEnabled and initialized to false
     * @dev set blocksNeededForOrder
     * @param _authority Solid DAO Manager contract address
     * @param _ct address of the CT (Carbon Token) this treasury will manange 
     * @param _timelock unint256
     * @param _category string to store the name of the category this contract manages. This is for info purposes.
     * @param _daoTreasury address to store the address of the DAO Vault Smart Contract.
     * @param _daoLiquidityFee uint256 to store the DAO Liquidity Fee.
     */
    constructor(
        address _authority,
        address _ct,
        uint256 _timelock,
        string memory _category,
        address _daoTreasury,
        uint256 _daoLiquidityFee
    ) SolidDaoManaged(ISolidDaoManagement(_authority)) {
        require(_ct != address(0), "CT Treasury: invalid CT address");
        require(_daoTreasury != address(0), "CT Treasury: invalid DAO Treasury");
        CT = ICT(_ct);
        timelockEnabled = false;
        initialized = false;
        blocksNeededForOrder = _timelock;
        category = _category;
        DAOTreasury = _daoTreasury;
        daoLiquidityFee = _daoLiquidityFee;
    }

    /**
     * @notice initialize
     * @dev this function enable timelock and set initialized to true
     * @dev only governor can call this function
     */
    function initialize() external onlyGovernor {
        require(!initialized, "SCT Treasury: already initialized");
        timelockEnabled = true;
        initialized = true;
    }

    

    /*
    ************************************************************
    ** CARBON PROJECT AREA
    ************************************************************
    */

    /**
     * @notice createOrUpdateCarbonProject
     * @notice function to create or update carbon project
     * @dev only permitted reserve manager can call this function
     * @dev only permitted reserve tokens are accepted
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
     * @notice depositReserveToken
     * @notice function to deposit an _amount of ERC1155 carbon project token in SCT Treasury and mint the same _amount of SCT
     * @dev only permitted reserve tokens are accepted
     * @dev only active carbon projects are accepted
     * @dev owner ERC1155 carbon project token balance needs to be more or equal than _amount
     * @dev owner need to allow this contract spend ERC1155 carbon project token before execute this function
     * @dev update _owner carbonProjectBalances and smart contract carbonProjectTons
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
        require(initialized, "Contract was not initialized yet");
        require(permissions[STATUS.RESERVETOKEN][_token], "CT Treasury: reserve token not permitted");
        require(carbonProjects[_token][_tokenId].isActive, "CT Treasury: carbon project not active");
        require((IERC1155(_token).balanceOf(_owner, _tokenId)) >= _amount, "CT Treasury: owner insuficient ERC1155 balance");
        require((IERC1155(_token).isApprovedForAll(_owner, address(this))) , "CT Treasury: owner not approved this contract spend ERC1155");
        
        (bool mathOK, uint256 weeksUntilDelivery) = SolidMath.weeksInThePeriod(block.timestamp, carbonProjects[_token][_tokenId].contractExpectedDueDate);
        require(mathOK, "CT Treasury: weeks from delivery dates are invalid");

        (, uint256 projectAmount, uint256 daoAmount) = payout(
            weeksUntilDelivery,
            _amount,
            carbonProjects[_token][_tokenId].projectDiscountRate,
            daoLiquidityFee,
            CT.decimals()
        );

        IERC1155(_token).safeTransferFrom(
            _owner, 
            address(this), 
            _tokenId, 
            _amount, 
            "data"
        );

        CT.mint(_owner, projectAmount);
        CT.mint(DAOTreasury, daoAmount);

        carbonProjectBalances[_token][_tokenId][_owner] += _amount;
        carbonProjectTons[_token][_tokenId] += _amount;
        totalReserves += _amount;

        emit Deposited(_token, _tokenId, _owner, _amount);
        return true;
    }

    /**
     * @notice TODO: sell issue #49
     * @return true     
     */
    function sell() external returns (bool) {
        return true;
    }

    /**
    @notice informs the investor a simulated return for deposit project's tokens
     */
    function simulateDepositWeekPeriod(
        uint256 _numWeeks,
        uint256 _rate,
        uint256 _totalToken,
        uint256 _daoFee
    ) view public returns (uint256 basisValue, uint256 toProjectOwner, uint256 toDAO) {
        return payout(_numWeeks, _totalToken, _rate, _daoFee, CT.decimals());
    }

    /*
    ************************************************************
    ** POLICY MANAGEMENT AREA
    ************************************************************
    */

    /**
     * @notice enable
     * @notice function to enable permission
     * @dev only policy can call this function
     * @dev timelock needs to be disabled
     * @dev if timelock is enable use orderTimelock function
     * @param _status STATUS
     * @param _address address
     * @return true
     */
    function enable(
        STATUS _status,
        address _address
    ) external onlyPolicy returns(bool) {
        require(_address != address(0), "SCT Treasury: invalid address");
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
     * @dev only policy can call this function
     * @param _status STATUS
     * @param _address address
     * @return true
     */
    function disable(
        STATUS _status, 
        address _address
    ) external onlyPolicy returns(bool) {
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
     * @dev only policy can call this function
     * @param _status STATUS
     * @param _address address
     * @return true
     */
    function orderTimelock(
        STATUS _status,
        address _address
    ) external onlyPolicy returns(bool) {
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

        emit PermissionOrdered(_status, _address, permissionOrder.length);
        return true;
    }

    /**
     * @notice execute
     * @notice function to enable ordered permission
     * @dev only policy can call this function
     * @param _index uint256
     * @return true
     */
    function execute(uint256 _index) external onlyPolicy returns(bool) {
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

    /*
    ************************************************************
    ** GOVERNOR MANAGEMENT AREA
    ************************************************************
    */

    /**
    * @notice function where the Governor sets the DAO liquidity fee
    * @dev only governor can call this function
    * @return true if everything goes well
    * @param _daoLiquidityFee uint256 to store the DAO Liquidity Fee
    */
    function setDAOLiquidityFee(uint256 _daoLiquidityFee) external onlyGovernor returns(bool) {
        daoLiquidityFee = _daoLiquidityFee;
        return true;
    }

    /**
    * @notice function where the Governor sets the DAO Smart Contract address
    * @dev only governor can call this function
    * @return true if everything goes well
    * @param _daoAddress address to store the DAO Smart Contract address
    */
    function setDAOAddress(address _daoAddress) external onlyGovernor returns(bool) {
        DAOTreasury = _daoAddress;
        return true;
    }

    /**
     * @notice nullify
     * @notice function to cancel timelocked order
     * @dev only governor can call this function
     * @param _index uint256
     * @return true
     */
    function nullify(uint256 _index) external onlyGovernor returns(bool) {
        permissionOrder[_index].nullify = true;
        return true;
    }

    /**
     * @notice enableTimelock
     * @notice function to disable timelock
     * @dev only governor can call this function
     * @dev set timelockEnabled to true
     */
    function enableTimelock() external onlyGovernor {
        require(!timelockEnabled, "SCT Treasury: timelock already enabled");
        timelockEnabled = true;
        emit ChangedTimelock(true);
    }

    /**
     * @notice disableTimelock
     * @notice function to disable timelock
     * @dev only governor can call this function
     * @dev onChainGovernanceTimelock need to be less or equal than block number
     */
    function disableTimelock() external onlyGovernor {
        require(timelockEnabled, "SCT Treasury: timelock already disabled");
        require(onChainGovernanceTimelock != 0 && onChainGovernanceTimelock <= block.number, "SCT Treasury: governance timelock not expired yet");
        timelockEnabled = false;
        onChainGovernanceTimelock = 0;
        emit ChangedTimelock(false);
    }

    /**
     * @notice permissionToDisableTimelock
     * @notice function to set onChainGovernanceTimelock to disable timelock
     * @dev only governor can call this function
     * @dev this function set new onChainGovernanceTimelock
     */
    function permissionToDisableTimelock() external onlyGovernor {
        require(timelockEnabled, "SCT Treasury: timelock already disabled");
        onChainGovernanceTimelock = block.number + (blocksNeededForOrder * 10);
        emit SetOnChainGovernanceTimelock(onChainGovernanceTimelock);
    }

    /**
     * @notice totalPermissionOrder
     * @notice view function that returns total permissionOrder entries
     * @return uint256
     */
    function totalPermissionOrder() external view returns (uint256) {
        return permissionOrder.length;
    }    

    /**
     * @notice baseSupply
     * @notice view function that returns SCT total supply
     * @return uint256
     */
    function baseSupply() external view returns (uint256) {
        return CT.totalSupply();
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