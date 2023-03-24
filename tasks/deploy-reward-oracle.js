const { getCurrentGasFees } = require('@solid-world/gas-station')
const { setupEnvForGasStation } = require('../deploy-helpers/gas-station-env')

const deployMockPoolAndFactory = async (deployer, deployments) => {
  const Pool = await deployments.deploy('MockUniswapV3Pool', {
    from: deployer,
    args: [],
    log: true
  })

  const Factory = await deployments.deploy('MockUniswapV3Factory', {
    from: deployer,
    args: [Pool.address],
    log: true
  })

  return Factory.address
}

async function getVerificationRegistryAddress(deployments) {
  const verificationRegistry = await deployments.get('VerificationRegistry')

  return verificationRegistry.address
}

const deployMockERC20 = async (deployer, deployments) => {
  const verificationRegistryAddress = await getVerificationRegistryAddress(
    deployments
  )

  const CollateralizedBasketToken = await deployments.deploy(
    'CollateralizedBasketToken',
    {
      from: deployer,
      args: [
        'Mock Collateralized Basket Token',
        'MockCBT',
        verificationRegistryAddress
      ],
      log: true
    }
  )

  return CollateralizedBasketToken.address
}

task('deploy-reward-oracle', 'Deploys a reward price oracle contract')
  .addOptionalParam(
    'owner',
    'The owner of the contract. Defaults to OWNER_ADDRESS'
  )
  .addOptionalParam(
    'factory',
    'UniswapV3Factory address. If not provided, a mock factory will be deployed'
  )
  .addOptionalParam(
    'baseToken',
    'The base token address. If not provided, a mock token will be deployed'
  )
  .addOptionalParam(
    'quoteToken',
    'The quote token address. If not provided, a mock token will be deployed'
  )
  .addOptionalParam('fee', 'Pool fee', 500, types.int)
  .addOptionalParam(
    'secondsAgo',
    'Seconds ago to calculate the time-weighted means',
    300,
    types.int
  )
  .setAction(
    async (
      { owner, factory, baseToken, quoteToken, fee, secondsAgo },
      { getNamedAccounts, deployments, network, getChainId, ethers }
    ) => {
      await setupEnvForGasStation(network, getChainId)
      const { deployer, contractsOwner } = await getNamedAccounts()

      let actualOwner = owner ?? contractsOwner
      let actualFactory = factory
      let actualBaseToken = baseToken
      let actualQuoteToken = quoteToken

      if (isLocalhost(network.name)) {
        actualFactory ??= await deployMockPoolAndFactory(deployer, deployments)
        actualBaseToken ??= await deployMockERC20(deployer, deployments)
        actualQuoteToken ??= await deployMockERC20(deployer, deployments)
      }

      const deploymentName = await makeDeploymentName(
        actualBaseToken,
        actualQuoteToken,
        fee,
        ethers
      )
      const UniswapEACAggregatorProxyAdapter = await deployments.deploy(
        deploymentName,
        {
          ...(await getCurrentGasFees()),
          // manual gas limit, because on goerli sometimes the deployment fails with
          // "contract creation code storage out of gas" during `eth_estimategas`.
          // I couldn't figure out why.
          gasLimit: 1011930,
          contract: 'UniswapEACAggregatorProxyAdapter',
          from: deployer,
          args: [
            actualOwner,
            actualFactory,
            actualBaseToken,
            actualQuoteToken,
            fee,
            secondsAgo
          ],
          log: true
        }
      )

      console.log(
        'UniswapEACAggregatorProxyAdapter address',
        UniswapEACAggregatorProxyAdapter.address
      )
    }
  )
async function getTokenSymbol(tokenAddress, ethers) {
  const symbolAbi = ['function symbol() external view returns (string memory)']

  const baseTokenContract = await ethers.getContractAt(symbolAbi, tokenAddress)

  return baseTokenContract.symbol()
}

async function makeDeploymentName(
  baseTokenAddress,
  quoteTokenAddress,
  fee,
  ethers
) {
  const baseTokenSymbol = await getTokenSymbol(baseTokenAddress, ethers)
  const quoteTokenSymbol = await getTokenSymbol(quoteTokenAddress, ethers)

  return `UniswapEACAggregatorProxyAdapter_${baseTokenSymbol}_${quoteTokenSymbol}_${fee}`
}

function isLocalhost(networkName) {
  return ['localhost'].includes(networkName)
}
