const Factory = artifacts.require("SwapsFactory");
const Router = artifacts.require("SwapsRouter");
const Token = artifacts.require("Token");
const Weth = artifacts.require("WrappedEther");

const catchRevert = require("./exceptionsHelpers.js").catchRevert;

require("./utils");

const BN = web3.utils.BN;

// TESTING PARAMETERS
const SECONDS_IN_DAY = 30;
const FIVE_ETH = web3.utils.toWei("5");
const STATIC_SUPPLY = web3.utils.toWei("5000000");
const WETH_ADDRESS = "0x...."

const getLastEvent = async (eventName, instance) => {
    const events = await instance.getPastEvents(eventName, {
        fromBlock: 0,
        toBlock: "latest",
    });
    return events.pop().returnValues;
};

contract("Swaps", ([owner, user1, user2, random]) => {

    let factory;
    let router;
    let launchTime;

    before(async () => {
        weth = await Weth.new();
        factory = await Factory.new(owner);
        router = await Router.new(
            factory.address,
            weth. address
        );
    });

    describe("Factory Initial Values", () => {

        it("should have correct feeToSetter address", async () => {
            const feeToSetterAddress = await factory.feeToSetter();
            assert.equal(
                feeToSetterAddress,
                owner
            );
        });
    });
});
