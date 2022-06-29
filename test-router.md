# Router step-by-step to test Solid World Dao Smart Contracts
 
# CT Carbon Treasury
 
## 1. Disable and Enable Timelock
 
### 1.1. Disable Timelock
 
To disable the smart contract timelock it is necessary to call two functions:
 
First, you must call the function `permissionToDisableTimelock()` which will establish, based on the number of blocks needed to execute a function multiplied by 10, the number of blocks needed to execute the next function. 

And second, after passing the number of blocks established by the previous function, you need to call the `disableTimelock()` function to disable the timelock.
 
> * Only CT Authority Governor wallet can execute these function
> * When the function `permissionToDisableTimelock()` is executed, CT Carbon Treasury smart contract set new `onChainGovernanceTimelock` block number
> * When the function `disableTimelock()` is executed, CT Carbon Treasury smart contract set `timelockEnabled` to `false` and `onChainGovernanceTimelock` to zero
 
### 1.2. Enable Timelock
 
To enable the timelock you can call the function `enableTimelock()`.
 
> * Only CT Authority Governor wallet can execute this function
> * When the function `enableTimelock()` is executed, CT Carbon Treasury smart contract set `timelockEnabled` to `true`
 
## 2. Add Permissions When Timelock is Disabled
 
### 2.1. Set Carbon Project Credit ERC1155 as Reserve Token in CT Carbon Treasury using enable function
 
To set a carbon Project credit token as reserve token you need to register smart contract address calling `enable()` function and setting `_status` 0 (RESERVETOKEN) and ERC1155 Carbon Project Credit `_address` as parameters.
 
> * Only CT Authority Policy wallet can execute this function
> * This function only can be executed when timelock is disabled
 
### 2.2. Set Manager as Reserve Manager in CT Carbon Treasury using enable function
 
To set manager address as reserve manager you need to register wallet address callind `enable()` function and setting `_status` 1 (RESERVEMANAGER) and manager wallet `_address` as parameters.
 
> * Only CT Authority Policy wallet can execute this function
> * This function only can be executed when timelock is disabled
 
## 3. Add Permissions When Timelock is Enabled
 
### 3.1. Set Carbon Project Credit ERC1155 as Reserve Token in CT Carbon Treasury using orderTimelock function
 
To set a carbon Project credit token as a reserve token you need to create a new `Order` to register a smart contract address calling `orderTimelock()` function and setting `_status` 0 (RESERVETOKEN) and ERC1155 Carbon Project Credit `_address` as parameters.
 
And then, you can execute the previous order, calling `execute()` function and setting the `_order` id as parameter.
 
> * Only CT Authority Policy wallet can execute these functions
> * The `orderTimelock()` function only can be executed when timelock is enabled
> * The `Order` id can be found in `permissionOrder` array or in `PermissionOrdered` event
 
### 3.2. Set Manager as Reserve Manager in CT Carbon Treasury using orderTimelock function
 
To set manager address as reserve manager you need to create a new `Order` to register wallet address calling `orderTimelock()` function and setting `_status` 1 (RESERVEMANAGER) and manager wallet `_address` as parameters.
 
And then, you can execute the previous order, calling the `execute()` function and setting the `_order` id as a parameter.
 
> * Only CT Authority Policy wallet can execute these functions
> * The `orderTimelock()` function only can be executed when timelock is enabled
> * The `Order` id can be found in `permissionOrder` array or in `PermissionOrdered` event
 
### 3.3. Nullify an Order
 
To nullify one pending `Order` you can call the `nullify()` function passing the `_order` id as parameter.
 
> * Only CT Authority Governor wallet can execute this function
> * The `Order` id can be found in `permissionOrder` array or in `PermissionOrdered` event
> * The `Order` will be nullified and it will no longer be possible to execute
 
## 4. Create and edit carbon project
### 4.1. Create and Set Carbon Project as active in CT Carbon Treasury
 
To set an active Carbon Project you need to call `createOrUpdateCarbonProject()` function, setting the `isActive` field as `true`.
 
Call `createOrUpdateCarbonProject()` function sending `CarbonProject` struct:
 
```
{
 address token; //address of ERC1155 Carbon Project Credit smart contract
 uint256 tokenId; //id of ERC1155 Carbon Project Credit token of one Carbon Project
 uint256 tons; // total amount of project ERC1155 Carbon Project Credits
 uint256 contractExpectedDueDate; //the carbon credit contract expected due date to be informed in seconds
 uint256 projectDiscountRate; // fee that will be charged from the investor when commodify the project
 bool isActive; // status of Carbon Project in CT Carbon Treasury (will start with true)
 bool isCertified; // verra certified status (will start with false)
 bool isRedeemed; // status of ERC1155 token id redeem (will start with false)
}
```
 
Example: `["0xC814c7BbF175F541f4Da27f9d8E7Ce12aa981497",1,5000,1672444800,1,true,false,false]`
 
> * Only permitted `RESERVEMANAGER` can execute this function
> * Only permitted `RESERVETOKEN` is accepted
> * Establishing the token and tokenId as an active `CarbonProject`, it is possible to deposit this token in the CT Carbon Treasury
 
### 4.2. Set Carbon Project Credit as inactive and certified
 
To set Carbon Project as inactive you need to call `createOrUpdateCarbonProject` function, setting `isActive` field as `false` and `isCertified` as `true`.
 
Call `createOrUpdateCarbonProject` function sending CarbonProject struct (see 4.1)
 
Example: `["0xC814c7BbF175F541f4Da27f9d8E7Ce12aa981497",1,5000,1672444800,1,false,true,false]`
 
> * Only permitted `RESERVEMANAGER` can execute this function
> * Only permitted `RESERVETOKEN` is accepted
> * Establishing the token and tokenId as an inactive `CarbonProject`, it is not possible to deposit this token in the CT Carbon Treasury
 
## 5. Make a deposit
 
### 5.1. Deposit Carbon Project Credit in CT Carbon Treasury
 
To make a deposit in CT Carbon Treasury `owner` can call `depositReserveToken()` function setting address of Carbon Project Credit `_token`, token id `_tokenId`, amount to deposit `_amount` and address of owner in `_owner` as parameters.
 
> * Before execute deposit function the owner needs to allow CT Carbon Treasury spend same amount of Carbon Project Credit Tokens using ERC1155 `setApprovalForAll()` function
> * This function mint to the `_owner` the same amount of Carbon Project Credit deposited in CT tokens, increase `_owner` `carbonProjectBalances` and smart contract `carbonProjectTons`
> * Only active `carbonProject` can be deposited
 

