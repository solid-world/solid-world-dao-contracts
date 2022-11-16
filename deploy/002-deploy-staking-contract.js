const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts()

  await deployments.deploy('SolidStaking', {
    from: deployer,
    log: true
  })
}

func.tags = ['SolidStaking']

module.exports = func
