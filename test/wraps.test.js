const Weth = artifacts.require("WrappedEther");
const catchRevert = require("./exceptionsHelpers.js").catchRevert;
require("./utils");
const BN = web3.utils.BN;

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

contract("Weth", ([owner, alice, bob, random]) => {

    let weth;

    beforeEach(async () => {
        weth = await Weth.new();
    });

    describe("Weth Getter functionality", () => {

        it("should have correct token name", async () => {
            const name = await weth.name();
            assert.equal(
                name,
                "Wrapped Ether"
            );
        });

        it("should have correct weth symbol", async () => {
            const symbol = await weth.symbol();
            assert.equal(
                symbol,
                "WETH"
            );
        });

        it("should have correct decimals", async () => {
            const decimals = await weth.decimals();
            assert.equal(
                decimals,
                18
            );
        });

        it("should have correct totalSupply", async () => {

            await weth.send(FOUR_ETH, {
                from: alice
            });

            await weth.send(FIVE_ETH, {
                from: bob
            });

            totalSupply = await weth.totalSupply();

            assert.equal(
                totalSupply,
                NINE_ETH
            );
        });

        it("should return the correct balance for the given account", async () => {
            const amount = FOUR_ETH;
            await weth.deposit({
                value: amount,
                from: owner
            });

            const balance = await weth.balanceOf(owner);
            assert.equal(
                balance,
                amount
            );
        });
    });

    describe("Deposit functionality", () => {

        it("should credit correct amount when deposited", async () => {

            const amount = FOUR_ETH;

            await weth.deposit({
                value: amount,
                from: alice
            });

            const balance = await weth.balanceOf(alice);

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

            const balance = await weth.balanceOf(bob);

            assert.equal(
                balance,
                amount
            );
        });
    });

    describe("Withdraw functionality", () => {

        beforeEach(async () => {
            await weth.deposit({
                value: ONE_ETH,
                from: alice
            });
        });

        it("should deduct the correct amount", async () => {

            const balanceBefore = await weth.balanceOf(alice);
            const withdrawalAmount = ONE_ETH;

            await weth.withdraw(
                ONE_ETH,
                {
                    from: alice
                }
            );

            const balanceAfter = await weth.balanceOf(alice);

            assert.equal(
                balanceAfter,
                balanceBefore - withdrawalAmount
            );
        });

        it("should emit the correct withdrawal event", async () => {

            const amount = ONE_ETH;

            await weth.withdraw(
                amount,
                {
                    from: alice
                }
            );

            const { src, wad } = await getLastEvent(
                "Withdrawal",
                weth
            );

            assert.equal(
                alice,
                src
            );

            assert.equal(
                amount,
                wad
            );
        });
    });

    describe("Transfer functionality", () => {

        beforeEach(async () => {
            await weth.deposit({
                value: NINE_ETH,
                from: alice
            });
        });

        it("should transfer correct amount of WETH from walletA to walletB", async () => {
            const transferValue = FOUR_ETH;
            const balanceBefore = await weth.balanceOf(bob);

            await weth.transfer(
                bob,
                transferValue,
                {
                    from: alice
                }
            );

            const balanceAfter = await weth.balanceOf(bob);

            assert.equal(
                parseInt(balanceAfter),
                parseInt(balanceBefore) + parseInt(transferValue)
            );
        });

        it("should reduce the sending wallet's balance after transfer", async () => {
            const transferValue = FOUR_ETH;
            const balanceBefore = await weth.balanceOf(alice);

            await weth.transfer(
                bob,
                transferValue,
                {
                    from: alice
                }
            );

            const balanceAfter = await weth.balanceOf(alice);

            assert.equal(
                parseInt(balanceAfter),
                parseInt(balanceBefore) - parseInt(transferValue)
            );
        });

        it("should revert if not enough balance in the wallet", async () => {
            const balanceBefore = await weth.balanceOf(alice);

            await catchRevert(
                weth.transfer(
                    bob,
                    parseInt(balanceBefore) + FOUR_ETH,
                    {
                        from: alice
                    }
                )
            );
        });

        it("should emit correct Transfer event", async () => {
            const transferValue = FOUR_ETH;
            const expectedRecepient = bob;

            await weth.transfer(
                expectedRecepient,
                transferValue,
                {
                    from: alice
                }
            );

            const { src, dst, wad } = await getLastEvent(
                "Transfer",
                weth
            );

            assert.equal(
                src,
                alice
            );

            assert.equal(
                dst,
                expectedRecepient
            );

            assert.equal(
                wad,
                transferValue
            );
        });

        it("should approve the transfer with an emitted Approval event", async () => {
            const transferValue = FOUR_ETH;

            await weth.approve(
                bob,
                transferValue,
                {
                    from: alice
                }
            );

            const { src, guy, wad } = await getLastEvent(
                "Approval",
                weth
            );

            assert.equal(
                src,
                alice
            );

            assert.equal(
                guy,
                bob
            );

            assert.equal(
                wad,
                transferValue
            );
        });

        it("should update the balance of the recipient when using transferFrom", async () => {
            const transferValue = FOUR_ETH;
            const balanceBefore = await weth.balanceOf(bob);

            await weth.approve(
                owner,
                transferValue,
                {
                    from: alice
                }
            );

            await weth.transferFrom(
                alice,
                bob,
                transferValue,
                {
                    from: owner
                }
            );

            const balanceAfter = await weth.balanceOf(bob);

            assert.equal(
                parseInt(balanceAfter),
                parseInt(balanceBefore) + parseInt(transferValue)
            );
        });

        it("should deduct from the balance of the sender when using transferFrom", async () => {
            const transferValue = FOUR_ETH;
            const balanceBefore = await weth.balanceOf(alice);

            await weth.approve(
                owner,
                transferValue,
                {
                    from: alice
                }
            );

            await weth.transferFrom(
                alice,
                bob,
                transferValue,
                {
                    from: owner
                }
            );

            const balanceAfter = await weth.balanceOf(alice);

            assert.equal(
                parseInt(balanceAfter),
                parseInt(balanceBefore) - parseInt(transferValue)
            );
        });

        it("should revert if there is no approval when using transferFrom", async () => {
            const transferValue = FOUR_ETH;

            await catchRevert(
                weth.transferFrom(
                    alice,
                    bob,
                    transferValue,
                    {
                        from: owner
                    }
                ),
                "revert REQUIRES APPROVAL"
            );
        });

        it("should revert if the sender has spent more than their approved amount when using transferFrom", async () => {

            const approvedValue = FOUR_ETH;
            const transferValue = NINE_ETH;

            await weth.approve(
                owner,
                approvedValue,
                {
                    from: alice
                }
            );

            await catchRevert(
                weth.transferFrom(
                    alice,
                    bob,
                    transferValue,
                    {
                        from: owner
                    }
                ),
                "revert REQUIRES APPROVAL"
            );
        });
    });
});
