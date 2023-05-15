const Maker = artifacts.require("LiquidityMaker");
// const catchRevert = require("./exceptionsHelpers.js").catchRevert;
const { expectRevert } = require('@openzeppelin/test-helpers');
require("./utils");

// const BN = web3.utils.BN;

const ONE_ETH = web3.utils.toWei("1");
const FOUR_ETH = web3.utils.toWei("4");
const FIVE_ETH = web3.utils.toWei("5");
const NINE_ETH = web3.utils.toWei("9");

const getLastEvent = async (eventName, instance) => {
    const events = await instance.getPastEvents(eventName, {
        fromBlock: 0,
        toBlock: "latest",
    });
    return events.pop().returnValues;
};

contract("Maker", ([owner, alice, bob, random]) => {

    const MAINNET_ROUTER = "0xB4B0ea46Fe0E9e8EAB4aFb765b527739F2718671";
    const MAINNET_FACTORY = "0xee3E9E46E34a27dC755a63e2849C9913Ee1A06E2";

    beforeEach(async () => {
        maker = await Maker.new(
            MAINNET_ROUTER,
            MAINNET_FACTORY
        );
    });

    describe("Initial deployment functionality", () => {

        it("should be able to deploy and check initial values", async () => {

            const router = await maker.ROUTER();
            const factory = await maker.FACTORY();

            assert.equal(
                router,
                MAINNET_ROUTER
            );

            assert.equal(
                factory,
                MAINNET_FACTORY
            );
        });
    });
});
