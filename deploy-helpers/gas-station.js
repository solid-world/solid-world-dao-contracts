const { initializeGasStation } = require('@solid-world/gas-station')

const getGasStation = async (network) => {
  if (!network?.config?.url) {
    throw new Error(`Can't obtain gas station. Missing network config.`)
  }

  return initializeGasStation(network.config.url)
}

module.exports = {
  getGasStation
}
