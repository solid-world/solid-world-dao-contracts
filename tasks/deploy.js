const { task } = require('hardhat/config');
const pico = require('picocolors');
const { getAccounts, getDeployer} = require('./accounts');

task('deploy', 'Deploys DAO Management, SCT and Treasury contracts')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile')

    const { ethers } = hre;

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

    /** @type {[string, string][]} Array of tuples - [treasury's category, ERC20 token's symbol] */
    const treasuries = [
      ['ForestConservation', 'CTFC'],
      ['Livestock', 'CTL'],
      ['WasteManagement', 'CTWM'],
      ['Agriculture', 'CTA'],
      ['EnergyProduction', 'CTEP'],
    ];

    const CTToken = await ethers.getContractFactory('CTERC20TokenTemplate', deployerWallet);
    const Treasury = await ethers.getContractFactory('CTTreasury', deployerWallet);

    for await (const [treasuryName, tokenSymbol] of treasuries) {
      console.log('Deploying %s treasury...', pico.green(treasuryName));

      const ctToken = await CTToken.deploy(tokenSymbol, tokenSymbol);

      const treasury = await Treasury.deploy(
        solidDaoManagement.address,
        ctToken.address,
        0,
        treasuryName,
        "0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299",
        2
      );

      console.log('Treasury Address: '.padStart(24), pico.green(treasury.address));
      console.log('CT Token Address: '.padStart(24), pico.green(ctToken.address));

      await ctToken.initialize(treasury.address)
    }
  });
