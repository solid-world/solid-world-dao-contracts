const { getCurrentGasFees } = require('@solid-world/gas-station')

async function deployForwardContractBatchToken(
  deployments,
  deployer,
  verificationRegistry
) {
  return deployments.deploy('ForwardContractBatchToken', {
    ...(await getCurrentGasFees()),
    from: deployer,
    args: ['https://solid.world/FCBT/{id}.json', verificationRegistry],
    log: true
  })
}

async function setupForwardContractBatchToken(
  deployments,
  deployer,
  SolidWorldManager
) {
  return deployments.execute(
    'ForwardContractBatchToken',
    { ...(await getCurrentGasFees()), from: deployer, log: true },
    'transferOwnership',
    SolidWorldManager
  )
}

module.exports = {
  deployForwardContractBatchToken,
  setupForwardContractBatchToken
}
