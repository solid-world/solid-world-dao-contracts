const { initializeGasStation } = require('@solid-world/gas-station')

task('deploy-zap-staker', 'Deploys a SolidZapStaker contract')
  .addParam('router', 'The address of the router used to perform token swaps.')
  .addParam('weth', 'The address of WETH contract of the network.')
  .addParam(
    'uniProxy',
    'The address of the Gamma UniProxy contract used for deploying liquidity.'
  )
  .addParam(
    'solidStaking',
    'The address of our SolidStaking contract, to stake with recipient.'
  )
  .setAction(
    async (
      { router, weth, uniProxy, solidStaking },
      { getNamedAccounts, deployments, ethers }
    ) => {
      const gasStation = await initializeGasStation(ethers.provider)
      const { deployer } = await getNamedAccounts()

      const deploymentName = await makeDeploymentName(
        router,
        weth,
        uniProxy,
        solidStaking
      )
      const SolidZapStaker = await deployments.deploy(deploymentName, {
        ...(await gasStation.getCurrentFees()),
        contract: 'SolidZapStaker',
        from: deployer,
        args: [router, weth, uniProxy, solidStaking],
        log: true
      })

      console.log(`SolidZapStaker address: ${SolidZapStaker.address}`)
    }
  )

async function makeDeploymentName(router, weth, uniProxy, solidStaking) {
  router = last4Digits(router)
  weth = last4Digits(weth)
  uniProxy = last4Digits(uniProxy)
  solidStaking = last4Digits(solidStaking)

  return `SolidZapStaker_${router}_${weth}_${uniProxy}_${solidStaking}`
}

function last4Digits(address) {
  return address.slice(-4)
}
