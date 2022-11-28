async function deploySolidStaking(deployments, deployer) {
  return await deployments.deploy('SolidStaking', {
    from: deployer,
    log: true
  })
}

async function setupSolidStaking(
  deployments,
  deployer,
  RewardsController,
  contractsOwner
) {
  await deployments.execute(
    'SolidStaking',
    {
      from: deployer,
      log: true
    },
    'setup',
    RewardsController,
    contractsOwner
  )
}

module.exports = { deploySolidStaking, setupSolidStaking }
