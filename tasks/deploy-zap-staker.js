const { initializeGasStation } = require('@solid-world/gas-station')

task('deploy-zap-staker', 'Deploys a SolidZapStaker contract')
  .addParam('router', 'The address of the router used to perform token swaps.')
  .addParam('weth', 'The address of WETH contract of the network.')
  .addParam(
    'solidStaking',
    'The address of our SolidStaking contract, to stake with recipient.'
  )
  .setAction(
    async (
      { router, weth, solidStaking },
      { getNamedAccounts, deployments, ethers }
    ) => {
      const gasStation = await initializeGasStation(ethers.provider)
      const { deployer } = await getNamedAccounts()

      const deploymentName = await makeDeploymentName(
        router,
        weth,
        solidStaking
      )
      const SolidZapStaker = await deployments.deploy(deploymentName, {
        ...(await gasStation.getCurrentFees()),
        contract: 'SolidZapStaker',
        from: deployer,
        args: [router, weth, solidStaking],
        log: true
      })

      console.log(`SolidZapStaker address: ${SolidZapStaker.address}`)
    }
  )

async function makeDeploymentName(router, weth, solidStaking) {
  router = last4Digits(router)
  weth = last4Digits(weth)
  solidStaking = last4Digits(solidStaking)

  return `SolidZapStaker_${router}_${weth}_${solidStaking}`
}

function last4Digits(address) {
  return address.slice(-4)
}
