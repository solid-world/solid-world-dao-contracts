const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getAccounts, getDeployer} = require('./accounts');

task('deploy', 'Deploys DAO Management, SCT and Treasury contracts')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile')

    const { ethers } = hre;

    const deployerWallet = await getDeployer(ethers);
    const { governor, guardian, policy, vault } = await getAccounts(deployerWallet.address);

    console.log(pico.dim('Governor: '.padStart(10) + pico.green(governor)));
    console.log(pico.dim('Guardian: '.padStart(10) + pico.green(guardian)));
    console.log(pico.dim('Policy: '.padStart(10) + pico.green(policy)));
    console.log(pico.dim('Vault: '.padStart(10) + pico.green(vault)));

    console.log('\n');

    const SolidDaoManagement = await ethers.getContractFactory('SolidDaoManagement', deployerWallet);
    const solidDaoManagement = await SolidDaoManagement.deploy(
      governor,
      guardian,
      policy,
      vault,
    );
    await solidDaoManagement.deployed()
    console.log('DAO Management Address: '.padStart(24), pico.green(solidDaoManagement.address));

    const SctToken = await ethers.getContractFactory('SCTERC20Token', deployerWallet);
    const sctToken = await SctToken.deploy(solidDaoManagement.address);
    console.log('SCT Token Address: '.padStart(24), pico.green(sctToken.address));

    const Treasury = await ethers.getContractFactory('SCTCarbonTreasury', deployerWallet);
    const treasury = await Treasury.deploy(
      solidDaoManagement.address,
      sctToken.address,
      0
    );
    console.log('Treasury Address: '.padStart(24), pico.green(treasury.address));
  });
