# Router step-by-step to deploy and set Solid World Dao Smart Contracts

## SCT Smart Contracts

### 1. Deploy SCT SolidDaoManagement

1.1. Deploy SolidDaoManagement and set `governor`, `guardian`, `policy` and `vault` addresses in constructor.

### 2. Deploy SCTERC20 Token

2.1. Deploy SCTERC20 and set SCT SolidDaoManagement `address` as `authority` in constructor.

### 3. Deploy and initialize SCT Carbon Treasury

3.1. Deploy SCTCarbonTreasury and set SCTERC20 `address` as `_sct`, timelock `uint256` (blocks need to enable one order) as `_timelock` and SCT SolidDaoManagement `address` as `_authority` in constructor.

3.2. Initialize calling `initialize()` function.

### 4. Add SCT Carbon Treasury as SCT vault in SCT SolidDaoManagement

4.1. Call SCT SolidDaoManagement smart contract `pushVault()` function passing SCT Carbon Treasury `address` as `_newVault` and `true` as `_effectiveImmediately` as parameters.