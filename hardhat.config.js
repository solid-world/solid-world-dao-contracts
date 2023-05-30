require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-ethers')
require('@typechain/hardhat')
require('hardhat-deploy')
require('hardhat-deploy-ethers')
require('dotenv').config()
require('./tasks')

const {
  CELOSCAN_KEY = '',
  POLYGONSCAN_KEY = '',
  ETHERSCAN_KEY = '',
  INFURA_KEY = '',
  DEPLOYER_PRIVATE_KEY,
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
        version: '0.8.18',
        settings: {
          optimizer: {
            enabled: true,
            runs: 10000
          }
        }
      },
      {
        version: '0.8.16',
        settings: {
          optimizer: {
            enabled: true,
            runs: 10000
          }
        }
      },
      {
        version: '0.7.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 10000
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
    polygon_stage: {
      url: 'https://polygon-mainnet.infura.io/v3/' + INFURA_KEY,
      timeout: 100000,
      verify: {
        etherscan: {
          apiKey: POLYGONSCAN_KEY,
          apiUrl: 'https://api.polygonscan.com/'
        }
      }
    },
    celo: {
      url: 'https://celo-mainnet.infura.io/v3/' + INFURA_KEY,
      timeout: 100000,
      verify: {
        etherscan: {
          apiKey: CELOSCAN_KEY,
          apiUrl: 'https://api.celoscan.io/'
        }
      }
    },
    celo_stage: {
      url: 'https://celo-mainnet.infura.io/v3/' + INFURA_KEY,
      timeout: 100000,
      verify: {
        etherscan: {
          apiKey: CELOSCAN_KEY,
          apiUrl: 'https://api.celoscan.io/'
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
      polygon: POLYGONSCAN_KEY,
      celo: CELOSCAN_KEY
    },
    customChains: [
      {
        network: 'celo',
        chainId: 42220,
        urls: {
          apiURL: 'https://api.celoscan.io/api',
          browserURL: 'https://celoscan.io'
        }
      }
    ]
  },
  namedAccounts: {
    deployer: buildPrivateKey(DEPLOYER_PRIVATE_KEY),
    contractsOwner: {
      default: OWNER_ADDRESS
    },
    rewardsVault: {
      default: REWARDS_VAULT_ADDRESS
    }
  },
  typechain: {
    outDir: 'types',
    target: 'ethers-v5'
  }
}

function buildPrivateKey(privateKey) {
  return `privatekey://${privateKey}`
}
