const { ethers } = require('hardhat')

const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts()
  const RewardsController = await ethers.getContract('RewardsController')

  await deployments.deploy('SolidStaking', {
    from: deployer,
    args: [RewardsController.address],
    log: true
  })
}

func.tags = ['SolidStaking']

module.exports = func
