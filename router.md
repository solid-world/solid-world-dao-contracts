# Router step-by-step to deploy and test Solid Word Dao Smart Contracts

1. Deploy SCT SolidDaoManagement
1.1. Deploy SolidDaoManagement and set governor, guardian, policy and vault addresses in constructor

2. Deploy SCTERC20 Token
2.1. Deploy SCTERC20 and set SCT SolidDaoManagement address as authority in constructor

3. Deploy and initialize Carbon Treasury
3.1. Deploy CarbonTreasury and set SCTERC20 address as _sct, timelock uint256 (blocks need to enable one order) as _timelock and SCT SolidDaoManagement address as _authority in constructor
3.2. Initialize calling initialize function
* To disable timelock call disableTimelock function

4. Add Carbon Treasury as SCT vault in SCT SolidDaoManagement
4.1. Call SCT SolidDaoManagement smart contract pushVault function passing Carbon Treasury as _newVault and true as _effectiveImmediately

5. Set Carbon Credit ERC1155 as Reserve Token in Carbon Treasury
* To set carbon credit token as reserve token is needed to register token address
* When timelock is disabled its posible add a RESERVETOKEN (STATUS = 0) calling enable function or create new order using orderTimeLock function
5.1. Call enable function setining _status 0 (RESERVETOKEN) and Carbon Credit _address 

6. Set Depositor as Reserve Depositor in Carbon Treasury
* To set depositor address as reserve depositor is needed to register wallet address
* When timelock is disabled its posible add a RESERVEDEPOSITOR (STATUS = 1) calling enable function or create new order using orderTimeLock function
6.1. Call enable function setining _status 1 (RESERVETOKEN) and depositor wallet _address 

7. Set Spender as Reserve Spender in Carbon Treasury
* To set spender address as reserve spender is needed to register wallet address
* When timelock is disabled its posible add a RESERVESPENDER (STATUS = 2) calling enable function or create new order using orderTimeLock function
7.1. Call enable function setining _status 2 (RESERVESPENDER) and spender wallet _address 

8. Deposit Carbon Credit in Carbon Treasury
* Before execute deposit function is needed to allow Carbon Treasury spend same amount of Carbon Credit Tokens using ERC1155 setApprovalForAll function
* This function mint the same amount of Carbon Credit deposited in SCT tokens
8.1. Call deposit function setting address of Carbon Credit _token, token id _tokenId, amount to deposit _amount and address of owner in _owner  

9. Withdraw Carbon Credit in Carbon Treasury
9.1. Call withdraw function setting address of Carbon Credit _token, token id _tokenId and to address to recieve in _owner