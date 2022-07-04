const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getPolicy, getGuardian} = require('../accounts');
const ctTreasuryAbi = require('../../abi/CTTreasury.json');

task('enable-permissions', 'Enable CT Treasury Permissions')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile')

    const { ethers } = hre;

    const policyWallet = await getPolicy(ethers);
    const guardianWallet = await getGuardian(ethers);

    console.log(pico.dim('Policy: '.padStart(10) + pico.green(policyWallet.address)));
    console.log(pico.dim('Guardian: '.padStart(10) + pico.green(guardianWallet.address)));

    const carbonProjectTokenAddress =  process.env.CARBON_PROJECT_ERC1155_ADDRESS;
    const treasuryAddresses = process.env.CTTREASURIES_ADDRESSES.split(',');

    console.log(pico.dim('Carbon Project Token: '.padStart(10) + pico.green(carbonProjectTokenAddress)));
    console.log(pico.dim('CT Treasuries: '.padStart(10) + pico.green(treasuryAddresses)));

    console.log('\n');

    treasuryAddresses.forEach(async function (address) {
      const ctTreasuryContract = new ethers.Contract(address, ctTreasuryAbi, policyWallet);
      console.log('Start enable-permissions CT Treasury address: '.padStart(24), pico.green(address));

      const enableToken = await ctTreasuryContract.enable(0, carbonProjectTokenAddress)
      await enableToken.wait()
      console.log('CT Treasury enable carbon project token tx: '.padStart(24), pico.green(enableToken.hash));

      const enableManager = await ctTreasuryContract.enable(1, guardianWallet.address)
      await enableManager.wait()
      console.log('CT Treasury enable manager tx: '.padStart(24), pico.green(enableManager.hash));

      console.log('Finish enable-permissions CT Treasury address: '.padStart(24), pico.green(address));
    });

    console.log('All enable-permissions tasks finished with success');

  });
