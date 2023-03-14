const { BigNumber } = require('ethers')
const { getCurrentGasFees } = require('@solid-world/gas-station')
const INITIAL_COLLATERALIZATION_FEE = BigNumber.from(30) // 0.3%
const INITIAL_DECOLLATERALIZATION_FEE = BigNumber.from(500) // 5.0%
const INITIAL_REWARDS_FEE = BigNumber.from(200) // 2.0%

async function deploySolidWorldManager(
  deployments,
  deployer,
  contractsOwner,
  ForwardContractBatchToken,
  EmissionManager
) {
  const WeeklyCarbonRewards = await deployments.deploy('WeeklyCarbonRewards', {
    ...(await getCurrentGasFees()),
    from: deployer,
    args: [],
    log: true
  })

  const CarbonDomainRepository = await deployments.deploy(
    'CarbonDomainRepository',
    {
      ...(await getCurrentGasFees()),
      from: deployer,
      args: [],
      log: true
    }
  )

  const CollateralizationManager = await deployments.deploy(
    'CollateralizationManager',
    {
      ...(await getCurrentGasFees()),
      from: deployer,
      args: [],
      log: true
    }
  )

  const DecollateralizationManager = await deployments.deploy(
    'DecollateralizationManager',
    {
      ...(await getCurrentGasFees()),
      from: deployer,
      args: [],
      log: true
    }
  )

  const CollateralizedBasketTokenDeployer = await deployments.deploy(
    'CollateralizedBasketTokenDeployer',
    {
      ...(await getCurrentGasFees()),
      from: deployer,
      args: [],
      log: true
    }
  )

  return deployments.deploy('SolidWorldManager', {
    ...(await getCurrentGasFees()),
    from: deployer,
    args: [],
    log: true,
    libraries: {
      WeeklyCarbonRewards: WeeklyCarbonRewards.address,
      CarbonDomainRepository: CarbonDomainRepository.address,
      CollateralizationManager: CollateralizationManager.address,
      DecollateralizationManager: DecollateralizationManager.address
    },
    proxy: {
      owner: contractsOwner,
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [
            CollateralizedBasketTokenDeployer.address,
            ForwardContractBatchToken,
            INITIAL_COLLATERALIZATION_FEE,
            INITIAL_DECOLLATERALIZATION_FEE,
            INITIAL_REWARDS_FEE,
            deployer,
            EmissionManager,
            contractsOwner
          ]
        }
      }
    }
  })
}

module.exports = { deploySolidWorldManager }
