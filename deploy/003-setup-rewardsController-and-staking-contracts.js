const { ethers } = require('hardhat')

const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer, contractsOwner } = await getNamedAccounts()
  const RewardsController = await ethers.getContract('RewardsController')
  const SolidStaking = await ethers.getContract('SolidStaking')

  await deployments.execute(
    'RewardsController',
    {
      from: deployer,
      log: true
    },
    'setup',
    SolidStaking.address
  )

  await deployments.execute(
    'SolidStaking',
    {
      from: deployer,
      log: true
    },
    'setup',
    RewardsController.address,
    contractsOwner
  )
}

func.tags = ['Setup_RewardsController_SolidStaking']

module.exports = func
