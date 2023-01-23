const fs = require('node:fs')
require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-ethers')
require('hardhat-deploy')
require('hardhat-deploy-ethers')
require('dotenv').config()
const { ethers } = require('ethers')
require('./tasks')

const {
  POLYGONSCAN_KEY = '',
  ETHERSCAN_KEY = '',
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
    goerli: {
      url: 'https://goerli.infura.io/v3/' + INFURA_KEY,
      gas: 10000000,
      verify: {
        etherscan: {
          apiKey: ETHERSCAN_KEY,
          apiUrl: 'https://api-goerli.etherscan.io/'
        }
      }
    },
    mumbai: {
      url: 'https://polygon-mumbai.infura.io/v3/' + INFURA_KEY,
      timeout: 100000,
      verify: {
        etherscan: {
          apiKey: POLYGONSCAN_KEY,
          apiUrl: 'https://api-testnet.polygonscan.com/'
        }
      }
    },
    polygon: {
      url: 'https://polygon-mainnet.infura.io/v3/' + INFURA_KEY,
      timeout: 100000,
      verify: {
        etherscan: {
          apiKey: POLYGONSCAN_KEY,
          apiUrl: 'https://api.polygonscan.com/'
        }
      }
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
      timeout: 10000
    }
  },
  etherscan: {
    apiKey: {
      goerli: ETHERSCAN_KEY,
      polygonMumbai: POLYGONSCAN_KEY,
      polygon: POLYGONSCAN_KEY
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
