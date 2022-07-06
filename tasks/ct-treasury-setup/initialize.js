const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getDeployer } = require('../accounts');
const ctTreasuryAbi = require('../../abi/CTTreasury.json');

task('initialize', 'Initialize CT Treasury')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile')

    const { ethers } = hre;

    const deployerWallet = await getDeployer(ethers);
    console.log(pico.dim('Governor: '.padStart(10) + pico.green(deployerWallet.address)));

    const treasuryAddresses = process.env.CTTREASURIES_ADDRESSES.split(',');
    console.log(pico.dim('CT Treasuries: '.padStart(10) + pico.green(treasuryAddresses)));

    console.log('\n');

    for (const address of treasuryAddresses) {
      const ctTreasuryContract = new ethers.Contract(address, ctTreasuryAbi, deployerWallet);
      console.log('Start initialize CT Treasury address: '.padStart(24), pico.green(address));

      const initialize = await ctTreasuryContract.initialize();
      await initialize.wait();
      console.log('CT Treasury initialize tx: '.padStart(24), pico.green(initialize.hash));

      console.log('Finish initialize CT Treasury address: '.padStart(24), pico.green(address));
    }

    console.log('All initialize tasks finished with success');

  });
