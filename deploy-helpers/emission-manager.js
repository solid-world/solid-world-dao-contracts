async function deployEmissionManager(deployments, deployer) {
  return await deployments.deploy('EmissionManager', {
    from: deployer,
    args: [],
    log: true
  })
}

async function setupEmissionManager(
  deployments,
  deployer,
  SolidWorldManager,
  RewardsController,
  contractsOwner
) {
  await deployments.execute(
    'EmissionManager',
    { from: deployer, log: true },
    'setup',
    SolidWorldManager,
    RewardsController,
    contractsOwner
  )
}

module.exports = { deployEmissionManager, setupEmissionManager }
