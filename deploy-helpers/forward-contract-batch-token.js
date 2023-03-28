async function deployForwardContractBatchToken(
  deployments,
  gasStation,
  deployer,
  verificationRegistry
) {
  return deployments.deploy('ForwardContractBatchToken', {
    ...(await gasStation.getCurrentFees()),
    from: deployer,
    args: ['https://solid.world/FCBT/{id}.json', verificationRegistry],
    log: true
  })
}

async function setupForwardContractBatchToken(
  deployments,
  gasStation,
  deployer,
  SolidWorldManager
) {
  return deployments.execute(
    'ForwardContractBatchToken',
    { ...(await gasStation.getCurrentFees()), from: deployer, log: true },
    'transferOwnership',
    SolidWorldManager
  )
}

module.exports = {
  deployForwardContractBatchToken,
  setupForwardContractBatchToken
}
