require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require('dotenv').config()

task("deploy", "Deploy SafeMEME token", async (taskArgs, hre) => {
  const Token = await hre.ethers.getContractFactory("SafeMeme");
  const token = await Token.deploy();

  await token.deployed();

  console.log("SafeMEME Token has been deployed to", token.address);
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  gasReporter: {
    currency: 'EUR',
    gasPrice: 45
  },
  solidity: "0.8.19",
  networks: {
    hardhat: {
      gas: "auto",
      mining: {
        mempool: {
          order: "fifo"
        }
      },
      forking: {
        url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
        blockNumber: 17259378
      }
    }
  }
};
