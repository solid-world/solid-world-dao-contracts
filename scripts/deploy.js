const { ethers, upgrades } = require('hardhat');

async function main() {
  const accounts = await ethers.getSigners();

  const SolidDaoManagement = await ethers.getContractFactory('SolidDaoManagement');
  const solidDaoManagement = await SolidDaoManagement.deploy(
    accounts[1].address,
    accounts[2].address,
    accounts[3].address,
    accounts[4].address,
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
