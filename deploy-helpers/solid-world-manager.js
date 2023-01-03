const { BigNumber } = require('ethers')
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
    from: deployer,
    args: [],
    log: true
  })

  const CollateralizedBasketTokenDeployer = await deployments.deploy(
    'CollateralizedBasketTokenDeployer',
    {
      from: deployer,
      args: [],
      log: true
    }
  )

  return await deployments.deploy('SolidWorldManager', {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      WeeklyCarbonRewards: WeeklyCarbonRewards.address
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
            EmissionManager
          ]
        }
      }
    }
  })
}

module.exports = { deploySolidWorldManager }
