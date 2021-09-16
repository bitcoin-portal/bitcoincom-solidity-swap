const HDWalletProvider = require('@truffle/hdwallet-provider');
// const mnemonic = 'hand install foil lion pottery century physical reject lens wonder rocket snack';
const mnemonic = 'insect minimum meadow eight hard voyage buzz cotton shrimp time vague banana';
const infura_id = '68e794f7333f47c2855ee7491aefeef4';

module.exports = {
    contracts_build_directory: "./build",
    contracts_directory: "contracts",
    /**
      * Networks define how you connect to your ethereum client and let you set the
      * defaults web3 uses to send transactions. If you don't specify one truffle
      * will spin up a development blockchain for you on port 9545 when you
      * run `develop` or `test`. You can ask a truffle command to use a specific
      * network from the command line, e.g
      *
      * $ truffle test --network <network-name>
      */
    networks: {
                development: {
                    host: "127.0.0.1",
                    port: 9545,
                    gasLimit: 8000000,
                    network_id: 5777
                },
                rinkeby: {
                    provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/${infura_id}`),
                    network_id: 4,
                    skipDryRun: true
                },
                ropsten: {
                    provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/${infura_id}`),
                    network_id: 3,
                    skipDryRun: true
                }
    },
    mocha: {
        useColors: true,
        reporter: "eth-gas-reporter",
        reporterOptions: {
            currency: "USD",
            gasPrice: 5
        }
    },
    // Configure your compilers
    compilers: {
        solc: {
            version: "0.6.5",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200
                },
            }
        }
    }
};
