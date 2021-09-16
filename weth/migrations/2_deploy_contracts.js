const WETH9 = artifacts.require("WETH9");

module.exports = async function(deployer) {
    await deployer.deploy(WETH9);
};
