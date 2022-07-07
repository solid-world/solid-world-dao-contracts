const assert = require('node:assert');
const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getDeployer } = require('../accounts');
const { parseCommaSeparatedValues } = require('../utils');
const ctTreasuryAbi = require('../../abi/CTTreasury.json');

task('initialize', 'Initialize CT Treasury')
  .addParam(
    'treasuries',
    'Comma-separated treasury addresses (fallback to env.CTTREASURIES_ADDRESSES)',
    process.env.CTTREASURIES_ADDRESSES,
  )
  .setAction(async (taskArgs, hre) => {
    assert(taskArgs.treasuries !== '', "Argument '--treasuries' should not be empty.");

    await hre.run('compile');

    const { ethers } = hre;

    const deployerWallet = await getDeployer(ethers);
    console.log('Governor:', pico.green(deployerWallet.address));

    const treasuryAddresses = parseCommaSeparatedValues(taskArgs.treasuries);
    console.log('Treasuries:', treasuryAddresses);

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
