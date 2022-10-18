const { ethers } = require('hardhat')
const { BigNumber } = require('ethers')

const LOCALHOST_ID = '31337'

const ensureDeployerHasFunds = async (deployerAddress, chainId) => {
  if (chainId !== LOCALHOST_ID) {
    return
  }
  const [owner] = await ethers.getSigners()

  await owner.sendTransaction({
    to: deployerAddress,
    value: ethers.utils.parseEther('1')
  })
}

const func = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deployer } = await getNamedAccounts()

  await ensureDeployerHasFunds(deployer, await getChainId())

  const ForwardContractBatchToken = await deployments.deploy(
    'ForwardContractBatchToken',
    {
      from: deployer,
      args: ['https://solid.world/FCBT/{id}.json'],
      log: true
    }
  )

  const INITIAL_COLLATERALIZATION_FEE = BigNumber.from(30) // 0.3%
  const SolidWorldManager = await deployments.deploy('SolidWorldManager', {
    from: deployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [
            ForwardContractBatchToken.address,
            INITIAL_COLLATERALIZATION_FEE
          ]
        }
      }
    }
  })

  if (ForwardContractBatchToken.newlyDeployed) {
    await deployments.execute(
      'ForwardContractBatchToken',
      { from: deployer, log: true },
      'transferOwnership',
      SolidWorldManager.address
    )
  }
}

module.exports = func
