const { initializeGasStation } = require('@solid-world/gas-station')

task('deploy-zap-decollateralize', 'Deploys a SolidZapDecollateralize contract')
  .addParam('router', 'The address of the router used to perform token swaps.')
  .addParam('weth', 'The address of WETH contract of the network.')
  .addParam(
    'swManager',
    'The address of the SolidWorldManager contract used for decollateralizing tokens.'
  )
  .addParam(
    'forwardContractBatch',
    'The address of our ForwardContractBatchToken contract, to transfer ERC1155 to receiver.'
  )
  .setAction(
    async (
      { router, weth, swManager, forwardContractBatch },
      { getNamedAccounts, deployments, ethers }
    ) => {
      const gasStation = await initializeGasStation(ethers.provider)
      const { deployer } = await getNamedAccounts()

      const deploymentName = await makeDeploymentName(
        router,
        weth,
        swManager,
        forwardContractBatch
      )
      const SolidZapDecollateralize = await deployments.deploy(deploymentName, {
        ...(await gasStation.getCurrentFees()),
        contract: 'SolidZapDecollateralize',
        from: deployer,
        args: [router, weth, swManager, forwardContractBatch],
        log: true
      })

      console.log(
        `SolidZapDecollateralize address: ${SolidZapDecollateralize.address}`
      )
    }
  )

async function makeDeploymentName(
  router,
  weth,
  swManager,
  forwardContractBatch
) {
  router = last4Digits(router)
  weth = last4Digits(weth)
  swManager = last4Digits(swManager)
  forwardContractBatch = last4Digits(forwardContractBatch)

  return `SolidZapDecollateralize_${router}_${weth}_${swManager}_${forwardContractBatch}`
}

function last4Digits(address) {
  return address.slice(-4)
}
