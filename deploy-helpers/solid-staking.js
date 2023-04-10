async function deploySolidStaking(
  deployments,
  gasStation,
  deployer,
  verificationRegistry,
  timelockController
) {
  return deployments.deploy('SolidStaking', {
    ...(await gasStation.getCurrentFees()),
    from: deployer,
    args: [verificationRegistry, timelockController],
    log: true
  })
}

async function setupSolidStaking(
  deployments,
  gasStation,
  deployer,
  RewardsController,
  contractsOwner
) {
  return deployments.execute(
    'SolidStaking',
    {
      ...(await gasStation.getCurrentFees()),
      from: deployer,
      log: true
    },
    'setup',
    RewardsController,
    contractsOwner
  )
}

module.exports = { deploySolidStaking, setupSolidStaking }
