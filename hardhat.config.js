require("@nomiclabs/hardhat-etherscan");
require('@nomiclabs/hardhat-ethers');
require('dotenv').config()
require('./tasks/accounts');
require('./tasks/deploy');
require('./tasks/print-accounts');
const { accountsSecrets, mnemonic, etherscanApiKey, infuraKey } = require('./secrets.json');

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.13',
    settings: {
      optimizer: {
        enabled: true,
        runs: 10
      }
    }
  },
  networks: {
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/' + infuraKey,
      gas: 10000000,
      accounts: accountsSecrets
    },
    ropsten: {
      url: 'https://ropsten.infura.io/v3/' + infuraKey,
      gas: 10000000,
      accounts: { mnemonic: mnemonic }
    },
    testnet: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
      gas: 10000000,
      accounts: { mnemonic: mnemonic }
    },
    main: {
      url: 'https://bsc-dataseed.binance.org/',
      gas: 10000000,
      accounts: { mnemonic: mnemonic }
    },
    mumbai: {
      url: 'https://rpc-mumbai.maticvigil.com',
      accounts: accountsSecrets,
      timeout: 100000,
    },
    polygon: {
      url: 'https://polygon-rpc.com',
      accounts: { mnemonic: mnemonic },
      timeout: 100000,
    }
  },
  etherscan: {
    apiKey: etherscanApiKey
  },
};
