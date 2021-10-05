const Token = artifacts.require("Token");
const catchRevert = require("./exceptionsHelpers.js").catchRevert;

require("./utils");

const BN = web3.utils.BN;

// TESTING PARAMETERS
const ONE_TOKEN = web3.utils.toWei("1");
const FIVE_ETH = web3.utils.toWei("5");
const STATIC_SUPPLY = web3.utils.toWei("5000000");

const getLastEvent = async (eventName, instance) => {
    const events = await instance.getPastEvents(eventName, {
        fromBlock: 0,
        toBlock: "latest",
    });
    return events.pop().returnValues;
};

contract("Token", ([owner, alice, bob, random]) => {

    let token;
    let launchTime;

    beforeEach(async () => {
        token = await Token.new();
    });

    describe("Token Initial Values", () => {

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

    describe.only("Token Transfer Functionality", () => {

        it("should transfer correct amount from walletA to walletB", async () => {

            const transferValue = ONE_TOKEN;
            const balanceBefore = await token.balanceOf(bob);

            await token.transfer(
                bob,
                transferValue,
                {
                    from: owner
                }
            );

            const balanceAfter = await token.balanceOf(bob);

            assert.equal(
                parseInt(balanceAfter),
                parseInt(balanceBefore) + parseInt(transferValue)
            );
        });

        it("should revert if not enough balance in the wallet", async () => {

            const balanceBefore = await token.balanceOf(alice);

            await catchRevert(
                token.transfer(
                    bob,
                    parseInt(balanceBefore) + 1,
                    {
                        from: alice
                    }
                )
            );
        });

        it("should reduce wallets balance after transfer", async () => {

            const transferValue = ONE_TOKEN;
            const balanceBefore = await token.balanceOf(owner);

            await token.transfer(
                bob,
                transferValue,
                {
                    from: owner
                }
            );

            const balanceAfter = await token.balanceOf(owner);

            assert.equal(
                parseInt(balanceAfter),
                parseInt(balanceBefore) - parseInt(transferValue)
            );
        });

        it("should emit correct Transfer event", async () => {

            const transferValue = ONE_TOKEN;
            const expectedRecepient = bob;

            await token.transfer(
                expectedRecepient,
                transferValue,
                {
                    from: owner
                }
            );

            const { from, to, value } = await getLastEvent(
                "Transfer",
                token
            );

            assert.equal(
                from,
                owner
            );

            assert.equal(
                to,
                expectedRecepient
            );

            assert.equal(
                value,
                transferValue
            );
        });
    });
});
