async function deployTimelockController(
  deployments,
  gasStation,
  deployer,
  contractsOwner
) {
  const minDelay = 0
  const proposers = [contractsOwner]
  const executors = [contractsOwner]
  const admin = contractsOwner

  return deployments.deploy('TimelockController', {
    ...(await gasStation.getCurrentFees()),
    contract: 'contracts/TimelockController.sol:TimelockController',
    from: deployer,
    args: [minDelay, proposers, executors, admin],
    log: true
  })
}

module.exports = {
  deployTimelockController
}
