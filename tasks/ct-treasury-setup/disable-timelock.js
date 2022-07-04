const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getDeployer } = require('../accounts');
const ctTreasuryAbi = require('../../abi/SCTCarbonTreasury.json');

task('disable-timelock', 'Disable CT Treasury Timelock')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile')

    const { ethers } = hre;

    const deployerWallet = await getDeployer(ethers);
    console.log(pico.dim('Governor: '.padStart(10) + pico.green(deployerWallet.address)));

    const treasuryAddresses = process.env.CTTREASURIES_ADDRESSES.split(',');
    console.log(pico.dim('CT Treasuries: '.padStart(10) + pico.green(treasuryAddresses)));

    console.log('\n');

    treasuryAddresses.forEach(async function (address) {
      const ctTreasuryContract = new ethers.Contract(address, ctTreasuryAbi, deployerWallet);
      console.log('Start disable-timelock CT Treasury address: '.padStart(24), pico.green(address));

      const disablePermit = await ctTreasuryContract.permissionToDisableTimelock();
      await disablePermit.wait();
      console.log('CT Treasury permit to disable timelock tx: '.padStart(24), pico.green(disablePermit.hash));

      const disable = await ctTreasuryContract.disableTimelock()
      await disable.wait()
      console.log('CT Treasury disable timelock tx: '.padStart(24), pico.green(disable.hash));

      console.log('Finish disable-timelock CT Treasury address: '.padStart(24), pico.green(address));
    });

    console.log('All disable-timelock tasks finished with success');

  });
