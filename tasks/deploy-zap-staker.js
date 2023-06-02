const { initializeGasStation } = require('@solid-world/gas-station')

task('deploy-zap-staker', 'Deploys a SolidZapStaker contract')
  .addParam('router', 'The address of the router used to perform token swaps.')
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
      { router, uniProxy, solidStaking },
      { getNamedAccounts, deployments, ethers }
    ) => {
      const gasStation = await initializeGasStation(ethers.provider)
      const { deployer } = await getNamedAccounts()

      const deploymentName = await makeDeploymentName(
        router,
        uniProxy,
        solidStaking
      )
      const SolidZapStaker = await deployments.deploy(deploymentName, {
        ...(await gasStation.getCurrentFees()),
        contract: 'SolidZapStaker',
        from: deployer,
        args: [router, uniProxy, solidStaking],
        log: true
      })

      console.log(`SolidZapStaker address: ${SolidZapStaker.address}`)
    }
  )

async function makeDeploymentName(router, uniProxy, solidStaking) {
  router = last4Digits(router)
  uniProxy = last4Digits(uniProxy)
  solidStaking = last4Digits(solidStaking)

  return `SolidZapStaker_${router}_${uniProxy}_${solidStaking}`
}

function last4Digits(address) {
  return address.slice(-4)
}
