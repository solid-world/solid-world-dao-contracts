const treasuries = [
  ['ForestConservation', 'CTFC'],
  ['Livestock', 'CTL'],
  ['WasteManagement', 'CTWM'],
  ['Agriculture', 'CTA'],
  ['EnergyProduction', 'CTEP']
]

const daoLiquidityFee = 2 // 2%

const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer, daoTreasury } = await getNamedAccounts()

  const SolidDaoManagement = await deployments.get('SolidDaoManagement')

  for (const [treasuryName, tokenSymbol] of treasuries) {
    const token = await deployments.deploy('Token' + treasuryName, {
      from: deployer,
      contract: 'CTERC20TokenTemplate',
      args: [treasuryName + 'Token', tokenSymbol],
      log: true
    })

    const treasury = await deployments.deploy('Treasury' + treasuryName, {
      from: deployer,
      contract: 'CTTreasury',
      args: [
        SolidDaoManagement.address,
        token.address,
        0,
        treasuryName,
        daoTreasury,
        daoLiquidityFee
      ],
      log: true
    })

    if (token.newlyDeployed) {
      await deployments.execute(
        'Token' + treasuryName,
        { from: deployer, log: true },
        'initialize',
        treasury.address
      )
    }
  }
}

module.exports = func
