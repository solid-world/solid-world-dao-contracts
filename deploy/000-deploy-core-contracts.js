const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts()

  const Erc20Deployer = await deployments.deploy('Erc20Deployer', {
    from: deployer,
    args: [],
    log: true
  })

  const ForwardContractBatch = await deployments.deploy('CarbonCredit', {
    from: deployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: ['']
        }
      }
    }
  })

  const SolidWorldManager = await deployments.deploy('SolidWorldManager', {
    from: deployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [Erc20Deployer.address, ForwardContractBatch.address]
        }
      }
    }
  })

  if (ForwardContractBatch.newlyDeployed) {
    await deployments.execute(
      'CarbonCredit',
      { from: deployer, log: true },
      'transferOwnership',
      SolidWorldManager.address
    )
  }
}

module.exports = func
