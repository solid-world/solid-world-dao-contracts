const assert = require('node:assert');
const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getGuardian } = require('../accounts');
const { parseCommaSeparatedValues } = require('../utils');
const ctTreasuryAbi = require('../../abi/CTTreasury.json');

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
  .setAction(async (taskArgs, hre) => {
    assert(taskArgs.erc1155 !== '', "Argument '--erc1155' should not be empty.");
    assert(taskArgs.treasuries !== '', "Argument '--treasuries' should not be empty.");

    await hre.run('compile');

    const { ethers } = hre;

    const guardianWallet = await getGuardian(ethers);
    console.log(pico.dim('Guardian: '.padStart(10) + pico.green(guardianWallet.address)));

    const carbonProjectTokenAddress = taskArgs.erc1155;
    console.log('Carbon Project Token:', pico.green(carbonProjectTokenAddress));

    const treasuryAddresses = parseCommaSeparatedValues(taskArgs.treasuries);
    console.log('Treasuries:', treasuryAddresses);
    assert(treasuryAddresses.length === 5, 'To run project-seed task you need to provide 5 treasuries');

    console.log('\n');

    const treasuryForestConservationContract = new ethers.Contract(treasuryAddresses[0], ctTreasuryAbi, guardianWallet);
    const treasuryLivestockContract = new ethers.Contract(treasuryAddresses[1], ctTreasuryAbi, guardianWallet);
    const treasuryWasteManagementContract = new ethers.Contract(treasuryAddresses[2], ctTreasuryAbi, guardianWallet);
    const treasuryAgricultureContract = new ethers.Contract(treasuryAddresses[3], ctTreasuryAbi, guardianWallet);
    const treasuryEnergyContract = new ethers.Contract(treasuryAddresses[4], ctTreasuryAbi, guardianWallet);

    const addProject1 = await treasuryForestConservationContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 1, 5000, 1672444800, 1, true, false, false
    ]);
    await addProject1.wait();
    console.log('Add Project 1 tx: '.padStart(24), pico.green(addProject1.hash));

    const addProject2 = await treasuryForestConservationContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 2, 6000, 1672444800, 1, true, false, false
    ]);
    await addProject2.wait();
    console.log('Add Project 2 tx: '.padStart(24), pico.green(addProject2.hash));

    const addProject3 = await treasuryForestConservationContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 3, 7000, 1672444800, 1, true, false, false
    ]);
    await addProject3.wait();
    console.log('Add Project 3 tx: '.padStart(24), pico.green(addProject3.hash));

    const addProject4 = await treasuryAgricultureContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 4, 15000, 1733011200, 1, true, false, false
    ]);
    await addProject4.wait();
    console.log('Add Project 4 tx: '.padStart(24), pico.green(addProject4.hash));

    const addProject5 = await treasuryLivestockContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 5, 9000, 1701388800, 1, true, false, false
    ]);
    await addProject5.wait();
    console.log('Add Project 5 tx: '.padStart(24), pico.green(addProject5.hash));

    const addProject6 = await treasuryAgricultureContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 6, 10000, 1701388800, 1, true, false, false
    ]);
    await addProject6.wait();
    console.log('Add Project 6 tx: '.padStart(24), pico.green(addProject6.hash));

    const addProject7 = await treasuryForestConservationContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 7, 10000, 1701388800, 1, true, false, false
    ]);
    await addProject7.wait();
    console.log('Add Project 7 tx: '.padStart(24), pico.green(addProject7.hash));

    const addProject8 = await treasuryAgricultureContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 8, 11000, 1827619200, 1, true, false, false
    ]);
    await addProject8.wait();
    console.log('Add Project 8 tx: '.padStart(24), pico.green(addProject8.hash));

    const addProject9 = await treasuryAgricultureContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 9, 7000, 1764547200, 1, true, false, false
    ]);
    await addProject9.wait();
    console.log('Add Project 9 tx: '.padStart(24), pico.green(addProject9.hash));

    const addProject10 = await treasuryForestConservationContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 10, 20000, 1733011200, 1, true, false, false
    ]);
    await addProject10.wait();
    console.log('Add Project 10 tx: '.padStart(24), pico.green(addProject10.hash));

    const addProject11 = await treasuryForestConservationContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 11, 13000, 1672444800, 1, true, false, false
    ]);
    await addProject11.wait();
    console.log('Add Project 11 tx: '.padStart(24), pico.green(addProject11.hash));

    const addProject12 = await treasuryForestConservationContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 12, 18000, 1733011200, 1, true, false, false
    ]);
    await addProject12.wait();
    console.log('Add Project 12 tx: '.padStart(24), pico.green(addProject12.hash));

    const addProject13 = await treasuryWasteManagementContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 13, 25000, 1669852800, 1, true, false, false
    ]);
    await addProject13.wait();
    console.log('Add Project 13 tx: '.padStart(24), pico.green(addProject13.hash));

    const addProject14 = await treasuryEnergyContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 14, 14000, 1701388800, 1, true, false, false
    ])
    await addProject14.wait()
    console.log('Add Project 14 tx: '.padStart(24), pico.green(addProject14.hash));

    const addProject15 = await treasuryForestConservationContract.createOrUpdateCarbonProject([
      carbonProjectTokenAddress, 15, 10000, 1701388800, 1, true, false, false
    ]);
    await addProject15.wait();
    console.log('Add Project 15 tx: '.padStart(24), pico.green(addProject15.hash));

    console.log('All project-seed tasks finished with success');

  });
