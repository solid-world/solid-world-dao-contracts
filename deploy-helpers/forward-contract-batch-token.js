async function deployForwardContractBatchToken(deployments, deployer) {
  return await deployments.deploy('ForwardContractBatchToken', {
    from: deployer,
    args: ['https://solid.world/FCBT/{id}.json'],
    log: true
  })
}

async function setupForwardContractBatchToken(
  deployments,
  deployer,
  SolidWorldManager
) {
  await deployments.execute(
    'ForwardContractBatchToken',
    { from: deployer, log: true },
    'transferOwnership',
    SolidWorldManager
  )
}

module.exports = {
  deployForwardContractBatchToken,
  setupForwardContractBatchToken
}
