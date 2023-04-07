const TimelockController = require('@openzeppelin/contracts/build/contracts/TimelockController.json')

async function deployTimelockController(
  deployments,
  gasStation,
  deployer,
  contractsOwner
) {
  const minDelay = 48 * 60 * 60
  const proposers = [contractsOwner]
  const executors = [contractsOwner]
  const admin = contractsOwner

  return deployments.deploy('TimelockController', {
    ...(await gasStation.getCurrentFees()),
    contract: {
      abi: TimelockController.abi,
      bytecode: TimelockController.bytecode
    },
    from: deployer,
    args: [minDelay, proposers, executors, admin],
    log: true
  })
}

module.exports = {
  deployTimelockController
}
