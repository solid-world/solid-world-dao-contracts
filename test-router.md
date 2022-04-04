# Router step-by-step to test Solid World Dao Smart Contracts 

## SCT Carbon Treasury

1. Set Carbon Credit ERC1155 as Reserve Token in SCT Carbon Treasury
* To set carbon credit token as reserve token you need to register smart contract address
* Only SCT Autority Governor can execute this function
* When timelock is disabled its posible add a RESERVETOKEN (STATUS = 0) calling enable function or create new order using orderTimeLock function
1.1. Call enable function setting _status 0 (RESERVETOKEN) and Carbon Credit _address 

2. Set Manager as Reserve Manager in SCT Carbon Treasury
* To set manager address as reserve manager you need to register wallet address
* Only SCT Autority Governor can execute this function
* When timelock is disabled its posible add a RESERVEMANAGER (STATUS = 1) calling enable function or create new order using orderTimeLock function
2.1. Call enable function setting _status 1 (RESERVEMANAGER) and manager wallet _address 

3. Create and Set Carbon Project as active in SCT Carbon Treasury
* To set and active Carbon Project you need to call createOrUpdateCarbonProject function, passing isActive field as true.
* Only reserve manager can execute this function
* Only reserve tokens are accepted
3.1. Call setCarbonProject function sending CarbonProject struct:

{
  address token; //address of ERC1155 Carbon Credit smart contract
  uint256 tokenId; //id of ERC1155 Carbon Credit token of one Carbon Project
  uint256 tons; // total amount of project ERC1155 Carbon Credits
  uint256 flatRate; // premium price variable
  uint256 sdgPremium; // premium price variable
  uint256 daysToRealization; // premium price variable
  uint256 closenessPremium; // premium price variable
  bool isActive; // status of Carbon Project in SCT Carbon Treasury (will start with true)
  bool isCertified; // verra certified status (will start with false)
  bool isRedeemed; // status of ERC1155 token id redeem (will start with false)
}

Example: ["0x4D3470e7567d805b29D220cc462825d1abee7D87",1,1000,1,1,1,1,true,false,false]

4. Deposit Carbon Credit in SCT Carbon Treasury
* Before execute deposit function the owner needs to allow SCT Carbon Treasury spend same amount of Carbon Credit Tokens using ERC1155 setApprovalForAll function
* This function mint to the _owner the same amount of Carbon Credit deposited in SCT tokens and increase _owner ERC1155 balance in contract
4.1. Call depositReserveToken function setting address of Carbon Credit _token, token id _tokenId, amount to deposit _amount and address of owner in _owner  

5. Approve Carbon Credit Sell in SCT Carbon Treasury
* This function set the sale approval of ERC1155 amount and SCT total value
* Only owner can execute this function
5.1. Call approveReserveTokenSell function setting address of Carbon Credit _token, token id _tokenId, the amount of ERC1155 to sell in _amount and the total SCT value in _totalValue 

6. Buy Carbon Credit in SCT Carbon Treasury
* Before execute sell function the buyer needs to allow SCT Carbon Treasury spend same amount totalvalue of SCT tokens
* This function burn the _amount of SCT tokens from buyer, transfer to seller the diference between _totalValue - _amount in SCT tokens and transfer to buyer the _amount of ERC1155
* Only buyer can execute this function
5.1. Call buyReserveToken function setting address of Carbon Credit _token, token id _tokenId, address of token owner in _owner, the amount of ERC1155 to sell in _amount and the total SCT value in _totalValue

6. Set Carbon Credit as inactive and certified
* To set Carbon Project as inactive you need to call setCarbonProject function, passing isActive field as false and isCertified as true.
* Only reserve manager can execute this function
6.1. Call setCarbonProject function sending CarbonProject struct (see 3.1):

Example: ["0x4D3470e7567d805b29D220cc462825d1abee7D87",1,1000,1,1,1,1,false,true,false]