async function deployEmissionManager(deployments, gasStation, deployer) {
  return deployments.deploy('EmissionManager', {
    ...(await gasStation.getCurrentFees()),
    from: deployer,
    args: [],
    log: true
  })
}

async function setupEmissionManager(
  deployments,
  gasStation,
  deployer,
  SolidWorldManager,
  RewardsController,
  contractsOwner
) {
  return deployments.execute(
    'EmissionManager',
    { ...(await gasStation.getCurrentFees()), from: deployer, log: true },
    'setup',
    SolidWorldManager,
    RewardsController,
    contractsOwner
  )
}

module.exports = { deployEmissionManager, setupEmissionManager }
