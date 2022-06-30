const fs = require('fs/promises');
const assert = require('../lib/assert');

/**
 * Returns addresses required for DAO Management contract
 * @param deployerAddress
 * @return {Promise<{governor: string, guardian: string, vault: string, policy: string}>}
 */
async function getAccounts(deployerAddress) {
  assert(
    !!process.env.ADDRESS_GOVERNOR || !!deployerAddress,
    "Governer's address is missing."
  );
  assert(!!process.env.ADDRESS_GUARDIAN, "Guardian's address is missing.");
  assert(!!process.env.ADDRESS_POLICY, "Policy's address is missing.");
  assert(!!process.env.ADDRESS_VAULT, "Vault's address is missing.");

  return {
    governor: process.env.ADDRESS_GOVERNOR || deployerAddress,
    guardian: process.env.ADDRESS_GUARDIAN,
    policy: process.env.ADDRESS_POLICY,
    vault: process.env.ADDRESS_VAULT,
  };
}

/**
 * Returns deployer's wallet
 * @param {import('@nomiclabs/hardhat-ethers').HardhatRuntimeEnvironment.ethers} ethers
 * @return {Promise<import('ethers').Wallet>}
 */
async function getDeployer(ethers) {
  assert(!!process.env.DEPLOYER_JSON, "Deployer's JSON wallet is missing.");
  assert(!!process.env.DEPLOYER_PASSWORD, "Deployer's password is missing.");

  const file = process.env.DEPLOYER_JSON;
  const password = process.env.DEPLOYER_PASSWORD;

  const json = await fs.readFile(file, 'utf8');
  const wallet = await ethers.Wallet.fromEncryptedJson(json, password);
  return new ethers.Wallet(wallet.privateKey, ethers.provider);
}

/**
 * Returns guardian's wallet
 * @param {import('@nomiclabs/hardhat-ethers').HardhatRuntimeEnvironment.ethers} ethers
 * @return {Promise<import('ethers').Wallet>}
 */
 async function getGuardian(ethers) {
  assert(!!process.env.GUARDIAN_JSON, "Guardian's JSON wallet is missing.");
  assert(!!process.env.GUARDIAN_PASSWORD, "Guardian's password is missing.");

  const file = process.env.GUARDIAN_JSON;
  const password = process.env.GUARDIAN_PASSWORD;

  const json = await fs.readFile(file, 'utf8');
  const wallet = await ethers.Wallet.fromEncryptedJson(json, password);
  return new ethers.Wallet(wallet.privateKey, ethers.provider);
}

/**
 * Returns policy's wallet
 * @param {import('@nomiclabs/hardhat-ethers').HardhatRuntimeEnvironment.ethers} ethers
 * @return {Promise<import('ethers').Wallet>}
 */
 async function getPolicy(ethers) {
  assert(!!process.env.POLICY_JSON, "Guardian's JSON wallet is missing.");
  assert(!!process.env.POLICY_PASSWORD, "Guardian's password is missing.");

  const file = process.env.POLICY_JSON;
  const password = process.env.POLICY_PASSWORD;

  const json = await fs.readFile(file, 'utf8');
  const wallet = await ethers.Wallet.fromEncryptedJson(json, password);
  return new ethers.Wallet(wallet.privateKey, ethers.provider);
}

exports.getAccounts = getAccounts;
exports.getDeployer = getDeployer;
exports.getGuardian = getGuardian;
exports.getPolicy = getPolicy;
