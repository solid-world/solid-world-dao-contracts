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

    /**
     * @notice CarbonProject
     * @dev struct to store carbon project details
     * @param token: ERC1155 smart contract address 
     * @param tokenId: ERC1155 carbon project token id
     * @param tons: total amount of carbon project tokens
     * @param flatRate: premium price variable
     * @param sdgPremium: premium price variable
     * @param daysToRealization: premium price variable
     * @param closenessPremium: premium price variable
     * @param isActive: boolean status of carbon project in this smart contract
     * @param isCertified: boolean verra status of carbon project certificate
     * @param isRedeemed: boolean status of carbon project redeem
     */
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

    /**
     * @notice Offer
     * @dev enum of offer status
     * @dev 0 NOT_DEFINED
     * @dev 1 OPEN
     * @dev 2 EXECUTED
     * @dev 3 CANCELED
     */
    enum StatusOffer {
        NOT_DEFINED,
        OPEN,
        EXECUTED,
        CANCELED
    }

    /**
     * @notice Offer
     * @dev struct to store ERC1155 carbon project buy offers
     * @param token: ERC1155 carbon project smart contract address 
     * @param tokenId: ERC1155 carbon project token id
     * @param buyer: address of buyer
     * @param amount: amount of ERC1155 carbon project tokens to buy
     * @param totalValue: amount of SCT tokens to pay for the sale
     * @param statusOffer: enum StatusOffer
     */
    struct Offer {
        address token;
        uint256 tokenId;
        address buyer;
        uint256 amount;
        uint256 totalValue;
        StatusOffer statusOffer;
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

    event Deposited(address indexed token, uint256 indexed tokenId, address indexed owner, uint256 amount);
    event CreatedOffer(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 totalValue);
    event CanceledOffer(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 totalValue);
    event Sold(uint256 offerId, address indexed token, uint256 indexed tokenId, address indexed owner, address buyer, uint256 amount, uint256 totalValue);
    event UpdatedInfo(address indexed token, uint256 indexed tokenId, bool isActive);
    event ChangedTimelock(bool timelock);
    event SetOnChainGovernanceTimelock(uint256 blockNumber);
    event Permissioned(STATUS indexed status, address token, bool result);
    event PermissionOrdered(STATUS indexed status, address token, uint256 index);

    /**
     * @notice SCT
     * @dev immutable variable to store SCT ERC20 token address
     * @return address
     */
    ISCT public immutable SCT;
    
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
     * @notice offers
     * @dev mapping with offerId as key to store Offers
     * @dev return Offer
     */
    mapping(uint256 => Offer) public offers;

    /**
     * @notice offerIdCounter
     * @dev variable to count the ids of offers
     * @return uint256
     */
    uint256 public offerIdCounter;

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
     * @notice constructor
     * @dev this is executed when this contract is deployed
     * @dev set timelockEnabled and initialized to false
     * @dev set blocksNeededForOrder
     * @param _authority address
     * @param _sct address
     * @param _timelock unint256
     */
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
    ** OFFER AREA
    ************************************************************
    */

    /**
     * @notice createOffer
     * @notice function to create an offer to buy deposited ERC1155 carbon project tokens
     * @notice when the offer is created the buyer deposits _offer.totalValue SCT tokens in this smart contract
     * @notice to remove an OPEN offer, buyer needs to cancel the offer using cancelOffer function
     * @dev only active carbon projects are accepted
     * @dev ERC1155 carbon project tokens deposited in this smart contract needs to be equal or more than _offer.amount
     * @dev SCT _offer.totalValue needs to be equal or more than ERC1155 carbon project tokens _offer.amount
     * @dev only _offer.buyer can call this function
     * @dev msg.sender need to approve this smart contract spend _offer.totalValue of SCT tokens before execute this function
     * @dev to prevent msg.sender lose his SCT tokens this function automatically set offer status to OPEN
     * @param _offer struct Offer
     * @return offerId uint256
     */
    function createOffer(Offer memory _offer) external returns (uint256) {
        require(carbonProjects[_offer.token][_offer.tokenId].isActive, "SCT Treasury: carbon project not active");
        require(carbonProjectTons[_offer.token][_offer.tokenId]  >= _offer.amount, "SCT Treasury: ERC1155 deposited insuficient");
        require(_offer.totalValue >= _offer.amount, "SCT Treasury: SCT total value needs to be more or equal than ERC1155 amount");
        require(_offer.buyer == msg.sender, "SCT Treasury: msg.sender is not the buyer");
        require((SCT.allowance(msg.sender, address(this))) >= _offer.totalValue, "SCT Treasury: buyer not allowed this contract spend SCT");

        SCT.transferFrom(msg.sender, address(this), _offer.totalValue);

        offerIdCounter ++;
        offers[offerIdCounter] = _offer;
        offers[offerIdCounter].statusOffer = StatusOffer.OPEN;

        emit CreatedOffer(offerIdCounter, _offer.token, _offer.tokenId, msg.sender, _offer.amount, _offer.totalValue);
        return offerIdCounter;
    }

    /**
     * @notice cancelOffer
     * @notice function to cancel an offer to buy deposited ERC1155 carbon project tokens
     * @notice when the offer is canceled the msg.sender recieve the amount of offer.totalValue SCT tokens from this smart contract
     * @dev only OPEN offers can be canceled
     * @dev only offer.buyer can call this function
     * @dev change offer.statusOffer to CANCELED
     * @param _offerId uint256 offerId
     * @return true
     */
    function cancelOffer(uint256 _offerId) external returns (bool) {
        require(offers[_offerId].statusOffer == StatusOffer.OPEN, "SCT Treasury: offer is not OPEN");
        require(offers[_offerId].buyer == msg.sender, "SCT Treasury: msg.sender is not the buyer");

        offers[_offerId].statusOffer = StatusOffer.CANCELED;

        SCT.transfer(msg.sender, offers[_offerId].totalValue);

        emit CanceledOffer(_offerId, offers[_offerId].token, offers[_offerId].tokenId, msg.sender, offers[_offerId].amount, offers[_offerId].totalValue);
        return true;
    }

    /**
     * @notice acceptOffer
     * @notice function to accept an offer to buy offer.amount from msg.sender/owner ERC1155 carbon project tokens deposited in this contract
     * @notice burns the offer.amount of SCT deposited in this contract 
     * @notice transfers the difference between offer.totalValue and offer.amount of SCT deposited in this contract to msg.sender/owner
     * @notice transfers to the buyer the offer.amount of ERC1155 carbon project tokens deposited in this contract
     * @dev for security reasons, to execute a sale in this contract it is necessary buyer create some offer first and only OPEN offers are accepted
     * @dev only active carbon projects can be sold
     * @dev only OPEN offer can be executed in this function
     * @dev msg.sender/owner ERC1155 carbon project tokens balance needs to be equal or more than offer.amount
     * @dev update owner carbonProjectBalances and smart contract carbonProjectTons
     * @dev change offer.statusOffer to EXECUTED
     * @param _offerId offer id
     * @return true     
     */
    function acceptOffer(uint256 _offerId) external returns (bool) {

        Offer memory offer = offers[_offerId];

        require(carbonProjects[offer.token][offer.tokenId].isActive, "SCT Treasury: carbon project not active");
        require(offer.statusOffer == StatusOffer.OPEN, "SCT Treasury: offer is not OPEN");
        require(carbonProjectBalances[offer.token][offer.tokenId][msg.sender] >= offer.amount, "SCT Treasury: caller deposited balance insuficient");

        offers[_offerId].statusOffer = StatusOffer.EXECUTED;

        carbonProjectBalances[offer.token][offer.tokenId][msg.sender] -= offer.amount;
        carbonProjectTons[offer.token][offer.tokenId] -= offer.amount;
        totalReserves -= offer.amount;

        SCT.burn(offer.amount);

        if(offer.totalValue - offer.amount > 0) {
            SCT.transfer(msg.sender, offer.totalValue - offer.amount);
        }
        
        IERC1155(offer.token).safeTransferFrom( 
            address(this), 
            offer.buyer,
            offer.tokenId, 
            offer.amount, 
            "data"
        );

        emit Sold(_offerId, offer.token, offer.tokenId, msg.sender, offer.buyer, offer.amount, offer.totalValue);
        return true;
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
        carbonProjectTons[_token][_tokenId] += _amount;
        totalReserves += _amount;

        emit Deposited(_token, _tokenId, _owner, _amount);
        return true;
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