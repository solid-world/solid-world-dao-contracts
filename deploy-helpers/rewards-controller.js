async function deployRewardsController(deployments, deployer) {
  return await deployments.deploy('RewardsController', {
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
  await deployments.execute(
    'RewardsController',
    {
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
