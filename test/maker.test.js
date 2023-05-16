const Maker = artifacts.require("LiquidityMaker");
const Weth = artifacts.require("WrappedEther");
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
        fromBlock: testBlock, // 1 ETH = ~$1820
        toBlock: "latest",
    });
    return events.pop().returnValues;
};

contract("Maker", ([owner, alice, bob, random]) => {

    const MAINNET_ROUTER = "0xB4B0ea46Fe0E9e8EAB4aFb765b527739F2718671";
    const MAINNET_FACTORY = "0xee3E9E46E34a27dC755a63e2849C9913Ee1A06E2";
    const MAINNET_WRAPPED_ETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    const MAINNET_VERSE_TOKEN = "0x249cA82617eC3DfB2589c4c17ab7EC9765350a18";

    let maker;
    let weth;

    beforeEach(async () => {
        maker = await Maker.new(
            MAINNET_ROUTER,
            MAINNET_FACTORY
        );

        weth = await Weth.at(
            MAINNET_WRAPPED_ETH
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

    describe("Initial liquidity functionality", () => {

        it("should be able to provide liquidity", async () => {

            const depositor = alice;
            const amount = FOUR_ETH;

            const balanceBefore = await weth.balanceOf(
                depositor
            );

            await weth.send(
                amount,
                {
                    from: depositor
                }
            );

            const balanceAfter = await weth.balanceOf(
                depositor
            );

            const balanceChange = balanceAfter.sub(
                balanceBefore
            );

            assert.equal(
                balanceChange.toString(),
                amount.toString()
            );

            await weth.approve(
                maker.address,
                ONE_ETH,
                {
                    from: depositor
                }
            );

            await maker.makeLiquidity(
                MAINNET_WRAPPED_ETH,
                MAINNET_VERSE_TOKEN,
                ONE_ETH,
                1,
                0,
                0,
                {
                    from: depositor
                }
            );
        });
    });
});
