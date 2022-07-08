const assert = require('node:assert');
const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getDeployer } = require('../accounts');
const { parseCommaSeparatedValues } = require('../utils');
const ctTreasuryAbi = require('../../abi/CTTreasury.json');

task('disable-timelock', 'Disable CT Treasury Timelock')
  .addParam(
    'treasuries',
    'Comma-separated treasury addresses (fallback to env.CTTREASURIES_ADDRESSES)',
    process.env.CTTREASURIES_ADDRESSES,
  )
  .addFlag('multipleTreasuries', 'Proceeds multiple treasuries')
  .setAction(async (taskArgs, hre) => {
    assert(taskArgs.treasuries !== '', "Argument '--treasuries' should not be empty.");

    await hre.run('compile');

    const { ethers } = hre;
    const { multipleTreasuries } = taskArgs;

    const deployerWallet = await getDeployer(ethers);
    console.log('Governor:', pico.green(deployerWallet.address));

    let treasuryAddresses = parseCommaSeparatedValues(taskArgs.treasuries);
    if (!multipleTreasuries) {
      treasuryAddresses = treasuryAddresses.slice(0, 1);
    }
    console.log('Treasuries:', treasuryAddresses);

    console.log('\n');

    for (const address of treasuryAddresses) {
      const ctTreasuryContract = new ethers.Contract(address, ctTreasuryAbi, deployerWallet);
      console.log('Start disable-timelock CT Treasury address: '.padStart(24), pico.green(address));

      const disablePermit = await ctTreasuryContract.permissionToDisableTimelock();
      await disablePermit.wait();
      console.log('CT Treasury permit to disable timelock tx: '.padStart(24), pico.green(disablePermit.hash));

      const disable = await ctTreasuryContract.disableTimelock()
      await disable.wait()
      console.log('CT Treasury disable timelock tx: '.padStart(24), pico.green(disable.hash));

      console.log('Finish disable-timelock CT Treasury address: '.padStart(24), pico.green(address));
    }

    console.log('All disable-timelock tasks finished with success');

  });
