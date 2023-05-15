const { initializeGasStation } = require('@solid-world/gas-station')

task(
  'upgrade-verification-registry',
  'Deploys a VerificationRegistry implementation contract with the latest changes. The call to upgrade needs to be made from the multisig.'
).setAction(async ({}, { getNamedAccounts, deployments, network, ethers }) => {
  const gasStation = await initializeGasStation(ethers.provider)
  const { deployer } = await getNamedAccounts()

  const newVerificationRegistryImplementation = await deployments.deploy(
    'VerificationRegistry_Implementation',
    {
      ...(await gasStation.getCurrentFees()),
      contract: 'VerificationRegistry',
      from: deployer,
      args: [],
      log: true
    }
  )

  console.log(
    'New VerificationRegistry implementation address:',
    newVerificationRegistryImplementation.address
  )
})
