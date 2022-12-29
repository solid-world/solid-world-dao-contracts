const {
  ensureDeployerHasFunds
} = require('../deploy-helpers/ensure-deployer-has-funds')
const {
  deployEmissionManager,
  setupEmissionManager
} = require('../deploy-helpers/emission-manager')
const {
  deployRewardsController,
  setupRewardsController
} = require('../deploy-helpers/rewards-controller')
const {
  deploySolidStaking,
  setupSolidStaking
} = require('../deploy-helpers/solid-staking')
const {
  deploySolidWorldManager
} = require('../deploy-helpers/solid-world-manager')
const {
  deployForwardContractBatchToken,
  setupForwardContractBatchToken
} = require('../deploy-helpers/forward-contract-batch-token')

const func = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deployer, contractsOwner, rewardsVault } = await getNamedAccounts()

  await ensureDeployerHasFunds(deployer, await getChainId())

  const ForwardContractBatchToken = await deployForwardContractBatchToken(
    deployments,
    deployer
  )
  const RewardsController = await deployRewardsController(deployments, deployer)
  const SolidStaking = await deploySolidStaking(deployments, deployer)
  const EmissionManager = await deployEmissionManager(deployments, deployer)
  const SolidWorldManager = await deploySolidWorldManager(
    deployments,
    deployer,
    contractsOwner,
    ForwardContractBatchToken.address,
    EmissionManager.address
  )

  if (ForwardContractBatchToken.newlyDeployed) {
    await setupForwardContractBatchToken(
      deployments,
      deployer,
      SolidWorldManager.address
    )
  }

  if (EmissionManager.newlyDeployed) {
    await setupEmissionManager(
      deployments,
      deployer,
      SolidWorldManager.address,
      RewardsController.address,
      contractsOwner
    )
  }

  if (RewardsController.newlyDeployed) {
    await setupRewardsController(
      deployments,
      deployer,
      SolidStaking.address,
      rewardsVault,
      EmissionManager.address
    )
  }

  if (SolidStaking.newlyDeployed) {
    await setupSolidStaking(
      deployments,
      deployer,
      RewardsController.address,
      contractsOwner
    )
  }
}

module.exports = func
