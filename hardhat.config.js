/** @type import('hardhat/config').HardhatUserConfig */

require("@nomiclabs/hardhat-truffle5");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-ethers");

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 1337,
            allowUnlimitedContractSize: true,
            blockGasLimit: 100000000,
            callGasLimit: 100000000,
            forking: {
                url: "https://eth-mainnet.g.alchemy.com/v2/GIE2WO3ORzSLZD9CYyh9wsuAmeiYb_NV",
                blockNumber: 16827867, //block from 14/03/22
                //blockNumber: 16518560, // blockNumber: 15949225,//  15939225 16775573
                enabled: false
            }
        },
        live: {
            chainId: 1337,
            allowUnlimitedContractSize: true,
            blockGasLimit: 100000000,
            callGasLimit: 100000000,
            url: "http://127.0.0.1:9545/"
        }
    },
    solidity: {
        version: "0.8.19",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    mocha: {
        timeout: 4000000
    }
}
