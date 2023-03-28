const { getGasStation } = require('../deploy-helpers/gas-station')

task('deploy-liquidity-deployer', 'Deploys a LiquidityDeployer contract')
  .addParam('token0', 'The address of token0.')
  .addParam('token1', 'The address of token1.')
  .addParam('gammaVault', 'The address of the GammaVault contract.')
  .addParam('uniProxy', 'The address of the UniProxy contract.')
  .addParam(
    'conversionRate',
    'The conversion rate of token0 to token1. (1 token0 = ? token1)'
  )
  .addParam(
    'conversionRateDecimals',
    'The number of decimals in the conversion rate.'
  )
  .setAction(
    async (
      {
        token0,
        token1,
        gammaVault,
        uniProxy,
        conversionRate,
        conversionRateDecimals
      },
      { getNamedAccounts, deployments, network, ethers }
    ) => {
      const gasStation = await getGasStation(network)
      const { deployer } = await getNamedAccounts()

      const deploymentName = await makeDeploymentName(
        token0,
        token1,
        conversionRate,
        conversionRateDecimals,
        ethers
      )
      const LiquidityDeployer = await deployments.deploy(deploymentName, {
        ...(await gasStation.getCurrentFees()),
        contract: 'LiquidityDeployer',
        from: deployer,
        args: [
          token0,
          token1,
          gammaVault,
          uniProxy,
          conversionRate,
          conversionRateDecimals
        ],
        log: true
      })

      console.log(`LiquidityDeployer address: ${LiquidityDeployer.address}`)
    }
  )
async function getTokenSymbol(tokenAddress, ethers) {
  const symbolAbi = ['function symbol() external view returns (string memory)']

  const baseTokenContract = await ethers.getContractAt(symbolAbi, tokenAddress)

  return baseTokenContract.symbol()
}

async function makeDeploymentName(
  token0,
  token1,
  conversionRate,
  conversionRateDecimals,
  ethers
) {
  const token0Symbol = await getTokenSymbol(token0, ethers)
  const token1Symbol = await getTokenSymbol(token1, ethers)

  return `LiquidityDeployer_${token0Symbol}_${token1Symbol}_${conversionRate}_${conversionRateDecimals}`
}
