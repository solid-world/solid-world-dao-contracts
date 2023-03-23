const { getCurrentGasFees } = require('@solid-world/gas-station')

async function deployCollateralizedBasketTokenDeployer(
  deployments,
  deployer,
  VerificationRegistry
) {
  return deployments.deploy('CollateralizedBasketTokenDeployer', {
    ...(await getCurrentGasFees()),
    from: deployer,
    args: [VerificationRegistry],
    log: true
  })
}

async function setupCollateralizedBasketTokenDeployer(
  deployments,
  deployer,
  SolidWorldManager
) {
  return deployments.execute(
    'CollateralizedBasketTokenDeployer',
    { ...(await getCurrentGasFees()), from: deployer, log: true },
    'transferOwnership',
    SolidWorldManager
  )
}

module.exports = {
  deployCollateralizedBasketTokenDeployer,
  setupCollateralizedBasketTokenDeployer
}
