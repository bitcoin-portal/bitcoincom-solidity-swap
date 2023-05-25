/** @type import('hardhat/config').HardhatUserConfig */

require("@nomiclabs/hardhat-truffle5");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-ethers");
require("solidity-coverage");

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 1337,
            allowUnlimitedContractSize: true,
            blockGasLimit: 100000000,
            callGasLimit: 100000000,
            forking: {
                url: "https://eth-mainnet.g.alchemy.com/v2/J3bTM7KLiYYwh8Ar_VBXuo-oLlGTx7od",
                blockNumber: 17274000,
                enabled: true
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
