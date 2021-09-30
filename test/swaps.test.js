const Token = artifacts.require("Token");
const Weth = artifacts.require("WrappedEther");
const Router = artifacts.require("SwapsRouter");
const Factory = artifacts.require("SwapsFactory");

const catchRevert = require("./exceptionsHelpers.js").catchRevert;

require("./utils");

const BN = web3.utils.BN;

const FOUR_ETH = web3.utils.toWei("4");
const FIVE_ETH = web3.utils.toWei("5");
const NINE_ETH = web3.utils.toWei("9");

const STATIC_SUPPLY = web3.utils.toWei("5000000");

const getLastEvent = async (eventName, instance) => {
    const events = await instance.getPastEvents(eventName, {
        fromBlock: 0,
        toBlock: "latest",
    });
    return events.pop().returnValues;
};

contract("Swaps", ([owner, alice, bob, random]) => {

    let weth;
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

        it("should have correct pairCodeHash value", async () => {
            const pairCodeHash = await factory.pairCodeHash();
            const expectedValue = '0x9bec311a9347a183370c3cbe13f2b2a92d1e671699913e9ed34e0875311e9c08';
            assert.equal(
                pairCodeHash,
                expectedValue
            );
        });
    });
});
