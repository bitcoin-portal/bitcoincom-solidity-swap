const Token = artifacts.require("Token");

const catchRevert = require("./exceptionsHelpers.js").catchRevert;

require("./utils");

const BN = web3.utils.BN;

// TESTING PARAMETERS
const SECONDS_IN_DAY = 30;
const FIVE_ETH = web3.utils.toWei("5");
const STATIC_SUPPLY = web3.utils.toWei("5000000");

const getLastEvent = async (eventName, instance) => {
    const events = await instance.getPastEvents(eventName, {
        fromBlock: 0,
        toBlock: "latest",
    });
    return events.pop().returnValues;
};

contract("Token", ([owner, user1, user2, random]) => {

    let token;
    let launchTime;

    before(async () => {
        token = await Token.new();
    });

    describe.skip("Initial Variables", () => {

        it("should have correct token name", async () => {
            const name = await token.name();
            assert.equal(
                name,
                "Token"
            );
        });

        it("should have correct token symbol", async () => {
            const symbol = await token.symbol();
            assert.equal(
                symbol,
                "TKN"
            );
        });

        it("should have correct token decimals", async () => {
            const decimals = await token.decimals();
            assert.equal(
                decimals,
                18
            );
        });
    });
});
