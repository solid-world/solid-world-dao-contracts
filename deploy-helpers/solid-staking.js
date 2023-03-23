const { getCurrentGasFees } = require('@solid-world/gas-station')

async function deploySolidStaking(deployments, deployer, verificationRegistry) {
  return deployments.deploy('SolidStaking', {
    ...(await getCurrentGasFees()),
    from: deployer,
    args: [verificationRegistry],
    log: true
  })
}

async function setupSolidStaking(
  deployments,
  deployer,
  RewardsController,
  contractsOwner
) {
  return deployments.execute(
    'SolidStaking',
    {
      ...(await getCurrentGasFees()),
      from: deployer,
      log: true
    },
    'setup',
    RewardsController,
    contractsOwner
  )
}

module.exports = { deploySolidStaking, setupSolidStaking }
