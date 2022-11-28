const { ethers } = require("hardhat");

const LOCALHOST_ID = '31337'

const ensureDeployerHasFunds = async (deployerAddress, chainId) => {
  if (chainId !== LOCALHOST_ID) {
    return
  }
  const [owner] = await ethers.getSigners()

  await owner.sendTransaction({
    to: deployerAddress,
    value: ethers.utils.parseEther('100')
  })
}

module.exports = { ensureDeployerHasFunds }
