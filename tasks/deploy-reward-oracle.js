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

const deployMockERC20 = async (deployer, deployments) => {
  const CollateralizedBasketToken = await deployments.deploy(
    'CollateralizedBasketToken',
    {
      from: deployer,
      args: ['Mock Collateralized Basket Token', 'MockCBT'],
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
      { getNamedAccounts, deployments, network }
    ) => {
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

      const UniswapEACAggregatorProxyAdapter = await deployments.deploy(
        'UniswapEACAggregatorProxyAdapter',
        {
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

function isLocalhost(networkName) {
  return ['localhost'].includes(networkName)
}
