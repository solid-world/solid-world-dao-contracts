# solid-world-dao-contracts

[![MythXBadge](https://badgen.net/https/api.mythx.io/v1/projects/c7145fbf-0af1-4614-a82d-e478fb0cdb47/badge/data?cache=300&icon=https://raw.githubusercontent.com/ConsenSys/mythx-github-badge/main/logo_white.svg)](https://docs.mythx.io/dashboard/github-badges)

This repository contains all Solid World DAO Smart Contracts.

For more information about DAO visit our site: https://solid.world

## Testnet contract addresses and verified codes

The smart contracts was deployed at Polygon Mumbai Test Network and the source code was verified on Polygon scan.

#### Solid Dao Management (Authority)

- Address: `0xE3D044eB20160894E9DA09B12F2fD5A4B120B7FD`
- Source: https://mumbai.polygonscan.com/address/0xE3D044eB20160894E9DA09B12F2fD5A4B120B7FD#code

### Test CT ERC20 Tokens and CT Treasuries

#### Forest Conservation

- CT Treasury Address: 0xF6f092322aE97d9587a8ECb24FdAeA21789069ED
- Source: https://mumbai.polygonscan.com/address/0xF6f092322aE97d9587a8ECb24FdAeA21789069ED#code

- CT Token Address:  0xB86E0aac28069bc93c458F0753ec3ba3acd70DAF
- Source: https://mumbai.polygonscan.com/address/0xB86E0aac28069bc93c458F0753ec3ba3acd70DAF#code


#### Livestock

- CT Treasury Address: 0xD5f90a386531082508C05bb83E291d88C86033E1
- Source: https://mumbai.polygonscan.com/address/0xD5f90a386531082508C05bb83E291d88C86033E1#code

- CT Token Address:  0x2c1dA70b73BF922A1Fc3E2239b152FF50963F6FB
- Source: https://mumbai.polygonscan.com/address/0x2c1dA70b73BF922A1Fc3E2239b152FF50963F6FB#code


#### Waste Management

- CT Treasury Address: 0x5911A373902c95f207Ed1b5589D05D03a013257a
- Source: https://mumbai.polygonscan.com/address/0x5911A373902c95f207Ed1b5589D05D03a013257a#code

- CT Token Address:  0x2733F7842b3d49A976217fE66285D73077E500ea
- Source: https://mumbai.polygonscan.com/address/0x2733F7842b3d49A976217fE66285D73077E500ea#code


#### Agriculture

- CT Treasury Address: 0x5911A373902c95f207Ed1b5589D05D03a013257a
- Source: https://mumbai.polygonscan.com/address/0x5911A373902c95f207Ed1b5589D05D03a013257a#code

- CT Token Address:  0x67BC82123d91fdF926BFC681C896272351d15065
- Source: https://mumbai.polygonscan.com/address/0x67BC82123d91fdF926BFC681C896272351d15065#code

#### Energy Production

- CT Treasury Address: 0x62DFE4d624aE80C62bB847eEC7683AC6fc6f494e
- Source: https://mumbai.polygonscan.com/address/0x62DFE4d624aE80C62bB847eEC7683AC6fc6f494e#code

- CT Token Address:  0xD15aDC5425e4661720A70B93fAc8CAB28d9c258C
- Source: https://mumbai.polygonscan.com/address/0xD15aDC5425e4661720A70B93fAc8CAB28d9c258C#code


## Testnet Carbon Credit Token

To access the Carbon Credit and the NFT addresses of Solid Marketplace on Mumbai Testnet Smart Contracts please check this repository https://github.com/solid-world/solid-world-marketplace-contracts

## Testnet Dao Management Wallets

### Governor

- Address: `0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299`
- Source: https://github.com/solid-world/solid-world-dao-contracts/blob/f72db030ba5ee792252e46743ee0511bff503e68/UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299

### Guardian

- Address: `0x94cd0f84fec287f2426e90f0d6653ba8fa29bd8e`
- Source: https://github.com/solid-world/solid-world-dao-contracts/blob/f72db030ba5ee792252e46743ee0511bff503e68/UTC--2022-01-25T14-29-25.630697000Z--94cd0f84fec287f2426e90f0d6653ba8fa29bd8e

### Policy

- Address: `0x513906d9b238955b7e4a499ad98e0b90f9503eb4`
- Source: https://github.com/solid-world/solid-world-dao-contracts/blob/f72db030ba5ee792252e46743ee0511bff503e68/UTC--2022-01-25T14-29-49.236558000Z--513906d9b238955b7e4a499ad98e0b90f9503eb4

## How to deploy to network

- Add fund to deployer account on target network
- Create `secrets.json` (see `secrets.json.example`): add Etherscan API key and Infura API key
- Create `.env` (see `.env.example`): add deployer's creds, guardian, policy and vault addresses
- Run the following command:

```sh
npx hardhat deploy --network {rinkeby | ropsten | main | mumbai}
```

For verification the contract after deployment run:
```sh
npx hardhat verify --network {rinkeby | ropsten | main | mumbai} DEPLOYED_CONTRACT_ADDRESS PARAM1 PARAM_N
```

For deploy multiple treasuries for tests, run:

```
$ npx hardhat deploy --multiple-treasuries --network  {rinkeby | ropsten | main | mumbai}
```

## Available tasks

### Print accounts

Decrypts and prints JSON accounts stored in the root directory (e.g. `UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299`):
```sh
npx hardhat print-accounts
```

### Exporting ABI files

It is mandatory to update ABI files after changing contract signatures: 
```sh
npx hardhat export-abi
```

### CT Treasury Setup and Seed 

These tasks can be used to automatize the creation of CT Treasuries for tests.

For overview of how deploy and set CT Treasury for test, see the [Deployment Flow Diagram](https://github.com/solid-world/solid-world-dao-contracts/blob/v0.9.1/docs/mumbai-deployment-flow.md)

- Add funds to deployer, policy and guardian accounts on target network
- Create `secrets.json` (see `secrets.json.example`): add Etherscan API key and Infura API key
- Create `.env` (see `.env.example`): add deployer, guardian and policy credentials
- Add to `.env` `CARBON_PROJECT_ERC1155_ADDRESS` (ERC-1155 carbon project token address)
- Add to `.env` `CTTREASURIES_ADDRESSES` (CT Treasuries addresses that you wanna run the tasks)
- Before execute these tasks, you need to deploy ERC-1155 carbon project token and mint the tokens to deployer account

If you wanna run the tasks in multiple treasuries, use the flag `--multiple-treasuries`

Initialize CT Treasuries:
```sh
npx hardhat initialize --network  {rinkeby | ropsten | main | mumbai}
```

Disable CT Treasuries timelocks:
```sh
npx hardhat disable-timelock --network  {rinkeby | ropsten | main | mumbai}
```

Enable CT Treasuries reserve carbon project tokens and reserve managers:
```sh
npx hardhat enable-permissions --network  {rinkeby | ropsten | main | mumbai}
```

Seed CT Treasuries with carbon projects:
```sh
npx hardhat project-seed --network  {rinkeby | ropsten | main | mumbai}
```

Deposit carbon project tokens in CT Treasuries:
```sh
npx hardhat deposit-seed --network  {rinkeby | ropsten | main | mumbai}
```

## Run unit tests

This repository has unit tests that cover all smart contracts features.

You can run unit tests built in solidity using Foundry smart contract development toolchain.

Instructions for install Foundry can be found in the documentation:

- [Foundry Book](https://book.getfoundry.sh/index.html)

Before run tests, update forge to map forge-std lib:

```sh
forge update lib/forge-std
```

To compile all smart contracts run:

```sh
forge build
```

After that you can execute unit tests:

```sh
npm run test
```

If you want to run the tests and see detailed traces:

```sh
forge test -vvvv
```

You can also debug a single test using the debug flag and the test function name:

```sh
forge test --debug functionToDebug
```

All tests can be found in the folder `./test`.

The output of tests can be found in the folder `./out`.
 

## Scan smart contracts with Mythx

All smart contracts in this repository were scanned with the mythx security tool:

- [Mythx](https://mythx.io/)

To install mythx and run an analysis you can follow these steps.

First you must install python:

```sh
python3-pip
```

Then you need to install mythx-cli:

```sh
pip3 install mythx-cli
```

Now you can check if it is installed correctly

```sh
mythx --help
```

If you have any issue with markupsake, downgrade the markupsake to version 2.0.1:

```sh
pip install markupsafe==2.0.1
```

Before running an analysis, you also need to add the api key:

```sh
export MYTHX_API_KEY=''
```

And finally, you can select a smart contract and perform a complete code analysis, for example:

```sh
mythx analyze contracts/SolidDaoManagement.sol --mode standard
```

The detailed results obtained can be consulted on the mythx dashboard.

## Previous security reports of Solid World DAO smart contracts

Here you can access the complete reports of the analyzes that have already been performed:

- [Report from 2022-05-16](https://github.com/solid-world/solid-world-dao-contracts/blob/2fac0379e22546c481245bd7f4fd1d42ecfd3733/test-logs/REPORT_2022_05_16.md)

## More info about deploy and tests
 
For a detailed view of how to deploy, set, adjust and test the smart contracts of this repository, access the router files:
 
[Deploy Router](https://github.com/solid-world/solid-world-dao-contracts/blob/main/router.md)
 
[Test Router](https://github.com/solid-world/solid-world-dao-contracts/blob/main/test-router.md)

