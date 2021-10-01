const Token = artifacts.require("Token");
const Weth = artifacts.require("WrappedEther");
const Router = artifacts.require("SwapsRouter");
const Factory = artifacts.require("SwapsFactory");
const IUniswapV2Pair = artifacts.require("IUniswapV2Pair");

const catchRevert = require("./exceptionsHelpers.js").catchRevert;

require("./utils");

const BN = web3.utils.BN;

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
    let factory;
    let router;
    let launchTime;

    // beforeEach(async () => {
    before(async () => {
        weth = await Weth.new();
        token = await Token.new();
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
            // const expectedValue = '0x4e769ee398923525ee6655071d658be32e15b33e7786e3b22f916b37ac05be80';
            const expectedValue = '0xf04fd5e3f5b30af6dd14b39fcd43f69a796a3c943f942c59322b1c8639390f89';
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

            const lookupAddress = await router.pairLookup(
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

        it("should be able to addLiquidityETH", async () => {

            const depositAmount = FIVE_ETH;

            pairCodeHash = await factory.pairCodeHash();
            supply = await token.balanceOf(owner);

            await token.approve(
                router.address,
                STATIC_SUPPLY,
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

            const pairAddress = await router.pairLookup(
                factory.address,
                token.address,
                weth.address
            );

            pair = await IUniswapV2Pair.at(pairAddress);
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

        it.skip("should be able to removeLiquidityETH", async () => {
        });

    });

    describe("Router Swap", () => {
        it("should be able to perform a swap (ETH > ERC20)", async () => {

            const pairAddress = await router.pairLookup(
                factory.address,
                token.address,
                weth.address
            );

            wethBalanceBefore = await weth.balanceOf(pairAddress);

            const swapAmount = FOUR_ETH;

            const path = [
                weth.address,
                token.address
            ];

            await router.swapExactETHForTokens(
                0,
                path,
                owner,
                170000000000,
                {from: owner, value: swapAmount}
            );

            pair = await IUniswapV2Pair.at(pairAddress);
            wethBalanceAfter = await weth.balanceOf(pairAddress);

            assert.equal(
                parseInt(wethBalanceBefore) + parseInt(swapAmount),
                parseInt(wethBalanceAfter)
            );
        });

        it.skip("should be able to perform a swap (ERC20 > ETH)", async () => {
        });

        it.skip("should be able to perform a swap (ERC20 > ERC20)", async () => {
        });
    });
});
