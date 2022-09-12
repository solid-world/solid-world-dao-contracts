const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts()

  const SolidAccessControl = await deployments.get('SolidAccessControl')
  const SolidMarketplace = await deployments.get('SolidMarketplace')

  await deployments.execute(
    'SolidMarketplace',
    {
      from: deployer,
      log: true
    },
    'updateAccessControls',
    SolidAccessControl.address
  )

  await deployments.execute(
    'NFT',
    { from: deployer, log: true },
    'transferOwnership',
    SolidMarketplace.address
  )

  await deployments.execute(
    'CarbonCredit',
    {
      from: deployer,
      log: true
    },
    'transferOwnership',
    SolidMarketplace.address
  )
}

module.exports = func
