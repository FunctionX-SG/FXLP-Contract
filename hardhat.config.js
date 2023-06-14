//require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");

const ALCHEMY_API_KEY = "oVlBkzgZrAVhL6zvDAB73MtQK7EiiRhH";
const ETH_ALCHEMY_API_KEY = "h46tf7QGoc6jpx8nO0GrGoB6MumXB-u1";
const TESTNET_PRIVATE_KEY = "784f911af2030e328daceccb1ccce8ae3fe954e23791e4ea8c2847af6c420d76";

const fs = require('fs');
const MAINNET_PRIVATE_KEY = fs.readFileSync(".secret").toString().trim();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }, 
  networks: {
    mainnet: {
      // url: `https://goerli.infura.io/v3/3f6bc0d4637344c8b7efd24e118a5c45`,
      url: `https://eth-mainnet.g.alchemy.com/v2/${ETH_ALCHEMY_API_KEY}`,
      // url: `https://rpc.ankr.com/eth_goerli`,
      accounts: [MAINNET_PRIVATE_KEY],
      networkCheckTimeout: 999999,
      timeoutBlocks: 200,
      gas: 12400000,
      gasPrice: 17000000000,
    },
    goerli: {
      // url: `https://goerli.infura.io/v3/3f6bc0d4637344c8b7efd24e118a5c45`,
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      // url: `https://rpc.ankr.com/eth_goerli`,
      accounts: [TESTNET_PRIVATE_KEY],
      networkCheckTimeout: 999999,
      timeoutBlocks: 200,
      gas: 12400000,
      gasPrice: 20000000000,
    },
    avalancheFujiTestnet: {
      // url: `https://api.avax-test.network/ext/bc/C/rpc`,
      url: `https://rpc.ankr.com/avalanche_fuji`,
      accounts: [TESTNET_PRIVATE_KEY]
    },
    avalanche: {
      url: `https://rpc.ankr.com/avalanche`,
      accounts: [MAINNET_PRIVATE_KEY],
      gasPrice: 28000000000,
    },
    fxTestnet: {
      url: `https://testnet-fx-json-web3.functionx.io:8545`,
      accounts: [TESTNET_PRIVATE_KEY],
      networkCheckTimeout: 999999,
      timeoutBlocks: 200,
      gas: 12400000,
      gasPrice: 600000000000,
    },
    fxMainnet: {
      url: `https://fx-json-web3.functionx.io:8545`,
      accounts: [MAINNET_PRIVATE_KEY],
      networkCheckTimeout: 999999,
      timeoutBlocks: 200,
      gas: 12400000,
      gasPrice: 505000000000,
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    // apiKey: "5TQ86X5849114KV5WJXXM7WDYK3AMHSVV9"
    apiKey: {
      mainnet: "YOUR_ETHERSCAN_API_KEY",
      optimisticEthereum: "YOUR_OPTIMISTIC_ETHERSCAN_API_KEY",
      arbitrumOne: "YOUR_ARBISCAN_API_KEY",
      bscTestnet: "K7IMNXV71X1IKYBX7FR7F5R72CZB3JUXXS",
      avalancheFujiTestnet: "1HBGVI926B9RNSN97EKV5W5FCNQN11K1B2",     // EJECAN3SAN2PXS194A5VMN13NUFHKAR62D
      avalanche: "1HBGVI926B9RNSN97EKV5W5FCNQN11K1B2"
    }
  },
  mocha: {
    timeout: 40000
  }
};
