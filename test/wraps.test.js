const Weth = artifacts.require("WrappedEther");
const catchRevert = require("./exceptionsHelpers.js").catchRevert;
require("./utils");
const BN = web3.utils.BN;

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

contract("Weth", ([owner, alice, bob, random]) => {

    let weth;

    before(async () => {
        weth = await Weth.new();
    });

    describe("Deposit functionality", () => {

        it("should credit correct amount when deposited", async () => {

            const amount = FOUR_ETH;

            await weth.deposit({
                value: amount,
                from: alice
            });

            balance = await weth.balanceOf(alice);

            assert.equal(
                balance,
                amount
            );
        });

        it("should emit correct deposit event", async () => {

            const amount = FIVE_ETH;

            await weth.deposit({
                value: amount,
                from: alice
            });

            const { dst, wad } = await getLastEvent(
                "Deposit",
                weth
            );

            assert.equal(
                alice,
                dst
            );

            assert.equal(
                amount,
                wad
            );
        });

        it("should allow to deposit through direct transfer", async () => {

            const amount = NINE_ETH;

            await weth.send(amount, {
                from: bob
            });

            balance = await weth.balanceOf(bob);

            assert.equal(
                balance,
                amount
            );
        });
    });

    describe("Withdraw functionality", () => {

        it("should give back correct amount", async () => {
        });

        it("should emit withdraw event", async () => {
        });
    });

    describe.skip("Transfer functionality", () => {

        it("should allow to transfer WETH token between accounts", async () => {
        });

        it("should be able to use approve/allowance", async () => {
        });

        it("should be able to use transferFrom", async () => {
        });
    });
});
