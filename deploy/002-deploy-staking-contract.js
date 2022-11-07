const { ethers } = require('hardhat')

const func = async ({ getNamedAccounts, deployments }) => {
  const { deployer, contractsOwner } = await getNamedAccounts()
  const RewardsController = await ethers.getContract('RewardsController')

  const SolidStaking = await deployments.deploy('SolidStaking', {
    from: deployer,
    args: [RewardsController.address],
    log: true
  })

  if (SolidStaking.newlyDeployed) {
    await deployments.execute(
      'SolidStaking',
      { from: deployer, log: true },
      'transferOwnership',
      contractsOwner
    )
  }
}

func.tags = ['SolidStaking']

module.exports = func
