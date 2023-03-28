async function deployRewardsController(deployments, gasStation, deployer) {
  return await deployments.deploy('RewardsController', {
    ...(await gasStation.getCurrentFees()),
    from: deployer,
    log: true
  })
}

async function setupRewardsController(
  deployments,
  gasStation,
  deployer,
  SolidStaking,
  rewardsVault,
  EmissionManager
) {
  return deployments.execute(
    'RewardsController',
    {
      ...(await gasStation.getCurrentFees()),
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
