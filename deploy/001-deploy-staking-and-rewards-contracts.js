const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer, contractsOwner } = await getNamedAccounts()

  const RewardsController = await deployments.deploy('RewardsController', {
    from: deployer,
    log: true
  })

  const SolidStaking = await deployments.deploy('SolidStaking', {
    from: deployer,
    log: true
  })

  const EmissionManager = await deployments.deploy('EmissionManager', {
    from: deployer,
    args: [RewardsController.address, contractsOwner],
    log: true
  })

  if (RewardsController.newlyDeployed) {
    await deployments.execute(
      'RewardsController',
      {
        from: deployer,
        log: true
      },
      'setup',
      SolidStaking.address,
      contractsOwner,
      EmissionManager.address
    )
  }

  if (SolidStaking.newlyDeployed) {
    await deployments.execute(
      'SolidStaking',
      {
        from: deployer,
        log: true
      },
      'setup',
      RewardsController.address,
      contractsOwner
    )
  }
}

func.tags = ['RewardsController_SolidStaking']

module.exports = func
