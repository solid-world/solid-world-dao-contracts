const { ethers, upgrades } = require('hardhat');

async function main() {
  const [
    governor,
    guardian,
    policy,
    vault
  ] = await ethers.getSigners();

  const SolidDaoManagement = await ethers.getContractFactory('SolidDaoManagement');
  const solidDaoManagement = await SolidDaoManagement.deploy(
    governor.address,
    guardian.address,
    policy.address,
    vault.address,
  );
  await solidDaoManagement.deployed()
  console.log('DAO Management Address:'.padStart(25), solidDaoManagement.address);

  const SctToken = await ethers.getContractFactory('SCTERC20Token');
  const sctToken = await SctToken.deploy(solidDaoManagement.address);
  console.log('SCT Token Address:'.padStart(25), sctToken.address);

  const Treasury = await ethers.getContractFactory('SCTCarbonTreasury');
  const treasury = await Treasury.deploy(
    solidDaoManagement.address,
    sctToken.address,
    0
  );
  console.log('Treasury Address:'.padStart(25), treasury.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
