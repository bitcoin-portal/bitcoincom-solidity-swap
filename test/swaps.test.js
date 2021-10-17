const Token = artifacts.require("Token");
const Weth = artifacts.require("WrappedEther");
const Router = artifacts.require("SwapsRouter");
const Factory = artifacts.require("SwapsFactory");
const ISwapsPair = artifacts.require("ISwapsPair");

const catchRevert = require("./exceptionsHelpers.js").catchRevert;

require("./utils");

const BN = web3.utils.BN;
const APPROVE_VALUE = web3.utils.toWei("1000000");

const ONE_ETH = web3.utils.toWei("1");
const ONE_TOKEN = web3.utils.toWei("1");

const FOUR_TOKENS = web3.utils.toWei("4");
const FIVE_TOKENS = web3.utils.toWei("5");
const NINE_TOKENS = web3.utils.toWei("5");

const FOUR_ETH = web3.utils.toWei("4");
const FIVE_ETH = web3.utils.toWei("5");
const NINE_ETH = web3.utils.toWei("9");

const STATIC_SUPPLY = web3.utils.toWei("500");

const getLastEvent = async (eventName, instance) => {
    const events = await instance.getPastEvents(eventName, {
        fromBlock: 0,
        toBlock: "latest",
    });
    return events.pop().returnValues;
};

contract("Swaps", ([owner, alice, bob, random]) => {

    let weth;
    let token;
    let token2;
    let factory;
    let router;
    // let launchTime;

    // beforeEach(async () => {
    before(async () => {
        weth = await Weth.new();
        token = await Token.new();
        token2 = await Token.new();
        factory = await Factory.new(owner);
        router = await Router.new(
            factory.address,
            weth.address
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

            // during coverage-test
            // const expectedValue = '0x01ada0920ed343dcff2aa5c776daf53affb255ea2841b36cec8629f75f9b1c50';

            // during regular-test
            const expectedValue = '0x34a38ffdad5e88b8e670d19a031204407a72a23edc334635c9c53a26774e3e72';

            assert.equal(
                pairCodeHash,
                expectedValue
            );
        });

        // pair contract
        it.skip("should have correct PERMIT_TYPEHASH value", async () => {
            const permitHash = await factory.PERMIT_TYPEHASH();
            const expectedValue = '0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9';
            assert.equal(
                permitHash,
                expectedValue
            );
        });
    });

    describe("Router Pairs", () => {

        it("should correctly generate pair address", async () => {

            await factory.createPair(
                token.address,
                weth.address
            );

            const { token0, token1, pair } = await getLastEvent(
                "PairCreated",
                factory
            );

            const lookupAddress = await router.pairFor(
                factory.address,
                token.address,
                weth.address
            );

            assert.equal(
                pair,
                lookupAddress
            );
        });

        it("should revert if pair already exists", async () => {

            await catchRevert(
                factory.createPair(
                    token.address,
                    weth.address
                ),
                "revert PAIR_EXISTS"
            );
        });
    });

    describe("Router Liquidity", () => {

        it("should be able to addLiquidity (Tokens)", async () => {

            const depositAmount = FIVE_TOKENS;

            await token.approve(
                router.address,
                APPROVE_VALUE,
                {from: owner}
            );

            await token2.approve(
                router.address,
                APPROVE_VALUE,
                {from: owner}
            );

            await router.addLiquidity(
                token.address,
                token2.address,
                depositAmount,
                depositAmount,
                1,
                1,
                owner,
                170000000000,
                {from: owner}
            );

            const pairAddress = await router.pairFor(
                factory.address,
                token.address,
                token2.address
            );

            pair = await ISwapsPair.at(pairAddress);

            tokenBalance = await token.balanceOf(pairAddress);
            token2Balance = await token2.balanceOf(pairAddress);

            liquidityTokens = await pair.balanceOf(owner);

            assert.isAbove(
                parseInt(liquidityTokens),
                parseInt(0)
            );

            assert.equal(
                tokenBalance,
                depositAmount
            );

            assert.equal(
                token2Balance,
                depositAmount
            );
        });

        it("should be able to addLiquidityETH (Ether)", async () => {

            const depositAmount = FIVE_ETH;

            await token.approve(
                router.address,
                APPROVE_VALUE,
                {from: owner}
            );

            await router.addLiquidityETH(
                token.address,
                STATIC_SUPPLY,
                0,
                0,
                owner,
                170000000000,
                {from: owner, value: depositAmount}
            );

            const pairAddress = await router.pairFor(
                factory.address,
                token.address,
                weth.address
            );

            pair = await ISwapsPair.at(pairAddress);
            wethBalance = await weth.balanceOf(pairAddress);
            tokenBalance = await token.balanceOf(pairAddress);

            liquidityTokens = await pair.balanceOf(owner);

            assert.isAbove(
                parseInt(liquidityTokens),
                parseInt(0)
            );

            assert.equal(
                tokenBalance,
                STATIC_SUPPLY
            );

            assert.equal(
                wethBalance,
                depositAmount
            );
        });

        it("should be able to removeLiquidity (Tokens)", async () => {

            const pairAddress = await router.pairFor(
                factory.address,
                token.address,
                token2.address
            );

            pair = await ISwapsPair.at(pairAddress);
            ownersBalance = await pair.balanceOf(owner);

            assert.isAbove(
                parseInt(ownersBalance),
                0
            );

            await pair.approve(
                router.address,
                APPROVE_VALUE,
                {from: owner}
            );

            const allowance = await pair.allowance(
                owner,
                router.address
            );

            assert.equal(
                allowance,
                APPROVE_VALUE
            );

            await router.removeLiquidity(
                token.address,
                token2.address,
                ownersBalance,
                0,
                0,
                owner,
                1700000000000
            );
        });

        it("should be able to removeLiquidityETH (Ether)", async () => {

            const pairAddress = await router.pairFor(
                factory.address,
                token.address,
                weth.address
            );

            pair = await ISwapsPair.at(pairAddress);
            ownersBalance = await pair.balanceOf(owner);

            assert.isAbove(
                parseInt(ownersBalance),
                0
            );

            await pair.approve(
                router.address,
                APPROVE_VALUE,
                {from: owner}
            );

            const allowance = await pair.allowance(
                owner,
                router.address
            );

            assert.equal(
                allowance,
                APPROVE_VALUE
            );

            await router.removeLiquidityETH(
                token.address,
                ownersBalance,
                0,
                0,
                owner,
                1700000000000
            );
        });
    });

    describe("Router Swap", () => {

        it("should be able to perform a swap (ETH > ERC20)", async () => {

            const depositAmount = FIVE_ETH;
            const swapAmount = FOUR_ETH;

            await token.approve(
                router.address,
                APPROVE_VALUE,
                {from: owner}
            );

            await router.addLiquidityETH(
                token.address,
                STATIC_SUPPLY,
                0,
                0,
                owner,
                170000000000,
                {from: owner, value: depositAmount}
            );

            const pairAddress = await router.pairFor(
                factory.address,
                token.address,
                weth.address
            );

            wethBalanceBefore = await weth.balanceOf(pairAddress);

            const path = [
                weth.address,
                token.address
            ];

            await router.swapExactETHForTokens(
                0,
                path,
                owner,
                1700000000000,
                {
                    from: owner,
                    gasLimit: 10000000000,
                    value: swapAmount
                }
            );

            wethBalanceAfter = await weth.balanceOf(pairAddress);

            assert.equal(
                parseInt(wethBalanceBefore) + parseInt(swapAmount),
                parseInt(wethBalanceAfter)
            );
        });

        it("should be able to perform a swap (ERC20 > ETH)", async () => {

            const depositAmount = FIVE_ETH;
            const swapAmount = FOUR_ETH;

            await token.approve(
                router.address,
                APPROVE_VALUE,
                {from: owner}
            );

            await router.addLiquidityETH(
                token.address,
                STATIC_SUPPLY,
                0,
                0,
                owner,
                170000000000,
                {
                    from: owner,
                    value: depositAmount
                }
            );

            const pairAddress = await router.pairFor(
                factory.address,
                token.address,
                weth.address
            );

            tokenBalanceBefore = await token.balanceOf(
                pairAddress
            );

            const path = [
                token.address,
                weth.address
            ];

            await router.swapExactTokensForETH(
                swapAmount,
                0,
                path,
                owner,
                1700000000000,
                {
                    from: owner,
                    gasLimit: 10000000000
                }
            );

            tokenBalanceAfter = await token.balanceOf(
                pairAddress
            );

            assert.equal(
                parseInt(tokenBalanceBefore) + parseInt(swapAmount),
                parseInt(tokenBalanceAfter)
            );
        });

        it("should be able to perform a swap (ERC20 > ERC20)", async () => {

            const depositAmount = FOUR_TOKENS;
            const swapAmount = ONE_TOKEN;

            await token.approve(
                router.address,
                APPROVE_VALUE,
                {from: owner}
            );

            await token2.approve(
                router.address,
                APPROVE_VALUE,
                {from: owner}
            );

            await router.addLiquidity(
                token.address,
                token2.address,
                depositAmount,
                depositAmount,
                1,
                1,
                owner,
                170000000000,
                {
                    from: owner
                }
            );

            const pairAddress = await router.pairFor(
                factory.address,
                token.address,
                token2.address
            );

            tokenBalanceBefore = await token.balanceOf(
                pairAddress
            );

            const path = [
                token.address,
                token2.address
            ];

            await router.swapExactTokensForTokens(
                swapAmount,
                0,
                path,
                owner,
                1700000000000,
                {
                    from: owner,
                    gasLimit: 10000000000
                }
            );

            tokenBalanceAfter = await token.balanceOf(
                pairAddress
            );

            assert.equal(
                parseInt(tokenBalanceBefore) + parseInt(swapAmount),
                parseInt(tokenBalanceAfter)
            );
        });
    });
});
