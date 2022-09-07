const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer, governor, guardian, policy, vault } =
    await getNamedAccounts()

  await deployments.deploy('SolidDaoManagement', {
    from: deployer,
    args: [governor, guardian, policy, vault],
    log: true
  })

  const SolidAccessControl = await deployments.deploy('SolidAccessControl', {
    from: deployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: []
        }
      }
    }
  })

  const Nft = await deployments.deploy('NFT', {
    from: deployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: ['NFT', 'NFT']
        }
      }
    }
  })

  const CarbonCredit = await deployments.deploy('CarbonCredit', {
    from: deployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: ['CarbonCredit']
        }
      }
    }
  })

  await deployments.deploy('SolidMarketplace', {
    from: deployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [Nft.address, CarbonCredit.address, SolidAccessControl.address]
        }
      }
    }
  })
}

module.exports = func
