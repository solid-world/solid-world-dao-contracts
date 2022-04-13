const { task } = require('hardhat/config');
const assert = require('../lib/assert');

task('accounts', 'Returns addresses required for DAO Management contract')
  .setAction(async (taskArgs, hre) => {
    // ADDRESS_GOVERNER is optional
    // assert(!!process.env.ADDRESS_GOVERNER, "Governer's address is missing.");

    assert(!!process.env.ADDRESS_GUARDIAN, "Guardian's address is missing.");
    assert(!!process.env.ADDRESS_POLICY, "Policy's address is missing.");
    assert(!!process.env.ADDRESS_VAULT, "Vault's address is missing.");

    const [deployer] = await hre.ethers.getSigners();

    return {
      governor: process.env.ADDRESS_GOVERNER || deployer.address,
      guardian: process.env.ADDRESS_GUARDIAN,
      policy: process.env.ADDRESS_POLICY,
      vault: process.env.ADDRESS_VAULT,
    };
  });
