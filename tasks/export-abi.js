const fs = require('node:fs');
const path = require('node:path');
const { task } = require('hardhat/config');

task('export-abi', 'exports ABI files of contracts')
  .setAction(async (taskArgs, hre) => {
    await hre.run('compile');

    const files = [
      'artifacts/contracts/CarbonCredit.sol/CarbonCredit.json',
      'artifacts/contracts/CTERC20.sol/CTERC20TokenTemplate.json',
      'artifacts/contracts/CTTreasury.sol/CTTreasury.json',
      'artifacts/contracts/NFT.sol/NFT.json',
      'artifacts/contracts/SolidAccessControl.sol/SolidAccessControl.json',
      'artifacts/contracts/SolidDaoManagement.sol/SolidDaoManagement.json',
      'artifacts/contracts/SolidMarketplace.sol/SolidMarketplace.json',
    ];

    files.forEach((file) => {
      try {
        const json = JSON.parse(fs.readFileSync(file, { encoding: 'utf-8' }));
        const abi = json.abi;
        if (!abi) {
          throw new Error('ABI is not defined in the file.');
        }

        const fileName = path.basename(file);
        const abiContent = JSON.stringify(abi, null, '\t');
        fs.writeFileSync(`./abi/${fileName}`, abiContent);
        console.log(`Wrote to ./abi/${fileName}`);
      } catch (err) {
        console.error(err);
      }
    })

  });
