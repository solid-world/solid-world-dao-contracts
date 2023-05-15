const { initializeGasStation } = require('@solid-world/gas-station')

task(
  'upgrade-swm',
  'Deploys a SolidWorldManager implementation contract with the latest changes. The call to upgrade needs to be made from the multisig.'
).setAction(async ({}, { getNamedAccounts, deployments, network, ethers }) => {
  const gasStation = await initializeGasStation(ethers.provider)
  const { deployer } = await getNamedAccounts()

  const WeeklyCarbonRewards = await deployments.deploy('WeeklyCarbonRewards', {
    ...(await gasStation.getCurrentFees()),
    from: deployer,
    args: [],
    log: true
  })

  const CarbonDomainRepository = await deployments.deploy(
    'CarbonDomainRepository',
    {
      ...(await gasStation.getCurrentFees()),
      from: deployer,
      args: [],
      log: true
    }
  )

  const CollateralizationManager = await deployments.deploy(
    'CollateralizationManager',
    {
      ...(await gasStation.getCurrentFees()),
      from: deployer,
      args: [],
      log: true
    }
  )

  const DecollateralizationManager = await deployments.deploy(
    'DecollateralizationManager',
    {
      ...(await gasStation.getCurrentFees()),
      from: deployer,
      args: [],
      log: true
    }
  )

  const RegulatoryComplianceManager = await deployments.deploy(
    'RegulatoryComplianceManager',
    {
      ...(await gasStation.getCurrentFees()),
      from: deployer,
      args: [],
      log: true
    }
  )

  const newSWMImplementation = await deployments.deploy(
    'SolidWorldManager_Implementation',
    {
      ...(await gasStation.getCurrentFees()),
      contract: 'SolidWorldManager',
      from: deployer,
      libraries: {
        WeeklyCarbonRewards: WeeklyCarbonRewards.address,
        CarbonDomainRepository: CarbonDomainRepository.address,
        CollateralizationManager: CollateralizationManager.address,
        DecollateralizationManager: DecollateralizationManager.address,
        RegulatoryComplianceManager: RegulatoryComplianceManager.address
      },
      args: [],
      log: true
    }
  )

  console.log(
    'New SolidWorldManager implementation address:',
    newSWMImplementation.address
  )
})
