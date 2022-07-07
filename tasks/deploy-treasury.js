const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getDeployer } = require('./accounts');

task('deploy-treasury', 'Deploys Treasury contract and corresponded ERC20 Token')
  .addParam('solidDaoManagement', 'Address of SolidDaoManagement contract')
  .addParam('treasuryName', 'Name of the treasury')
  .addOptionalParam('tokenName', 'Name of the corresponded ERC20 token')
  .addParam('tokenSymbol', 'Symbol of the corresponded ERC20 token')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile')

    const { ethers } = hre;
    const {
      solidDaoManagement,
      treasuryName,
      tokenSymbol,
      tokenName = tokenSymbol
    } = taskArgs;

    const deployerWallet = await getDeployer(ethers);

    const CTToken = await ethers.getContractFactory('CTERC20TokenTemplate', deployerWallet);
    const Treasury = await ethers.getContractFactory('CTTreasury', deployerWallet);

    console.log('Deploying %s treasury...', pico.green(treasuryName));

    const ctToken = await CTToken.deploy(tokenSymbol, tokenSymbol);

    const treasury = await Treasury.deploy(
      solidDaoManagement,
      ctToken.address,
      0,
      treasuryName,
      '0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299',
      2
    );

    await ctToken.initialize(treasury.address)

    console.log('Treasury Address: '.padStart(24), pico.green(treasury.address));
    console.log('CT Token Address: '.padStart(24), pico.green(ctToken.address));
  });
