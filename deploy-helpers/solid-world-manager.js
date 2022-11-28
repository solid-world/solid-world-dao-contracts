const { BigNumber } = require('ethers')
const INITIAL_COLLATERALIZATION_FEE = BigNumber.from(30) // 0.3%
const INITIAL_DECOLLATERALIZATION_FEE = BigNumber.from(500) // 5.0%

async function deploySolidWorldManager(
  deployments,
  deployer,
  ForwardContractBatchToken,
  EmissionManager
) {
  return await deployments.deploy('SolidWorldManager', {
    from: deployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        methodName: 'initialize',
        args: [
          ForwardContractBatchToken,
          INITIAL_COLLATERALIZATION_FEE,
          INITIAL_DECOLLATERALIZATION_FEE,
          deployer,
          EmissionManager
        ]
      }
    }
  })
}

module.exports = { deploySolidWorldManager }
