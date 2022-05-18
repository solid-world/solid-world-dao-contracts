# Router step-by-step to test Solid World Dao Smart Contracts
 
# SCT Carbon Treasury
 
## 1. Disable and Enable Timelock
 
### 1.1. Disable Timelock
 
To disable the smart contract timelock it is necessary to call two functions:
 
First, you must call the function `permissionToDisableTimelock()` which will establish, based on the number of blocks needed to execute a function multiplied by 10, the number of blocks needed to execute the next function. 

And second, after passing the number of blocks established by the previous function, you need to call the `disableTimelock()` function to disable the timelock.
 
> * Only SCT Authority Governor wallet can execute these function
> * When the function `permissionToDisableTimelock()` is executed, SCT Carbon Treasury smart contract set new `onChainGovernanceTimelock` block number
> * When the function `disableTimelock()` is executed, SCT Carbon Treasury smart contract set `timelockEnabled` to `false` and `onChainGovernanceTimelock` to zero
 
### 1.2. Enable Timelock
 
To enable the timelock you can call the function `enableTimelock()`.
 
> * Only SCT Authority Governor wallet can execute this function
> * When the function `enableTimelock()` is executed, SCT Carbon Treasury smart contract set `timelockEnabled` to `true`
 
## 2. Add Permissions When Timelock is Disabled
 
### 2.1. Set Carbon Credit ERC1155 as Reserve Token in SCT Carbon Treasury using enable function
 
To set a carbon credit token as reserve token you need to register smart contract address calling `enable()` function and setting `_status` 0 (RESERVETOKEN) and ERC1155 Carbon Credit `_address` as parameters.
 
> * Only SCT Authority Policy wallet can execute this function
> * This function only can be executed when timelock is disabled
 
### 2.2. Set Manager as Reserve Manager in SCT Carbon Treasury using enable function
 
To set manager address as reserve manager you need to register wallet address callind `enable()` function and setting `_status` 1 (RESERVEMANAGER) and manager wallet `_address` as parameters.
 
> * Only SCT Authority Policy wallet can execute this function
> * This function only can be executed when timelock is disabled
 
## 3. Add Permissions When Timelock is Enabled
 
### 3.1. Set Carbon Credit ERC1155 as Reserve Token in SCT Carbon Treasury using orderTimelock function
 
To set a carbon credit token as a reserve token you need to create a new `Order` to register a smart contract address calling `orderTimelock()` function and setting `_status` 0 (RESERVETOKEN) and ERC1155 Carbon Credit `_address` as parameters.
 
And then, you can execute the previous order, calling `execute()` function and setting the `_order` id as parameter.
 
> * Only SCT Authority Policy wallet can execute these functions
> * The `orderTimelock()` function only can be executed when timelock is enabled
> * The `Order` id can be found in `permissionOrder` array or in `PermissionOrdered` event
 
### 3.2. Set Manager as Reserve Manager in SCT Carbon Treasury using orderTimelock function
 
To set manager address as reserve manager you need to create a new `Order` to register wallet address calling `orderTimelock()` function and setting `_status` 1 (RESERVEMANAGER) and manager wallet `_address` as parameters.
 
And then, you can execute the previous order, calling the `execute()` function and setting the `_order` id as a parameter.
 
> * Only SCT Authority Policy wallet can execute these functions
> * The `orderTimelock()` function only can be executed when timelock is enabled
> * The `Order` id can be found in `permissionOrder` array or in `PermissionOrdered` event
 
### 3.3. Nullify an Order
 
To nullify one pending `Order` you can call the `nullify()` function passing the `_order` id as parameter.
 
> * Only SCT Authority Governor wallet can execute this function
> * The `Order` id can be found in `permissionOrder` array or in `PermissionOrdered` event
> * The `Order` will be nullified and it will no longer be possible to execute
 
## 4. Create and edit carbon project
### 4.1. Create and Set Carbon Project as active in SCT Carbon Treasury
 
To set an active Carbon Project you need to call `createOrUpdateCarbonProject()` function, setting the `isActive` field as `true`.
 
Call `createOrUpdateCarbonProject()` function sending `CarbonProject` struct:
 
```
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
```
 
Example: `["0x593ab3970524891343A76534067dcc595eCfbEDa",1,1000000000000000,1,1,1,1,true,false,false]`
 
> * Only permitted `RESERVEMANAGER` can execute this function
> * Only permitted `RESERVETOKEN` is accepted
> * Establishing the token and tokenId as an active `CarbonProject`, it is possible to deposit this token in the SCT Carbon Treasury
 
### 4.2. Set Carbon Credit as inactive and certified
 
To set Carbon Project as inactive you need to call `createOrUpdateCarbonProject` function, setting `isActive` field as `false` and `isCertified` as `true`.
 
Call `createOrUpdateCarbonProject` function sending CarbonProject struct (see 4.1)
 
Example: `["0x593ab3970524891343A76534067dcc595eCfbEDa",2,9999999999999999,1,1,1,1,false,true,false]`
 
> * Only permitted `RESERVEMANAGER` can execute this function
> * Only permitted `RESERVETOKEN` is accepted
> * Establishing the token and tokenId as an inactive `CarbonProject`, it is not possible to deposit this token in the SCT Carbon Treasury
 
## 5. Make a deposit, create, cancel and accept offer
 
### 5.1. Deposit Carbon Credit in SCT Carbon Treasury
 
To make a deposit in SCT Carbon Treasury `owner` can call `depositReserveToken()` function setting address of Carbon Credit `_token`, token id `_tokenId`, amount to deposit `_amount` and address of owner in `_owner` as parameters.
 
> * Before execute deposit function the owner needs to allow SCT Carbon Treasury spend same amount of Carbon Credit Tokens using ERC1155 `setApprovalForAll()` function
> * This function mint to the `_owner` the same amount of Carbon Credit deposited in SCT tokens, increase `_owner` `carbonProjectBalances` and smart contract `carbonProjectTons`
> * Only active `carbonProject` can be deposited
 
 
### 5.2. Create an Offer to buy Carbon Credit
 
To create an offer buyer can call `createOffer()` function sending `Offer` struct as parameter:
 
```
{
 address token;
 uint256 tokenId;
 address buyer;
 uint256 amount;
 uint256 totalValue;
 StatusOffer statusOffer;
}
```
 
Example: `["0x593ab3970524891343A76534067dcc595eCfbEDa",21,"0x513906d9b238955B7e4A499Ad98E0B90F9503EB4",1000000000000000,2000000000000000,1]`
 
> * Before execute this function the `buyer` needs to allow SCT Carbon Treasury spend same or more than amount of `Offer` `totalvalue` SCT tokens
> * This function create a new `Offer` and deposit in SCT Carbon Treasury the `totalValue` of buyers SCT tokens
> * SCT `totalValue` needs to be equal or more than Carbon Credit Tokens `amount`
> * Only `Offer` `buyer` can execute this function
> * This function set `Offer` `status` to `OPEN`
> * The `Offer` id can be found in `CreatedOffer` event
 
### 5.3. Accept Carbon Credit Offer in SCT Carbon Treasury
 
To accept an offer and transfer to the buyer the Carbon Credit Tokens `owner` can call `acceptOffer` function and use the `_offerId` of `Order` as parameter.
 
> * Only `tokenId` `owner` can execute this function
> * Only active `carbonProject` can be sold
> * This function burns the `Offer` `amount` of SCT tokens deposited in the smart contract, transfer to `owner` the difference between `Offer` `totalValue` and `amount` of SCT tokens and transfer to `Offer` `buyer` the amount of Carbon Credit Tokens.
> * This function update `owner` `carbonProjectBalances` and smart contract `carbonProjectTons`
> * This function set `Offer` `status` to `EXECUTED`
 
### 5.4. Cancel an Offer to buy Carbon Credit
 
To cancel an offer and receive back the SCT Tokens deposited in `Offer` `buyer` can call `cancellOffer()` function and use the `_offerId` of `Order` as parameter.
 
> * Only `Offer` `buyer` can execute this function
> * This function transfer to buyer the `totalValue` of SCT Tokens `Offer` deposited in SCT Carbon Treasury smart contract
> * This function set `Offer` `status` to `CANCELED`
 

