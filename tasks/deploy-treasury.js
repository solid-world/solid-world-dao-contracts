const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getDeployer } = require('./accounts');
const { verifyContract } = require('./utils');

task('deploy-treasury', 'Deploys Treasury contract and corresponded ERC20 Token')
  .addParam('solidDaoManagement', 'Address of SolidDaoManagement contract')
  .addParam('treasuryName', 'Name of the treasury')
  .addOptionalParam('tokenName', 'Name of the corresponded ERC20 token')
  .addParam('tokenSymbol', 'Symbol of the corresponded ERC20 token')
  .addFlag('noVerify', 'Skip contracts verification')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile')

    const { ethers } = hre;
    const {
      solidDaoManagement,
      treasuryName,
      tokenSymbol,
      tokenName = tokenSymbol,
      noVerify
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

    console.log('CT Token Address: '.padStart(24), pico.green(ctToken.address));
    console.log('Treasury Address: '.padStart(24), pico.green(treasury.address));

    const initializeCtToken = await ctToken.initialize(treasury.address)
    const receiptInitializeCtToken = await initializeCtToken.wait();

    if (receiptInitializeCtToken.status !== 1) {
      console.log(`initialize CT Token transaction failed: ${receiptInitializeCtToken.transactionHash}`)
    }

    console.log('CT Token initialized', pico.green(receiptInitializeCtToken.transactionHash));

    if (!noVerify) {
      console.log('Verifying treasury...', pico.green(treasuryName));

      const ctVerification = verifyContract(hre, ctToken.address, [
        tokenSymbol,
        tokenSymbol
      ])

      const treasuryVerification = verifyContract(hre, treasury.address, [
        solidDaoManagement,
        ctToken.address,
        0,
        treasuryName,
        '0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299',
        2
      ])

      await Promise.all([
        ctVerification,
        treasuryVerification,
      ])
    }

  });
