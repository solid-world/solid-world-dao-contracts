const { task } = require('hardhat/config');
const { getAccounts, getDeployer} = require('./accounts');

task('deploy', 'Deploys DAO Management, SCT and Treasury contracts')
  .setAction(async (taskArgs, hre) => {
    const { ethers } = hre;

    const deployerWallet = await getDeployer(ethers);
    const { governor, guardian, policy, vault } = await getAccounts(deployerWallet.address);

    const SolidDaoManagement = await ethers.getContractFactory('SolidDaoManagement', deployerWallet);
    const solidDaoManagement = await SolidDaoManagement.deploy(
      governor,
      guardian,
      policy,
      vault,
    );
    await solidDaoManagement.deployed()
    console.log('DAO Management Address:'.padStart(25), solidDaoManagement.address);

    const SctToken = await ethers.getContractFactory('SCTERC20Token', deployerWallet);
    const sctToken = await SctToken.deploy(solidDaoManagement.address);
    console.log('SCT Token Address:'.padStart(25), sctToken.address);

    const Treasury = await ethers.getContractFactory('SCTCarbonTreasury', deployerWallet);
    const treasury = await Treasury.deploy(
      solidDaoManagement.address,
      sctToken.address,
      0
    );
    console.log('Treasury Address:'.padStart(25), treasury.address);
  });
