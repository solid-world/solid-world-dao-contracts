const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getDeployer } = require('./accounts');
const { setTimeout } = require("timers/promises");

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

    console.log('CT Token Address: '.padStart(24), pico.green(ctToken.address));
    console.log('Treasury Address: '.padStart(24), pico.green(treasury.address));
    console.log('Verifing treasury...', pico.green(treasuryName));

    await setTimeout(20000);

    try {
      await run("verify:verify", {
        address: ctToken.address,
        constructorArguments: [
          tokenSymbol,
          tokenSymbol
        ]
      });
  
      await run("verify:verify", {
        address: treasury.address,
        constructorArguments: [
          solidDaoManagement,
          ctToken.address,
          0,
          treasuryName,
          '0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299',
          2
        ]
      });
    } catch (err) {
      if (err.message.includes("Reason: Already Verified")) {
        console.log("Contract is already verified!");
      } else {
        console.log(err.message)
      }
    }

    const initializeCtToken = await ctToken.initialize(treasury.address)
    const receiptInitializeCtToken = await initializeCtToken.wait();

    if (receiptInitializeCtToken.status !== 1) {
      console.log(`initialize CT Token transaction failed: ${receiptInitializeCtToken.transactionHash}`)
    }

    console.log('CT Token initialized', pico.green(receiptInitializeCtToken.transactionHash));

  });
