# solid-world-dao-contracts

[![MythXBadge](https://badgen.net/https/api.mythx.io/v1/projects/c7145fbf-0af1-4614-a82d-e478fb0cdb47/badge/data?cache=300&icon=https://raw.githubusercontent.com/ConsenSys/mythx-github-badge/main/logo_white.svg)](https://docs.mythx.io/dashboard/github-badges)

This repository contains all Solid World DAO Smart Contracts.

For more information about DAO visit our site: https://solid.world

## Testnet contract addresses and source codes
The smart contracts was deployed at Polygon Mumbai Test Network and the source code was verified on Polygon scan.

### SCT Solid Dao Management (authority)

- Address: `0x54005ab145e74d6354fe81390523e67dc40da64f`
- Source: https://mumbai.polygonscan.com/address/0x54005ab145e74d6354fe81390523e67dc40da64f#code

### SCTERC20 Token

- Address: `0x8fEa7A87FC01305e48C7F7d69609b243f98D4648`
- Source: https://mumbai.polygonscan.com/address/0x8fEa7A87FC01305e48C7F7d69609b243f98D4648#code

### SCT Carbon Treasury

- Address: `0xd0c087bd1e939e56ef064dbab2dbbcb87013fea0`
- Source: https://mumbai.polygonscan.com/address/0xd0c087bd1e939e56ef064dbab2dbbcb87013fea0#code

## Testnet Carbon Credit Token

To access the Carbon Credit and the NFT addresses of Solid Marketplace on Mumbai Testnet Smart Contracts please check this repository https://github.com/solid-world/solid-world-marketplace-contracts

## Testnet Dao Management Wallets

### Governor

- Address: `0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299`
- Source: https://github.com/solid-world/solid-world-dao-contracts/blob/f72db030ba5ee792252e46743ee0511bff503e68/UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299

### Policy

- Address: `0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299`
- Source: https://github.com/solid-world/solid-world-dao-contracts/blob/f72db030ba5ee792252e46743ee0511bff503e68/UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299

### Guardian

- Address: `0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299`
- Source: https://github.com/solid-world/solid-world-dao-contracts/blob/f72db030ba5ee792252e46743ee0511bff503e68/UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299

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

## Available tasks

Decrypts and prints JSON accounts stored in the root directory (e.g. `UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299`):
```sh
npx hardhat print-accounts
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

