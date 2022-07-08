const assert = require('node:assert');
const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getDeployer } = require('../accounts');
const { parseCommaSeparatedValues } = require('../utils');
const ctTreasuryAbi = require('../../abi/CTTreasury.json');
const carbonCreditAbi = require('../../abi/CarbonCredit.json');
const projects = require('./projects.json');

task('deposit-seed', 'Deposits predefined amount of ERC1155 to CT Treasury')
  .addParam(
    'erc1155',
    'ERC-1155 token address (fallback to env.CARBON_PROJECT_ERC1155_ADDRESS)',
    process.env.CARBON_PROJECT_ERC1155_ADDRESS,
  )
  .addParam(
    'treasuries',
    'Comma-separated treasury addresses (fallback to env.CTTREASURIES_ADDRESSES)',
    process.env.CTTREASURIES_ADDRESSES,
  )
  .addFlag('multipleTreasuries', 'Proceeds depositing to multiple treasuries')
  .setAction(async (taskArgs, hre) => {
    assert(taskArgs.erc1155 !== '', "Argument '--erc1155' should not be empty.");
    assert(taskArgs.treasuries !== '', "Argument '--treasuries' should not be empty.");

    await hre.run('compile');

    const { ethers } = hre;
    const { multipleTreasuries } = taskArgs;

    const ownerWallet = await getDeployer(ethers);
    console.log(pico.dim('Owner: '.padStart(10) + pico.green(ownerWallet.address)));

    const carbonProjectTokenAddress = taskArgs.erc1155;
    console.log('Carbon Project Token:', pico.green(carbonProjectTokenAddress));

    let treasuryAddresses = parseCommaSeparatedValues(taskArgs.treasuries);
    if (multipleTreasuries) {
      assert(treasuryAddresses.length === 5, 'To run deposit-seed task you need to provide 5 treasuries');
    } else {
      treasuryAddresses = treasuryAddresses.slice(0, 1);
    }
    console.log('Treasuries:', treasuryAddresses);

    console.log('\nStarting approvals...');

    const carbonProjectTokenContract = new ethers.Contract(carbonProjectTokenAddress, carbonCreditAbi, ownerWallet);

    for (const [index, treasuryAddress] of treasuryAddresses.entries()) {
      const approveTx = await carbonProjectTokenContract.setApprovalForAll(treasuryAddress, true);
      await approveTx.wait();
      console.log('Approve CT Treasury %s tx: %s', pico.green(index + 1), pico.green(approveTx.hash));
    }

    console.log('\nStarting deposits...');

    /**
     * @type {Array<{ projectId: number, tokenAmount: number, treasuryAddressIndex: number }>}
     */
    let deposits;

    if (multipleTreasuries) {
      deposits = projects;
    } else {
      deposits = projects.slice(0, 1);
    }

    for (const { projectId, tokenAmount, treasuryAddressIndex } of deposits) {
      const treasuryAddress = treasuryAddresses[treasuryAddressIndex];
      assert(treasuryAddress != null, 'Treasury address is undefined.')
      const treasuryContract = new ethers.Contract(treasuryAddress, ctTreasuryAbi, ownerWallet);

      const depositTx = await treasuryContract.depositReserveToken(
        carbonProjectTokenAddress,
        projectId,
        tokenAmount,
        ownerWallet.address
      );
      await depositTx.wait();

      console.log('Deposit Project %s tx: %s', pico.green(projectId), pico.green(depositTx.hash));
    }

    console.log('All deposit-seed tasks finished with success');
  });
