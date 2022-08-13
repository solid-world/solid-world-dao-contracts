# Router step-by-step to deploy and set Solid World Dao Smart Contracts

## SCT Smart Contracts

### 1. Deploy CT SolidDaoManagement

1.1. Deploy SolidDaoManagement and set `governor`, `guardian`, `policy` and `vault` addresses in .env file or OS environment variables.

### 2. Deploy CTERC20 Token

2.1. Deploy CTERC20TokenTemplate and set token `_name` and token `_symbol` in constructor.

### 3. Deploy and initialize CT Treasury

3.1. Deploy CTTreasury and set CTERC20 `address` as `_cterc20`, timelock `uint256` (blocks need to enable one order) as `_timelock` and CT SolidDaoManagement `address` as `_authority` in constructor.

3.2. Initialize calling `initialize()` function.

### 4. Initialize CTERC20 and Add CT Carbon Treasury

4.1. Call CTERC20TokenTemplate smart contract `initialize()` function and set CT Treasury `address` as `_treasury_`.