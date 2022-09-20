const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts()

  const erc20Deployer = await deployments.deploy('Erc20Deployer', {
    from: deployer,
    args: [],
    log: true
  })

  await deployments.deploy('SolidWorldManager', {
    from: deployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [erc20Deployer.address]
        }
      }
    }
  })
}

module.exports = func
