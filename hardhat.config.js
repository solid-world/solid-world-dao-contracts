const fs = require('node:fs')
require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-ethers')
require('hardhat-deploy')
require('dotenv').config()
const { ethers } = require('ethers')

const {
  POLYGONSCAN_API_KEY = '',
  ETHERSCAN_API_KEY = '',
  INFURA_KEY = ''
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
      gas: 10000000
    },
    goerli: {
      url: 'https://goerli.infura.io/v3/' + INFURA_KEY,
      gas: 10000000
    },
    ropsten: {
      url: 'https://ropsten.infura.io/v3/' + INFURA_KEY,
      gas: 10000000
    },
    mumbai: {
      url: 'https://polygon-mumbai.infura.io/v3/' + INFURA_KEY,
      timeout: 100000
    },
    polygon: {
      url: 'https://polygon-mainnet.infura.io/v3/' + INFURA_KEY,
      timeout: 100000
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
      timeout: 10000
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
  },
  namedAccounts: {
    deployer: decodePrivateKey(
      process.env.DEPLOYER_JSON,
      process.env.DEPLOYER_PASSWORD
    )
  }
}

function decodePrivateKey(jsonFile, password) {
  const json = fs.readFileSync(jsonFile, 'utf8')
  const wallet = ethers.Wallet.fromEncryptedJsonSync(json, password)
  return 'privatekey://' + wallet.privateKey
}
