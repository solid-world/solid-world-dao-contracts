const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getAccounts, getDeployer} = require('./accounts');

task('deploy', 'Deploys DAO Management, SCT and Treasury contracts')
  .addFlag('withTreasuries', 'Include predefined treasuries and ERC20 tokens deployment')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile')

    const { ethers } = hre;
    const { withTreasuries } = taskArgs;

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

    /**
     * Treasuries and ERC20 tokens deployment
     */
    if (withTreasuries) {
      /** @type {[string, string][]} Array of tuples - [treasury's category, ERC20 token's symbol] */
      const treasuries = [
        ['ForestConservation', 'CTFC'],
        ['Livestock', 'CTL'],
        ['WasteManagement', 'CTWM'],
        ['Agriculture', 'CTA'],
        ['EnergyProduction', 'CTEP'],
      ];

      for (const [treasuryName, tokenSymbol] of treasuries) {
        await hre.run('deploy-treasury', {
          solidDaoManagement: solidDaoManagement.address,
          treasuryName: treasuryName,
          tokenSymbol: tokenSymbol,
        })
      }
    }
  });
