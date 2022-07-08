const assert = require('node:assert');
const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getGuardian } = require('../accounts');
const { parseCommaSeparatedValues } = require('../utils');
const ctTreasuryAbi = require('../../abi/CTTreasury.json');
const projects = require('./projects.json');

task('project-seed', 'Create Carbon Projects in CT Treasuries')
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
  .addFlag('multipleTreasuries', 'Proceeds creating projects in multiple treasuries')
  .setAction(async (taskArgs, hre) => {
    assert(taskArgs.erc1155 !== '', "Argument '--erc1155' should not be empty.");
    assert(taskArgs.treasuries !== '', "Argument '--treasuries' should not be empty.");

    await hre.run('compile');

    const { ethers } = hre;
    const { multipleTreasuries } = taskArgs;

    const guardianWallet = await getGuardian(ethers);
    console.log(pico.dim('Guardian: '.padStart(10) + pico.green(guardianWallet.address)));

    const carbonProjectTokenAddress = taskArgs.erc1155;
    console.log('Carbon Project Token:', pico.green(carbonProjectTokenAddress));

    let treasuryAddresses = parseCommaSeparatedValues(taskArgs.treasuries);
    if (multipleTreasuries) {
      assert(treasuryAddresses.length === 5, 'To run project-seed task you need to provide 5 treasuries');
    } else {
      treasuryAddresses = treasuryAddresses.slice(0, 1);
    }
    console.log('Treasuries:', treasuryAddresses);

    console.log('\n');

    /**
     * @type {Array<{ projectId: number, tokenAmount: number, deliveryDate: number, treasuryAddressIndex: number }>}
     */
    let projects_;

    if (multipleTreasuries) {
      projects_ = projects;
    } else {
      projects_ = projects.filter(project => project.treasuryAddressIndex === 0);
    }

    for (const { projectId, tokenAmount, deliveryDate, treasuryAddressIndex } of projects_) {
      const treasuryAddress = treasuryAddresses[treasuryAddressIndex];
      assert(treasuryAddress != null, 'Treasury address is undefined.')
      const treasuryContract = new ethers.Contract(treasuryAddress, ctTreasuryAbi, guardianWallet);

      const tx = await treasuryContract.createOrUpdateCarbonProject([
        carbonProjectTokenAddress, projectId, tokenAmount, deliveryDate, 1, true, false, false
      ]);
      await tx.wait();

      console.log('Add Project %s tx: %s', pico.green(projectId), pico.green(tx.hash));
    }

    console.log('All project-seed tasks finished with success');
  });
