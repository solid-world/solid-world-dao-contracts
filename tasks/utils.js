const { setTimeout } = require('timers/promises');

exports.parseCommaSeparatedValues = (string) => {
  return string.split(',').map(v => v.trim())
};

exports.verifyContract = verifyContract;

async function verifyContract(hre, contractAddress, contractArgs) {
  while (true) {
    try {
      await hre.run("verify:verify", {
        address: contractAddress,
        constructorArguments: contractArgs
      });

    } catch (err) {
      if (err.message.includes("Reason: Already Verified")) {
        console.log(`Contract ${contractAddress} is already verified!`);
        return;

      } else if (!err.message.includes('does not have bytecode')) {
        console.error(`Failed to verify contract ${contractAddress}`);
        console.error(err.message)
        return
      }
    }

    await setTimeout(3000); // wait a bit until contracts are propagated to the backend
  }
}
