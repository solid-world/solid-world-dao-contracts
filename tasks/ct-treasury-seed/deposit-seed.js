const assert = require('node:assert');
const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getDeployer } = require('../accounts');
const { parseCommaSeparatedValues } = require('../utils');
const ctTreasuryAbi = require('../../abi/CTTreasury.json');
const carbonCreditAbi = require('../../abi/CarbonCredit.json');

task('deposit-seed', 'Deposit ERC1155 in CT Treasuries')
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

    const ownerWallet = await getDeployer(ethers);
    console.log(pico.dim('Owner: '.padStart(10) + pico.green(ownerWallet.address)));

    const carbonProjectTokenAddress = taskArgs.erc1155;
    console.log('Carbon Project Token:', pico.green(carbonProjectTokenAddress));

    const treasuryAddresses = parseCommaSeparatedValues(taskArgs.treasuries);
    console.log('Treasuries:', treasuryAddresses);
    assert(treasuryAddresses.length === 5, 'To run deposit-seed task you need to provide 5 treasuries');

    console.log('\n');

    console.log('Starting approvals...');

    const carbonProjectTokenContract = new ethers.Contract(carbonProjectTokenAddress, carbonCreditAbi, ownerWallet);

    const approve1 = await carbonProjectTokenContract.setApprovalForAll(treasuryAddresses[0], true);
    await approve1.wait();
    console.log('Approve CT Treasury 1 tx: '.padStart(24), pico.green(approve1.hash));

    const approve2 = await carbonProjectTokenContract.setApprovalForAll(treasuryAddresses[1], true);
    await approve2.wait();
    console.log('Approve CT Treasury 2 tx: '.padStart(24), pico.green(approve2.hash));

    const approve3 = await carbonProjectTokenContract.setApprovalForAll(treasuryAddresses[2], true);
    await approve3.wait();
    console.log('Approve CT Treasury 3 tx: '.padStart(24), pico.green(approve3.hash));

    const approve4 = await carbonProjectTokenContract.setApprovalForAll(treasuryAddresses[3], true);
    await approve4.wait();
    console.log('Approve CT Treasury 4 tx: '.padStart(24), pico.green(approve4.hash));

    const approve5 = await carbonProjectTokenContract.setApprovalForAll(treasuryAddresses[4], true);
    await approve5.wait();
    console.log('Approve CT Treasury 5 tx: '.padStart(24), pico.green(approve5.hash));

    console.log('Starting deposits...');

    const deposits = [
      { projectId: 1,  tokenAmount: 5000,  treasuryAddress: treasuryAddresses[0] },
      { projectId: 2,  tokenAmount: 6000,  treasuryAddress: treasuryAddresses[0] },
      { projectId: 3,  tokenAmount: 7000,  treasuryAddress: treasuryAddresses[0] },
      { projectId: 4,  tokenAmount: 15000, treasuryAddress: treasuryAddresses[3] },
      { projectId: 5,  tokenAmount: 9000,  treasuryAddress: treasuryAddresses[1] },
      { projectId: 6,  tokenAmount: 10000, treasuryAddress: treasuryAddresses[3] },
      { projectId: 7,  tokenAmount: 10000, treasuryAddress: treasuryAddresses[0] },
      { projectId: 8,  tokenAmount: 11000, treasuryAddress: treasuryAddresses[3] },
      { projectId: 9,  tokenAmount: 7000,  treasuryAddress: treasuryAddresses[3] },
      { projectId: 10, tokenAmount: 20000, treasuryAddress: treasuryAddresses[0] },
      { projectId: 11, tokenAmount: 13000, treasuryAddress: treasuryAddresses[0] },
      { projectId: 12, tokenAmount: 18000, treasuryAddress: treasuryAddresses[0] },
      { projectId: 13, tokenAmount: 25000, treasuryAddress: treasuryAddresses[2] },
      { projectId: 14, tokenAmount: 14000, treasuryAddress: treasuryAddresses[4] },
      { projectId: 15, tokenAmount: 10000, treasuryAddress: treasuryAddresses[0] },
    ];

    for (const { projectId, tokenAmount, treasuryAddress } of deposits) {
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
