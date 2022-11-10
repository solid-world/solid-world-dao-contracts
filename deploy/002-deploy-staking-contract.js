const { ethers } = require('hardhat')

const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer, contractsOwner } = await getNamedAccounts()
  const RewardsController = await ethers.getContract('RewardsController')

  await deployments.deploy('SolidStaking', {
    from: deployer,
    args: [RewardsController.address, contractsOwner],
    log: true
  })
}

func.tags = ['SolidStaking']

module.exports = func
