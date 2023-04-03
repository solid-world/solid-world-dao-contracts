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
const {
  deployVerificationRegistry
} = require('../deploy-helpers/verification-registry')
const {
  deployCollateralizedBasketTokenDeployer,
  setupCollateralizedBasketTokenDeployer
} = require('../deploy-helpers/collateralized-basket-token-deployer')
const { initializeGasStation } = require('@solid-world/gas-station')

const func = async ({ getNamedAccounts, deployments, getChainId, ethers }) => {
  const gasStation = await initializeGasStation(ethers.provider)
  const { deployer, contractsOwner, rewardsVault } = await getNamedAccounts()

  await ensureDeployerHasFunds(deployer, await getChainId())

  const VerificationRegistry = await deployVerificationRegistry(
    deployments,
    gasStation,
    deployer,
    contractsOwner
  )

  const ForwardContractBatchToken = await deployForwardContractBatchToken(
    deployments,
    gasStation,
    deployer,
    VerificationRegistry.address
  )
  const CollateralizedBasketTokenDeployer =
    await deployCollateralizedBasketTokenDeployer(
      deployments,
      gasStation,
      deployer,
      VerificationRegistry.address
    )
  const RewardsController = await deployRewardsController(
    deployments,
    gasStation,
    deployer
  )
  const SolidStaking = await deploySolidStaking(
    deployments,
    gasStation,
    deployer,
    VerificationRegistry.address
  )
  const EmissionManager = await deployEmissionManager(
    deployments,
    gasStation,
    deployer
  )
  const SolidWorldManager = await deploySolidWorldManager(
    deployments,
    gasStation,
    deployer,
    contractsOwner,
    ForwardContractBatchToken.address,
    EmissionManager.address,
    CollateralizedBasketTokenDeployer.address
  )

  if (ForwardContractBatchToken.newlyDeployed) {
    await setupForwardContractBatchToken(
      deployments,
      gasStation,
      deployer,
      SolidWorldManager.address
    )
  }

  if (CollateralizedBasketTokenDeployer.newlyDeployed) {
    await setupCollateralizedBasketTokenDeployer(
      deployments,
      gasStation,
      deployer,
      SolidWorldManager.address
    )
  }

  if (EmissionManager.newlyDeployed) {
    await setupEmissionManager(
      deployments,
      gasStation,
      deployer,
      SolidWorldManager.address,
      RewardsController.address,
      contractsOwner
    )
  }

  if (RewardsController.newlyDeployed) {
    await setupRewardsController(
      deployments,
      gasStation,
      deployer,
      SolidStaking.address,
      rewardsVault,
      EmissionManager.address
    )
  }

  if (SolidStaking.newlyDeployed) {
    await setupSolidStaking(
      deployments,
      gasStation,
      deployer,
      RewardsController.address,
      contractsOwner
    )
  }
}

module.exports = func
