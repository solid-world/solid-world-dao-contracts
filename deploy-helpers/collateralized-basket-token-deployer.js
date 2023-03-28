async function deployCollateralizedBasketTokenDeployer(
  deployments,
  gasStation,
  deployer,
  VerificationRegistry
) {
  return deployments.deploy('CollateralizedBasketTokenDeployer', {
    ...(await gasStation.getCurrentFees()),
    from: deployer,
    args: [VerificationRegistry],
    log: true
  })
}

async function setupCollateralizedBasketTokenDeployer(
  deployments,
  gasStation,
  deployer,
  SolidWorldManager
) {
  return deployments.execute(
    'CollateralizedBasketTokenDeployer',
    { ...(await gasStation.getCurrentFees()), from: deployer, log: true },
    'transferOwnership',
    SolidWorldManager
  )
}

module.exports = {
  deployCollateralizedBasketTokenDeployer,
  setupCollateralizedBasketTokenDeployer
}
