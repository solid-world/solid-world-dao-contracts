# solid-world-dao-contracts

[![MythXBadge](https://badgen.net/https/api.mythx.io/v1/projects/c7145fbf-0af1-4614-a82d-e478fb0cdb47/badge/data?cache=300&icon=https://raw.githubusercontent.com/ConsenSys/mythx-github-badge/main/logo_white.svg)](https://docs.mythx.io/dashboard/github-badges)

This repository contains all Solid World DAO Smart Contracts.

For more information about DAO visit our site: https://solid.world

## Deployment

▶ Copy and populate environment variables:
```shell
cp .env.example .env
```

▶ In order to deploy to localhost run:
```shell
yarn hardhat deploy --network localhost
```

▶ To verify the contracts on Etherscan run:
```shell
yarn hardhat --network <network> etherscan-verify
yarn hardhat verify --network goerli <SolidWorldManager_Implementation address>
```
(the second command is required because there's currently a [bug](https://github.com/wighawag/hardhat-deploy/issues/253) that prevents verification of contracts with linked libraries)

▶ To deploy a new reward price oracle run:
```shell
yarn hardhat --network localhost deploy-reward-oracle [OPTIONS] 
```

OPTIONS:

- `--owner`       The owner of the contract. Defaults to `OWNER_ADDRESS`
- `--factory`     UniswapV3Factory address. If not provided, a mock factory will be deployed
- `--base-token`  The base token address. If not provided, a mock token will be deployed
- `--quote-token` The quote token address. If not provided, a mock token will be deployed
- `--fee`         Pool fee (default: 500)
- `--seconds-ago` Seconds ago to calculate the time-weighted means (default: 300)

## Hardhat Tasks

▶ Deploying ERC-20 tokens with hardhat

```shell
yarn hardhat deploy-erc20 --network foundry --quantity 3 --owner 0xabcde
```

This command deploys 3 ERC-20 tokens on the Foundry network, owned by the address 0xabcde.

- `--quantity` flag specifies the number of tokens to deploy (Default: 1)
- `--owner` flag specifies the owner of the tokens (Default: OWNER_ADDRESS)



## How to export addresses and ABI?

In order to export contract addresses and ABI files to _contract-deployment.json_ run:
```shell
yarn hardhat export --export contract-deployment.json --network localhost
```
Supported networks: localhost, goerli, polygon.

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
