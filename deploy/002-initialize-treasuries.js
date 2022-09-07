const treasuries = [
  ['ForestConservation', 'CTFC'],
  ['Livestock', 'CTL'],
  ['WasteManagement', 'CTWM'],
  ['Agriculture', 'CTA'],
  ['EnergyProduction', 'CTEP']
]

const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer, guardian } = await getNamedAccounts()

  const CarbonCredit = await deployments.get('CarbonCredit')

  for (const [treasuryName] of treasuries) {
    const Treasury = await deployments.get('Treasury' + treasuryName)

    if (Treasury.newlyDeployed ||
      // For some reason a just deployed contract in the previous script has "undefined" value
      Treasury.newlyDeployed === undefined
    ) {
      await deployments.execute(
        'Treasury' + treasuryName,
        { from: deployer, log: true },
        'initialize'
      )

      await deployments.execute(
        'Treasury' + treasuryName,
        { from: deployer, log: true },
        'permissionToDisableTimelock'
      )

      await deployments.execute(
        'Treasury' + treasuryName,
        { from: deployer, log: true },
        'disableTimelock'
      )

      await deployments.execute(
        'Treasury' + treasuryName,
        { from: deployer, log: true },
        'enable',
        0,
        CarbonCredit.address
      )

      await deployments.execute(
        'Treasury' + treasuryName,
        { from: deployer, log: true },
        'enable',
        1,
        guardian
      )
    }
  }
}

module.exports = func
