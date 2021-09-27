const Web3 = require('web3');
const web3 = new Web3('http://localhost:9545');

const UniswapV2FactoryBytecode = require('@uniswap/v2-core/build/UniswapV2Factory.json').bytecode
const UniswapV2FactoryAbi = require('@uniswap/v2-core/build/UniswapV2Factory.json').abi

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

async function deployFactory() {

    const accounts = await web3.eth.getAccounts();
    const contract = new web3.eth.Contract(UniswapV2FactoryAbi);

    contract.deploy({
        arguments: [ZERO_ADDRESS],
        data: UniswapV2FactoryBytecode
    }).send({
        from: accounts[0],
        gas: 4712388,
        gasPrice: 100000000000
    }).then((deployment) => {
        console.log('Uniswap Factory was deployed at the following address:');
        console.log(deployment.options.address);
    }).catch((err) => {
        console.error(err);
    });
}

deployFactory();
