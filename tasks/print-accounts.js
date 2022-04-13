const fs = require('fs/promises');
const { task } = require('hardhat/config');
const ethers = require('ethers');
const assert = require('../lib/assert');

const files = [
  'UTC--2022-01-25T14-28-49.222357000Z--8b3a08b22d25c60e4b2bfd984e331568eca4c299',
  'UTC--2022-01-25T14-29-25.630697000Z--94cd0f84fec287f2426e90f0d6653ba8fa29bd8e',
  'UTC--2022-01-25T14-29-49.236558000Z--513906d9b238955b7e4a499ad98e0b90f9503eb4',
  'UTC--2022-01-25T14-30-19.557413000Z--1570bcaebf4a6184814bb8bde72c9b96f3d37525',
  'UTC--2022-01-25T14-30-44.745657000Z--01f5c57004b3b72b7e29dd9d753b0d856972f318',
];

task('print-accounts', 'Prints crypted JSON accounts')
  .addOptionalParam('file')
  .setAction(async () => {
    assert(process.env.DECRYPT_PASSWORD != null, 'Password for decrypting is not set.');
    const wallets = await decrypt(files, process.env.DECRYPT_PASSWORD);

    console.table(wallets.map((w) => ({
      privateKey: w.privateKey,
      address: w.address,
    })));
  });

async function decrypt(files, password) {
  const jsons = await Promise.all(files.map(file => fs.readFile(file, 'utf8')));
  return await Promise.all(jsons.map(json => ethers.Wallet.fromEncryptedJson(json, password)));
}
