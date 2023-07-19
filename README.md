# Smart Contracts: The Solid World Protocol

For more information about the protocol, please visit our website: [solid.world](https://solid.world)

## Deployment

To deploy the smart contracts, follow these steps:

1. Copy and populate the environment variables by running the command:
   ```shell
   cp .env.example .env
   ```

2. To deploy to localhost, run the command:
   ```shell
   yarn hardhat deploy --network localhost
   ```

3. To verify the contracts on Etherscan, run the following commands:
   ```shell
   yarn hardhat --network <network> etherscan-verify
   yarn hardhat verify --network goerli <SolidWorldManager_Implementation address>
   ```
   (The second command is required due to a [bug](https://github.com/wighawag/hardhat-deploy/issues/253) that prevents contract verification with linked libraries.)

4. To verify the contracts on Sourcify, run the following command:
    ```shell
    yarn hardhat --network <network> sourcify
    ```

## Hardhat Tasks

The following tasks are available in Hardhat:

1. Deploy a new reward price oracle:
   ```shell
   yarn hardhat --network localhost deploy-reward-oracle [OPTIONS]
   ```

   Options:
    - `--owner`: The owner of the contract. Defaults to `OWNER_ADDRESS`.
    - `--factory`: UniswapV3Factory address. If not provided, a mock factory will be deployed.
    - `--base-token`: The base token address. If not provided, a mock token will be deployed.
    - `--quote-token`: The quote token address. If not provided, a mock token will be deployed.
    - `--fee`: Pool fee (default: 500).
    - `--seconds-ago`: Seconds ago to calculate the time-weighted means (default: 300).

2. Deploy a new LiquidityDeployer contract:
   ```shell
   yarn hardhat --network localhost deploy-liquidity-deployer [OPTIONS]
   ```

   Options:
    - `--token0`: The address of token0.
    - `--token1`: The address of token1.
    - `--gamma-vault`: The address of the GammaVault contract.
    - `--uni-proxy`: The address of the UniProxy contract.
    - `--conversion-rate`: The conversion rate between token0 and token1.
    - `--conversion-rate-decimals`: The number of decimals of the conversion rate.

3. Deploy ERC-20 tokens with Hardhat:
   ```shell
   yarn hardhat deploy-erc20 --network localhost --quantity 3 --owner 0xabcde
   ```

   This command deploys 3 ERC-20 tokens on the localhost network, owned by the address 0xabcde.

   Flags:
    - `--quantity`: The number of tokens to deploy (Default: 1).
    - `--owner`: The owner of the tokens (Default: OWNER_ADDRESS).

4. Deploy a new SolidZapStaker contract:
   ```shell
   yarn hardhat --network localhost deploy-zap-staker [OPTIONS]
   ```

   Options:
   - `--router`: The address of the router used to perform token swaps.
   - `--weth`: The address of WETH contract of the network.
   - `--solid-staking`: The address of our SolidStaking contract, to stake with recipient.

5. Deploy a new SolidZapDecollateralize contract:
   ```shell
   yarn hardhat --network localhost deploy-zap-decollateralize [OPTIONS]
   ```

   Options:
   - `--router`: The address of the router used to perform token swaps.
   - `--weth`: The address of WETH contract of the network.
   - `--sw-manager`: The address of the SolidWorldManager contract used for decollateralizing tokens.
   - `--forward-contract-batch`: The address of our ForwardContractBatchToken contract, to transfer ERC1155 to receiver.

6. Deploy a new SolidZapCollateralize contract:
   ```shell
   yarn hardhat --network localhost deploy-zap-collateralize [OPTIONS]
   ```

   Options:
   - `--router`: The address of the router used to perform token swaps.
   - `--weth`: The address of WETH contract of the network.
   - `--sw-manager`: The address of the SolidWorldManager contract used for collateralizing forward credits.
   - `--forward-contract-batch`: The address of our ForwardContractBatchToken contract, to transfer over ERC1155 from receiver.

## Upgradable Contracts

The following contracts are upgradable and managed by a `DefaultProxyAdmin` contract. The owner of the `DefaultProxyAdmin` contract is authorized to upgrade both contracts.

- SolidWorldManager
- VerificationRegistry

## Exporting Addresses and ABI

To export contract addresses and ABI files to _contract-deployment.json_, run the command:
```shell
yarn hardhat export --export contract-deployment.json --network localhost
```

## Running Unit Tests

This repository includes unit tests that cover all smart contract features. The tests are built using the Foundry smart contract development toolchain.

To run the unit tests, follow these steps:

1. Install Foundry by referring to the documentation: [Foundry Book](https://book.getfoundry.sh/index.html).

2. Before running the tests, update forge to map forge-std lib:
   ```shell
   forge update lib/forge-std
   ```

3. Compile all smart contracts:
   ```shell
   forge build
   ```

4. Execute the unit tests:
   ```shell
   npm run test
   ```

   To see detailed traces, use the following command:
   ```shell
   forge test -vvvv
   ```

   You can also debug a single test by adding the `--debug` flag followed by the test function name:
   ```shell
   forge test --debug functionToDebug
   ```

   Unit tests are located in the `./test` and `./test_gas` folders.

## Test Coverage

To check the test coverage, you can use the following commands:

- Quick coverage check:
  ```shell
  yarn test:coverage
  ```

- Detailed coverage report (requires `lcov` package):
  ```shell
  yarn test:coverage:lcov
  ```

  If you don't have the `lcov` package installed, you can install it using the command:
  ```shell
  brew install lcov
  ```

## Typechain

Typechain is used to generate TypeScript bindings for Solidity smart contracts. The generated types are located in the `./types` folder.

To generate TypeScript bindings, run the following command:
```shell
yarn typechain
```
