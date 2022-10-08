/**
* @type import(‘hardhat/config’).HardhatUserConfig
*/

// npx hardhat verify 0xA5c4CF3fC74b6eA5e35cCF3DFb2592cE4A162d6c --network [mumbai|goerliOptimism]
// npx hardhat run --network [goerliOptimism|mumbai] scripts/deploy.js
require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
const { POLYGON_MUMBAI_RPC_PROVIDER, PRIVATE_KEY, POLYGONSCAN_API_KEY, OPTIMISMSCAN_API_KEY, OPTIMISM_GOERLI_RPC_PROVIDER  } = process.env;
module.exports = {
        solidity: {
          version:"0.8.11",
          settings: {
            optimizer: {
              enabled: true,
              runs: 200
            }
          }
        },
        defaultNetwork: "mumbai",
        networks: {
            mumbai: {
               url: POLYGON_MUMBAI_RPC_PROVIDER,
               accounts: [`0x${PRIVATE_KEY}`],
           },
           goerliOptimism: {
            url:OPTIMISM_GOERLI_RPC_PROVIDER,
            accounts:[`0x${PRIVATE_KEY}`],
           }
        },
        etherscan: {
           apiKey: { 
            polygonMumbai: POLYGONSCAN_API_KEY,
            goerliOptimism: OPTIMISMSCAN_API_KEY,
          },
          customChains: [
            {
              network: "goerliOptimism",
              chainId: 420,
              urls: {
                apiURL: "https://api-goerli-optimism.etherscan.io/api",
                browserURL: "https://goerli-optimism.etherscan.io"
              }
            }]
        }
};