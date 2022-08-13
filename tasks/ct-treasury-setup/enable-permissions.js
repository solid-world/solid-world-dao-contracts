const assert = require('node:assert');
const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getPolicy, getGuardian} = require('../accounts');
const { parseCommaSeparatedValues } = require('../utils');
const ctTreasuryAbi = require('../../abi/CTTreasury.json');

task('enable-permissions', 'Enable CT Treasury Permissions')
  .addParam(
    'erc1155',
    'ERC-1155 token address (fallback to env.CARBON_CREDIT_CONTRACT_ADDRESS)',
    process.env.CARBON_CREDIT_CONTRACT_ADDRESS,
  )
  .addParam(
    'treasuries',
    'Comma-separated treasury addresses (fallback to env.CTTREASURIES_ADDRESSES)',
    process.env.CTTREASURIES_ADDRESSES,
  )
  .addFlag('multipleTreasuries', 'Proceeds multiple treasuries')
  .setAction(async (taskArgs, hre) => {
    assert(taskArgs.erc1155 !== '', "Argument '--erc1155' should not be empty.");
    assert(taskArgs.treasuries !== '', "Argument '--treasuries' should not be empty.");

    await hre.run('compile');

    const { ethers } = hre;
    const { multipleTreasuries } = taskArgs;

    console.log('Opening wallets...');

    const policyWallet = await getPolicy(ethers);
    const guardianWallet = await getGuardian(ethers);

    console.log(pico.dim('Policy: '.padStart(10) + pico.green(policyWallet.address)));
    console.log(pico.dim('Guardian: '.padStart(10) + pico.green(guardianWallet.address)));

    const carbonProjectTokenAddress = taskArgs.erc1155;
    console.log('Carbon Project Token:', pico.green(carbonProjectTokenAddress));

    let treasuryAddresses = parseCommaSeparatedValues(taskArgs.treasuries);
    if (!multipleTreasuries) {
      treasuryAddresses = treasuryAddresses.slice(0, 1);
    }
    console.log('Treasuries:', treasuryAddresses);

    console.log('\n');

    for (const address of treasuryAddresses) {
      const ctTreasuryContract = new ethers.Contract(address, ctTreasuryAbi, policyWallet);
      console.log('Start enable-permissions CT Treasury address: '.padStart(24), pico.green(address));

      const enableToken = await ctTreasuryContract.enable(0, carbonProjectTokenAddress)
      const enableTokenReceipt = await enableToken.wait()
      if (enableTokenReceipt.status !== 1) {
        throw new Error(`Transaction failed. Tx: ${enableTokenReceipt.transactionHash}`)
      }
      console.log('CT Treasury enable carbon project token tx: '.padStart(24), pico.green(enableToken.hash));

      const enableManager = await ctTreasuryContract.enable(1, guardianWallet.address)
      const enableManagerReceipt = await enableManager.wait()
      if (enableManagerReceipt.status !== 1) {
        throw new Error(`Transaction failed. Tx: ${enableManagerReceipt.transactionHash}`)
      }
      console.log('CT Treasury enable manager tx: '.padStart(24), pico.green(enableManager.hash));

      console.log('Finish enable-permissions CT Treasury address: '.padStart(24), pico.green(address));
    }

    console.log('All enable-permissions tasks finished with success');

  });
