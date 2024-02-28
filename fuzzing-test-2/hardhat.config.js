require("@nomiclabs/hardhat-waffle");
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const CHAIN_IDS = {
  hardhat: 31337, // chain ID for hardhat testing
};
module.exports = {
  networks: {
    hardhat: {
      chainId: CHAIN_IDS.hardhat,
      forking: {
        url: `https://free-eth-node.com/api/eth`, // url to RPC node, ${ALCHEMY_KEY} - must be your API key
        blockNumber: 19191720, // a specific block number with which you want to work
      },
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.7.6",
      },
   ]
  }
};
