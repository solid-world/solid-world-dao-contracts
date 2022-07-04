const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getDeployer } = require('../accounts');
const ctTreasuryAbi = require('../../abi/CTTreasury.json');

task('deposit-seed', 'Deposit ERC1155 in CT Treasuries')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile')

    const { ethers } = hre;

    const ownerWallet = await getDeployer(ethers);
    console.log(pico.dim('Owner: '.padStart(10) + pico.green(ownerWallet.address)));

    const carbonProjectTokenAddress = process.env.CARBON_PROJECT_ERC1155_ADDRESS;
    console.log(pico.dim('Carbon Project Token: '.padStart(10) + pico.green(carbonProjectTokenAddress)));

    if (!carbonProjectTokenAddress.length) {
      throw 'ERROR: To run project-seed task you need to provide CARBON_PROJECT_ERC1155_ADDRESS'
    }

    const treasuryAddresses = process.env.CTTREASURIES_ADDRESSES.split(',');
    console.log(pico.dim('CT Treasuries: '.padStart(10) + pico.green(treasuryAddresses)));

    if (treasuryAddresses.length !== 5) {
      throw 'ERROR: To run project-seed task you need to provide 5 CTTREASURIES_ADDRESSES'
    }

    console.log('\n');

    console.log('Starting approvals...');

    const carbonProjectTokenContract = new ethers.Contract(carbonAddress, carbonCreditAbi, ownerWallet);

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

    const treasuryForestConservationContract = new ethers.Contract(treasuryAddresses[0], ctTreasuryAbi, ownerWallet);
    const treasuryLivestockContract = new ethers.Contract(treasuryAddresses[1], ctTreasuryAbi, ownerWallet);
    const treasuryWasteManagementContract = new ethers.Contract(treasuryAddresses[2], ctTreasuryAbi, ownerWallet);
    const treasuryAgricultureContract = new ethers.Contract(treasuryAddresses[3], ctTreasuryAbi, ownerWallet);
    const treasuryEnergyContract = new ethers.Contract(treasuryAddresses[4], ctTreasuryAbi, ownerWallet);

    const deposit1 = await treasuryForestConservationContract.depositReserveToken(carbonAddress, 1, 5000, ownerWallet.address);
    await deposit1.wait();
    console.log('Deposit Project 1 tx: '.padStart(24), pico.green(deposit1.hash));

    const deposit2 = await treasuryForestConservationContract.depositReserveToken(carbonAddress, 2, 6000, ownerWallet.address);
    await deposit2.wait();
    console.log('Deposit Project 2 tx: '.padStart(24), pico.green(deposit2.hash));

    const deposit3 = await treasuryForestConservationContract.depositReserveToken(carbonAddress, 3, 7000, ownerWallet.address);
    await deposit3.wait();
    console.log('Deposit Project 3 tx: '.padStart(24), pico.green(deposit3.hash));

    const deposit4 = await treasuryAgricultureContract.depositReserveToken(carbonAddress, 4, 15000, ownerWallet.address);
    await deposit4.wait();
    console.log('Deposit Project 4 tx: '.padStart(24), pico.green(deposit4.hash));

    const deposit5 = await treasuryLivestockContract.depositReserveToken(carbonAddress, 5, 9000, ownerWallet.address);
    await deposit5.wait();
    console.log('Deposit Project 5 tx: '.padStart(24), pico.green(deposit5.hash));

    const deposit6 = await treasuryAgricultureContract.depositReserveToken(carbonAddress, 6, 10000, ownerWallet.address);
    await deposit6.wait();
    console.log('Deposit Project 6 tx: '.padStart(24), pico.green(deposit6.hash));

    const deposit7 = await treasuryForestConservationContract.depositReserveToken(carbonAddress, 7, 10000, ownerWallet.address);
    await deposit7.wait();
    console.log('Deposit Project 7 tx: '.padStart(24), pico.green(deposit7.hash));

    const deposit8 = await treasuryAgricultureContract.depositReserveToken(carbonAddress, 8, 11000, ownerWallet.address);
    await deposit8.wait();
    console.log('Deposit Project 8 tx: '.padStart(24), pico.green(deposit8.hash));

    const deposit9 = await treasuryAgricultureContract.depositReserveToken(carbonAddress, 9, 7000, ownerWallet.address);
    await deposit9.wait();
    console.log('Deposit Project 9 tx: '.padStart(24), pico.green(deposit9.hash));

    const deposit10 = await treasuryForestConservationContract.depositReserveToken(carbonAddress, 10, 20000, ownerWallet.address);
    await deposit10.wait();
    console.log('Deposit Project 10 tx: '.padStart(24), pico.green(deposit10.hash));

    const deposit11 = await treasuryForestConservationContract.depositReserveToken(carbonAddress, 11, 13000, ownerWallet.address);
    await deposit11.wait();
    console.log('Deposit Project 11 tx: '.padStart(24), pico.green(deposit11.hash));

    const deposit12 = await treasuryForestConservationContract.depositReserveToken(carbonAddress, 12, 18000, ownerWallet.address);
    await deposit12.wait();
    console.log('Deposit Project 12 tx: '.padStart(24), pico.green(deposit12.hash));

    const deposit13 = await treasuryWasteManagementContract.depositReserveToken(carbonAddress, 13, 25000, ownerWallet.address);
    await deposit13.wait();
    console.log('Deposit Project 13 tx: '.padStart(24), pico.green(deposit13.hash));

    const deposit14 = await treasuryEnergyContract.depositReserveToken(carbonAddress, 14, 14000, ownerWallet.address);
    await deposit14.wait();
    console.log('Deposit Project 14 tx: '.padStart(24), pico.green(deposit14.hash));

    const deposit15 = await treasuryForestConservationContract.depositReserveToken(carbonAddress, 15, 10000, ownerWallet.address);
    await deposit15.wait();
    console.log('Deposit Project 15 tx: '.padStart(24), pico.green(deposit15.hash));

    console.log('All deposit-seed tasks finished with success');

  });
