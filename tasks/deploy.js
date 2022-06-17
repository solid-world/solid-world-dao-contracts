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

    const CTToken = await ethers.getContractFactory('CTERC20TokenTemplate', deployerWallet);
    const ctToken = await CTToken.deploy("CTTest", "CTTest");
    console.log('CT Token Address: '.padStart(24), pico.green(ctToken.address));

    const Treasury = await ethers.getContractFactory('CTTreasury', deployerWallet);
    const treasury = await Treasury.deploy(
      solidDaoManagement.address,
      ctToken.address,
      0,
      "REED+",
      "0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299",
      2
    );
    console.log('Treasury Address: '.padStart(24), pico.green(treasury.address));
  });
