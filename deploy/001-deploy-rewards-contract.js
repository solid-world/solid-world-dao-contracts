const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts()

  await deployments.deploy('RewardsController', {
    from: deployer,
    log: true
  })
}

func.tags = ['RewardsController']

module.exports = func
