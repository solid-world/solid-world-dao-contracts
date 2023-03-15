const { getCurrentGasFees } = require('@solid-world/gas-station')

async function deployRewardsController(deployments, deployer) {
  return await deployments.deploy('RewardsController', {
    ...(await getCurrentGasFees()),
    from: deployer,
    log: true
  })
}

async function setupRewardsController(
  deployments,
  deployer,
  SolidStaking,
  rewardsVault,
  EmissionManager
) {
  return deployments.execute(
    'RewardsController',
    {
      ...(await getCurrentGasFees()),
      from: deployer,
      log: true
    },
    'setup',
    SolidStaking,
    rewardsVault,
    EmissionManager
  )
}

module.exports = { deployRewardsController, setupRewardsController }
