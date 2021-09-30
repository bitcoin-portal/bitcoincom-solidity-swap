// const HDWalletProvider = require('@truffle/hdwallet-provider');
// const mnemonic = 'insect minimum meadow eight hard voyage buzz cotton shrimp time vague banana';
// const infura_id = '68e794f7333f47c2855ee7491aefeef4';

module.exports = {
    plugins: ["solidity-coverage"],
    networks: {
        development: {
            host: "127.0.0.1",
            port: 9545,
            gasLimit: 8000000,
            network_id: 5777
        },
        /* rinkeby: {
            provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/${infura_id}`),
            network_id: 4,
            skipDryRun: true
        },
        ropsten: {
            provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/${infura_id}`),
            network_id: 3,
            skipDryRun: true
        }*/
    },
    mocha: {
        useColors: true,
        reporter: "eth-gas-reporter",
        reporterOptions: {
            currency: "USD",
            gasPrice: 5
        }
    },
    compilers: {
        solc: {
            version: "^0.8.9",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200
                },
            }
        }
    }
};
