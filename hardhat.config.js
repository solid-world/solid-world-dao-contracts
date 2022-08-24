require('@nomiclabs/hardhat-etherscan');
require('@nomiclabs/hardhat-ethers');
require('dotenv').config()

require('./tasks/deploy');
require('./tasks/deploy-treasury');
require('./tasks/export-abi');
require('./tasks/print-accounts');
require('./tasks/ct-treasury-setup/initialize');
require('./tasks/ct-treasury-setup/disable-timelock');
require('./tasks/ct-treasury-setup/enable-permissions');
require('./tasks/ct-treasury-seed/project-seed');
require('./tasks/ct-treasury-seed/deposit-seed');

const {
  POLYGONSCAN_API_KEY = '',
  ETHERSCAN_API_KEY = '',
  INFURA_KEY = '',
} = process.env

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.16',
    settings: {
      optimizer: {
        enabled: false,
        runs: 0
      }
    }
  },
  networks: {
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/' + INFURA_KEY,
      gas: 10000000,
    },
    goerli: {
      url: 'https://goerli.infura.io/v3/' + INFURA_KEY,
      gas: 10000000,
    },
    ropsten: {
      url: 'https://ropsten.infura.io/v3/' + INFURA_KEY,
      gas: 10000000,
    },
    mumbai: {
      url: 'https://polygon-mumbai.infura.io/v3/' + INFURA_KEY,
      timeout: 100000,
    },
    polygon: {
      url: 'https://polygon-mainnet.infura.io/v3/' + INFURA_KEY,
      timeout: 100000,
    }
  },
  etherscan: {
    apiKey: {
      rinkeby: ETHERSCAN_API_KEY,
      goerli: ETHERSCAN_API_KEY,
      ropsten: ETHERSCAN_API_KEY,
      polygonMumbai: POLYGONSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY
    }
  }
};
