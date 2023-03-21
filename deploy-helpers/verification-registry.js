const { getCurrentGasFees } = require('@solid-world/gas-station')

async function deployVerificationRegistry(
  deployments,
  deployer,
  contractsOwner
) {
  return deployments.deploy('VerificationRegistry', {
    ...(await getCurrentGasFees()),
    from: deployer,
    args: [],
    log: true,
    proxy: {
      // owner of the proxy (a.k.a address authorized to perform upgrades)
      // in our case, it refers to the owner of the DefaultAdminProxy contract
      owner: contractsOwner,
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [contractsOwner] // owner of the VerificationRegistry contract
        }
      }
    }
  })
}

module.exports = {
  deployVerificationRegistry
}
