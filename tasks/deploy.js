const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getAccounts, getDeployer} = require('./accounts');
const { verifyContract } = require('./utils');

task('deploy_deprecated', 'Deploys DAO Management, predefined Treasury and ERC20 contracts')
  .addFlag('multipleTreasuries', 'Includes multiple predefined treasuries and ERC20 tokens deployment')
  .addFlag('noVerify', 'Skip contracts verification')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile')

    const { ethers } = hre;
    const { multipleTreasuries, noVerify } = taskArgs;

    const deployerWallet = await getDeployer(ethers);

    /**
     * DAO Management deployment
     */

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

    if (!noVerify) {
      console.log('Verifying...', pico.green('DAO Management'));

      await verifyContract(hre, solidDaoManagement.address, [
        governor,
        guardian,
        policy,
        vault,
      ])

      console.log('Finish verify ', pico.green('DAO Management'));
    }

    /**
     * Treasuries and ERC20 tokens deployment
     */

    /** @type {[string, string][]} Array of tuples - [treasury's category, ERC20 token's symbol] */
    let treasuries;

    if (multipleTreasuries) {
      treasuries = [
        ['ForestConservation', 'CTFC'],
        ['Livestock', 'CTL'],
        ['WasteManagement', 'CTWM'],
        ['Agriculture', 'CTA'],
        ['EnergyProduction', 'CTEP'],
      ];
    } else {
      treasuries = [['ForestConservation', 'CTFC']];
    }

    for (const [treasuryName, tokenSymbol] of treasuries) {
      await hre.run('deploy-treasury', {
        solidDaoManagement: solidDaoManagement.address,
        treasuryName: treasuryName,
        tokenSymbol: tokenSymbol,
      })
    }
  });
