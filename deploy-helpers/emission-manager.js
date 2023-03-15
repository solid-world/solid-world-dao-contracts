const { getCurrentGasFees } = require('@solid-world/gas-station')

async function deployEmissionManager(deployments, deployer) {
  return deployments.deploy('EmissionManager', {
    ...(await getCurrentGasFees()),
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
  return deployments.execute(
    'EmissionManager',
    { ...(await getCurrentGasFees()), from: deployer, log: true },
    'setup',
    SolidWorldManager,
    RewardsController,
    contractsOwner
  )
}

module.exports = { deployEmissionManager, setupEmissionManager }
