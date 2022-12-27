const fs = require('node:fs')
require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-ethers')
require('hardhat-deploy')
require('hardhat-deploy-ethers')
require('dotenv').config()
const { ethers } = require('ethers')
require('./tasks')

const {
  POLYGONSCAN_API_KEY = '',
  ETHERSCAN_API_KEY = '',
  INFURA_KEY = '',
  DEPLOYER_PRIVATE_KEY,
  DEPLOYER_JSON,
  DEPLOYER_PASSWORD,
  OWNER_ADDRESS,
  REWARDS_VAULT_ADDRESS
} = process.env

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: '0.7.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
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
    },
    foundry: {
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
    deployer: DEPLOYER_PRIVATE_KEY
      ? buildPrivateKey(DEPLOYER_PRIVATE_KEY)
      : decodePrivateKey(DEPLOYER_JSON, DEPLOYER_PASSWORD),
    contractsOwner: {
      default: OWNER_ADDRESS
    },
    rewardsVault: {
      default: REWARDS_VAULT_ADDRESS
    }
  }
}

function decodePrivateKey(jsonFile, password) {
  const json = fs.readFileSync(jsonFile, 'utf8')
  const wallet = ethers.Wallet.fromEncryptedJsonSync(json, password)

  return buildPrivateKey(wallet.privateKey)
}

function buildPrivateKey(privateKey) {
  return `privatekey://${privateKey}`
}
