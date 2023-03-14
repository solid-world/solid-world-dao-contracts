const setupEnvForGasStation = async (network, getChainId) => {
  if (!network?.config?.url) {
    throw new Error(`Can't setup env for gas station. Missing network config.`)
  }

  const url = network.config.url
  const chainId = await getChainId()

  process.env.CHAIN_RPC = url
  process.env.CHAIN_ID = chainId
}

module.exports = {
  setupEnvForGasStation
}
