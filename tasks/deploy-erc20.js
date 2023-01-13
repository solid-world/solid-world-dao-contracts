const { types, task } = require('hardhat/config')

task('deploy-erc20', 'Deploys a ERC-20 token')
  .addOptionalParam(
    'owner',
    'The owner of the contract. Defaults to OWNER_ADDRESS'
  )
  .addOptionalParam(
    'quantity',
    'Number of tokens to deploy. Default: 1',
    1,
    types.int
  )
  .setAction(
    async ({ owner, quantity }, { getNamedAccounts, deployments, ethers }) => {
      const { deployer, contractsOwner } = await getNamedAccounts()

      const actualOwner = owner ?? contractsOwner

      for (let i = 0; i < quantity; i++) {
        const tokenSymbol = 'TestToken' + (i + 1)
        const tokenAddr = await deployERC20(
          ethers,
          deployer,
          deployments,
          tokenSymbol,
          actualOwner
        )

        console.log([tokenSymbol, tokenAddr].join())
      }
    }
  )

async function deployERC20(
  ethers,
  deployer,
  deployments,
  tokenSymbol,
  ownerAddr
) {
  const Token = await ethers.getContractFactory('CollateralizedBasketToken')
  const token = await Token.deploy(tokenSymbol, tokenSymbol)
  await token.deployed()

  const tx = await token.transferOwnership(ownerAddr)
  await tx.wait()

  return token.address
}
