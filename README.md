# solid-world-dao-contracts

[![MythXBadge](https://badgen.net/https/api.mythx.io/v1/projects/c7145fbf-0af1-4614-a82d-e478fb0cdb47/badge/data?cache=300&icon=https://raw.githubusercontent.com/ConsenSys/mythx-github-badge/main/logo_white.svg)](https://docs.mythx.io/dashboard/github-badges)

This repository contains all Solid World DAO Smart Contracts.

For more information about DAO visit our site: https://solid.world

## Deployment

Copy and populate environment variables:
```shell
cp .env.example .env
```

In order to deploy to localhost run:
```shell
yarn hardhat deploy --network localhost
```
Supported networks: localhost, goerli, polygon.

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
