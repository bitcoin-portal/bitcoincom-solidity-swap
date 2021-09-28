const UniswapV2Router01 = artifacts.require("UniswapV2Router01");

const FACTORY = '0xd627ba3B9D89b99aa140BbdefD005e8CdF395a25';
const WETH = '0xEb59fE75AC86dF3997A990EDe100b90DDCf9a826';

module.exports = async function(deployer) {
    await deployer.deploy(
        UniswapV2Router01,
        FACTORY,
        WETH
    );
};
