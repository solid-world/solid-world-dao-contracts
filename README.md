# solid-world-dao-contracts
Solid World DAO Smart Contracts

## Testnet contract addresses and source codes

The smart contracts was deployed at Polygon Mumbai Test Netowrk

### SCT Solid Dao Management (authority)

Address: 0x54005ab145e74d6354fe81390523e67dc40da64f
Source: https://mumbai.polygonscan.com/address/0x54005ab145e74d6354fe81390523e67dc40da64f#code

### SCTERC20 Token

Address: 0x19b20cEacef5993697F8a5F0be1C071E406329dE
Source: https://mumbai.polygonscan.com/address/0x19b20cEacef5993697F8a5F0be1C071E406329dE#code

### SCT Carbon Treasury

Address: 0x9E16dAa388447E103A12cA61E4D19254B6d21d5e
Source: https://mumbai.polygonscan.com/address/0x9E16dAa388447E103A12cA61E4D19254B6d21d5e#code

## Testnet Carbon Credit Token
### Marketplace ERC1155

Address: 0x4D3470e7567d805b29D220cc462825d1abee7D87
Source: https://mumbai.polygonscan.com/address/0x4D3470e7567d805b29D220cc462825d1abee7D87#code

## Testnet Dao Management Wallets

### Governor

Address: 0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299
Source: https://github.com/solid-world/solid-world-dao-contracts/blob/f72db030ba5ee792252e46743ee0511bff503e68/UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299

### Policy

Address: 0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299
Source: https://github.com/solid-world/solid-world-dao-contracts/blob/f72db030ba5ee792252e46743ee0511bff503e68/UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299

### Guardian

Address: 0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299
Source: https://github.com/solid-world/solid-world-dao-contracts/blob/f72db030ba5ee792252e46743ee0511bff503e68/UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299

### How to deploy to network

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

### Available tasks

Decrypts and prints JSON accounts stored in the root directory (e.g. `UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299`):
```sh
npx hardhat print-accounts
```
